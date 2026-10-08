-- Rounds — Founder emails schema
-- Personal emails from Ali (founder) sent once to paying users and once to
-- users who link an email address to their account.
--
-- Safe to re-run (idempotent).
--
-- Requires Vault secrets (insert via SQL Editor or Supabase Dashboard):
--   - founder_email_url:    https://<project>.supabase.co/functions/v1/founder-email
--   - founder_email_secret: <same value as FOUNDER_EMAIL_SECRET edge function secret>

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
    variant         text,          -- null for standard, 'upgrade' for follow-up variant
    recipient_email text not null,
    first_name      text,
    resend_id       text,          -- Resend's message id for debugging
    sent_at         timestamptz not null default now(),
    created_at      timestamptz not null default now(),

    constraint founder_email_sends_unique unique (user_id, email_type)
);

create index if not exists founder_email_sends_user_idx on public.founder_email_sends(user_id);
create index if not exists founder_email_sends_type_idx on public.founder_email_sends(email_type, sent_at);

-- RLS on with no policies: only the service role (which bypasses RLS) can
-- read or write. Clients never touch it, so also drop the default grants.
alter table public.founder_email_sends enable row level security;
revoke all on public.founder_email_sends from anon, authenticated;

-- =========================================================================
-- request_founder_email: callable from triggers or other functions
--
-- Queues an HTTP request to the founder-email edge function via pg_net.
-- The edge function handles idempotency checking and actual sending.
--
-- Reads secrets from Supabase Vault (vault.decrypted_secrets):
--   - founder_email_url:    full URL to the edge function
--   - founder_email_secret: shared auth secret
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
    v_function_url    text;
    v_founder_secret  text;
    v_payload         jsonb;
begin
    -- Read secrets from Supabase Vault
    select decrypted_secret into v_function_url
    from vault.decrypted_secrets
    where name = 'founder_email_url'
    limit 1;

    select decrypted_secret into v_founder_secret
    from vault.decrypted_secrets
    where name = 'founder_email_secret'
    limit 1;

    -- Skip silently if Vault secrets are not configured
    if v_function_url is null or v_founder_secret is null then
        raise notice 'founder_email: Vault secrets not configured, skipping pg_net call';
        return;
    end if;

    v_payload := jsonb_build_object(
        'user_id',    p_user_id,
        'email_type', p_email_type,
        'email',      p_email,
        'first_name', p_first_name
    );

    -- Queue the HTTP request via pg_net (non-blocking)
    -- Signature: net.http_post(url, body jsonb, params jsonb, headers jsonb, timeout_milliseconds int)
    perform net.http_post(
        url                  := v_function_url,
        body                 := v_payload,
        params               := '{}'::jsonb,
        headers              := jsonb_build_object(
            'Content-Type',  'application/json',
            'Authorization', 'Bearer ' || v_founder_secret
        ),
        timeout_milliseconds := 5000
    );
end;
$$;

-- =========================================================================
-- notify_founder_email_on_link: trigger function for email linking
--
-- Fires when a user's email changes from null/empty to a real address.
-- This handles the "free user links their email" case.
--
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
        --
        -- Wrapped in its own exception block: a Vault/pg_net problem must
        -- never roll back or block the auth.users update that fired us.
        begin
            perform public.request_founder_email(
                NEW.id,
                'free',
                v_new_email,
                v_first_name
            );
        exception when others then
            raise warning 'founder_email: request failed for user %, skipping: % (%)',
                NEW.id, sqlerrm, sqlstate;
        end;
    end if;

    return NEW;
end;
$$;

-- =========================================================================
-- Trigger on auth.users for email linking
--
-- Fires after UPDATE when email changes. Uses pg_net to call the edge
-- function asynchronously. Safe to re-run (idempotent).
--
-- Named distinctly from existing triggers:
--   - on_auth_user_created (creates profile row)
--   - on_auth_user_team_sync (team sync)
-- =========================================================================
drop trigger if exists on_founder_email_link on auth.users;
create trigger on_founder_email_link
    after update of email on auth.users
    for each row
    when (OLD.email is distinct from NEW.email)
    execute function public.notify_founder_email_on_link();

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
    p_resend_id      text,
    p_variant        text default null
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.founder_email_sends (
        user_id, email_type, variant, recipient_email, first_name, resend_id
    ) values (
        p_user_id, p_email_type, p_variant, p_recipient_email, p_first_name, p_resend_id
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

revoke all on function public.record_founder_email_sent(uuid, text, text, text, text, text) from public, anon, authenticated;
grant execute on function public.record_founder_email_sent(uuid, text, text, text, text, text) to service_role;

-- =========================================================================
-- Admin view: see all founder emails sent
-- =========================================================================
create or replace view public.founder_email_stats
with (security_invoker = true)
as
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
