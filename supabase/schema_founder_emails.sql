-- Rounds — Founder emails schema
-- Personal emails from Ali (founder) sent once to paying users and once to
-- users who link an email address to their account.
--
-- Safe to re-run.

-- =========================================================================
-- pg_net: required for HTTP calls from database triggers to edge functions.
-- This extension is enabled by default on Supabase but must be explicitly
-- created if missing.
-- =========================================================================
create extension if not exists pg_net with schema extensions;

-- =========================================================================
-- founder_email_sends: idempotency tracking
--
-- Records every founder email sent so we never double-send. The unique
-- constraint on (user_id, email_type) ensures a user receives at most one
-- email of each type, ever.
-- =========================================================================
create table if not exists public.founder_email_sends (
    id              uuid primary key default gen_random_uuid(),
    user_id         uuid not null references public.profiles(id) on delete cascade,
    email_type      text not null check (email_type in ('paid', 'free')),
    recipient_email text not null,
    first_name      text,
    resend_id       text,          -- Resend's message id for debugging
    sent_at         timestamptz not null default now(),
    created_at      timestamptz not null default now(),

    constraint founder_email_sends_unique unique (user_id, email_type)
);

create index if not exists founder_email_sends_user_idx on public.founder_email_sends(user_id);
create index if not exists founder_email_sends_type_idx on public.founder_email_sends(email_type, sent_at);

-- No RLS needed: this table is only written by the service role from edge
-- functions. Clients never touch it.
alter table public.founder_email_sends enable row level security;

-- =========================================================================
-- request_founder_email: callable from triggers or other functions
--
-- Queues an HTTP request to the founder-email edge function via pg_net.
-- The edge function handles idempotency checking and actual sending.
--
-- Returns immediately (non-blocking). The email send is asynchronous.
-- =========================================================================
create or replace function public.request_founder_email(
    p_user_id    uuid,
    p_email_type text,
    p_email      text,
    p_first_name text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_supabase_url text;
    v_service_key  text;
    v_payload      jsonb;
begin
    -- Read runtime config (these are set automatically by Supabase)
    v_supabase_url := current_setting('app.settings.supabase_url', true);
    v_service_key  := current_setting('app.settings.service_role_key', true);

    -- Fallback: if settings aren't available, try environment-style approach
    -- In production Supabase, these would be injected. For safety, we also
    -- support a manual fallback via a config table if needed.
    if v_supabase_url is null or v_service_key is null then
        -- This will work in edge function context but not pure DB triggers.
        -- For pure DB triggers, use Database Webhooks instead (see README).
        raise notice 'founder_email: settings not available, skipping pg_net call';
        return;
    end if;

    v_payload := jsonb_build_object(
        'user_id',    p_user_id,
        'email_type', p_email_type,
        'email',      p_email,
        'first_name', p_first_name
    );

    perform extensions.http_post(
        url     := v_supabase_url || '/functions/v1/founder-email',
        body    := v_payload::text,
        headers := jsonb_build_object(
            'Content-Type',  'application/json',
            'Authorization', 'Bearer ' || v_service_key
        )
    );
end;
$$;

-- =========================================================================
-- notify_founder_email_on_link: trigger function for email linking
--
-- Fires when a user's email changes from null/empty to a real address.
-- This handles the "free user links their email" case.
--
-- Note: This trigger runs on auth.users, which requires careful permissions.
-- The actual email send check (hasn't already been sent, hasn't received
-- paid email) happens in the edge function for robustness.
-- =========================================================================
create or replace function public.notify_founder_email_on_link()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    v_old_email text;
    v_new_email text;
    v_first_name text;
begin
    v_old_email := coalesce(nullif(trim(OLD.email), ''), null);
    v_new_email := coalesce(nullif(trim(NEW.email), ''), null);

    -- Only fire when email transitions from null/empty to a real address
    if v_old_email is null and v_new_email is not null then
        -- Extract first name from raw_user_meta_data if available
        v_first_name := NEW.raw_user_meta_data->>'full_name';
        if v_first_name is not null then
            v_first_name := split_part(v_first_name, ' ', 1);
        end if;

        -- Queue the email request (non-blocking)
        -- The edge function will check idempotency and whether they already
        -- got a paid email (in which case the free email is skipped).
        perform public.request_founder_email(
            NEW.id,
            'free',
            v_new_email,
            v_first_name
        );
    end if;

    return NEW;
end;
$$;

-- The trigger on auth.users requires superuser. On Supabase hosted, this is
-- handled automatically. For local dev, you may need to run as postgres user.
--
-- IMPORTANT: In production Supabase, you likely want to use Database Webhooks
-- (dashboard → Database → Webhooks) instead of this trigger, pointing to the
-- founder-email edge function. Database Webhooks are more reliable for calling
-- edge functions because they use Supabase's internal infrastructure.
--
-- Uncomment the trigger below if using the pg_net approach:
--
-- drop trigger if exists on_email_linked on auth.users;
-- create trigger on_email_linked
--     after update of email on auth.users
--     for each row
--     when (OLD.email is distinct from NEW.email)
--     execute function public.notify_founder_email_on_link();

-- =========================================================================
-- has_received_founder_email: helper for checking email status
--
-- Used by edge functions to check idempotency before sending.
-- =========================================================================
create or replace function public.has_received_founder_email(
    p_user_id uuid,
    p_email_type text
)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select exists (
        select 1 from public.founder_email_sends
        where user_id = p_user_id and email_type = p_email_type
    );
$$;

-- =========================================================================
-- record_founder_email_sent: called by edge function after successful send
--
-- Inserts the record. Uses ON CONFLICT DO NOTHING for idempotency —
-- if the row already exists (race condition), we just don't insert again.
-- =========================================================================
create or replace function public.record_founder_email_sent(
    p_user_id        uuid,
    p_email_type     text,
    p_recipient_email text,
    p_first_name     text,
    p_resend_id      text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.founder_email_sends (
        user_id, email_type, recipient_email, first_name, resend_id
    ) values (
        p_user_id, p_email_type, p_recipient_email, p_first_name, p_resend_id
    )
    on conflict (user_id, email_type) do nothing;

    -- Return true if we actually inserted (first send), false if duplicate
    return found;
end;
$$;

-- Restrict function access to service role only
revoke all on function public.request_founder_email(uuid, text, text, text) from public, anon, authenticated;
grant execute on function public.request_founder_email(uuid, text, text, text) to service_role;

revoke all on function public.has_received_founder_email(uuid, text) from public, anon, authenticated;
grant execute on function public.has_received_founder_email(uuid, text) to service_role;

revoke all on function public.record_founder_email_sent(uuid, text, text, text, text) from public, anon, authenticated;
grant execute on function public.record_founder_email_sent(uuid, text, text, text, text) to service_role;

-- =========================================================================
-- Admin view: see all founder emails sent
-- =========================================================================
create or replace view public.founder_email_stats as
select
    email_type,
    count(*) as total_sent,
    count(*) filter (where sent_at > now() - interval '24 hours') as sent_last_24h,
    count(*) filter (where sent_at > now() - interval '7 days') as sent_last_7d,
    min(sent_at) as first_sent,
    max(sent_at) as last_sent
from public.founder_email_sends
group by email_type;

revoke all on public.founder_email_stats from public, anon, authenticated;
