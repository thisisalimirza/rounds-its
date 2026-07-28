-- Rounds — what the admin console needs to actually run the product
--
-- NOT YET APPLIED.
--
-- Three separate gaps, one file because they are all "the console can display
-- this but cannot act on it":
--
--   1. platform_waitlist has no definition anywhere in the codebase, yet
--      /api/waitlist writes to it. Either it was created by hand in the SQL
--      editor and never committed, or that endpoint has been failing silently
--      since it shipped. Created idempotently here so the answer stops
--      mattering.
--   2. feedback and feature_requests are inboxes with no state. Every row looks
--      unread forever, so the second person to look at them repeats the first
--      person's work.
--   3. Bulk case import needs to know which rows arrived together, so a bad
--      batch can be found and reversed as a unit rather than case by case.
--
-- Safe on a live database: every statement is create-if-not-exists or
-- add-column-if-not-exists, and nothing drops or rewrites existing data.

-- =========================================================================
-- Platform waitlist
--
-- Who wants Rounds on a platform that does not exist yet. Android is the only
-- one today, but the column is a free-text platform rather than a boolean so
-- iPad, web, or Anki-style desktop can join it without a migration.
--
-- (email, platform) is unique rather than (user_id, platform): the same person
-- signing up from two anonymous devices is one address to email, and the whole
-- point of the row is the address.
-- =========================================================================
create table if not exists public.platform_waitlist (
    id         uuid primary key default gen_random_uuid(),
    email      text not null,
    platform   text not null default 'android',
    user_id    uuid references auth.users(id) on delete set null,
    source     text not null default 'dashboard',
    notified_at timestamptz,
    created_at timestamptz not null default now()
);

create unique index if not exists platform_waitlist_email_platform_key
    on public.platform_waitlist (lower(btrim(email)), platform);

create index if not exists platform_waitlist_created_idx
    on public.platform_waitlist (created_at desc);

alter table public.platform_waitlist enable row level security;
grant insert on public.platform_waitlist to authenticated;

-- Insert-only, and only for yourself. There is no select policy: the list of
-- everyone waiting is a marketing asset and a pile of email addresses, so it is
-- readable through the service role and the console alone.
drop policy if exists "platform_waitlist_insert_own" on public.platform_waitlist;
create policy "platform_waitlist_insert_own"
    on public.platform_waitlist for insert to authenticated
    with check (user_id = auth.uid() or user_id is null);

-- =========================================================================
-- Feedback triage
--
-- `status` starts at 'new' for every existing row, which is honest — none of
-- them have been triaged, because until now there was nowhere to record that
-- they had been.
-- =========================================================================
alter table public.feedback
    add column if not exists status text not null default 'new',
    add column if not exists admin_note text,
    add column if not exists handled_by uuid references auth.users(id) on delete set null,
    add column if not exists handled_at timestamptz;

do $$
begin
    if not exists (
        select 1 from pg_constraint where conname = 'feedback_status_check'
    ) then
        alter table public.feedback
            add constraint feedback_status_check
            check (status in ('new', 'triaged', 'actioned', 'spam'));
    end if;
end $$;

create index if not exists feedback_status_idx
    on public.feedback (status, created_at desc);

-- =========================================================================
-- Feature request triage
--
-- The board already has a status the app reads. What it lacks is a place for
-- the reply — the reason a request was declined, or what "planned" means in
-- practice. `admin_note` is public by design: users can already read
-- feature_requests, so telling them why is the point.
-- =========================================================================
alter table public.feature_requests
    add column if not exists admin_note text,
    add column if not exists triaged_by uuid references auth.users(id) on delete set null,
    add column if not exists triaged_at timestamptz;

create index if not exists feature_requests_status_idx
    on public.feature_requests (status, score desc);

-- =========================================================================
-- Case import batches
--
-- A bulk import is one decision that produces hundreds of rows. Recording the
-- batch means "undo the import Sam ran on Tuesday" is a query rather than an
-- archaeology project, and it gives the audit log something to point at that
-- is smaller than 300 individual case.create entries.
-- =========================================================================
create table if not exists public.case_import_batches (
    id          uuid primary key default gen_random_uuid(),
    actor_id    uuid references auth.users(id) on delete set null,
    actor_email text not null default '',
    source      text not null default 'paste',
    created_count  integer not null default 0,
    updated_count  integer not null default 0,
    skipped_count  integer not null default 0,
    case_ids    uuid[] not null default '{}',
    note        text,
    created_at  timestamptz not null default now()
);

create index if not exists case_import_batches_created_idx
    on public.case_import_batches (created_at desc);

alter table public.case_import_batches enable row level security;
-- No policies at all: service role only, like the rest of the admin surface.

-- =========================================================================
-- Console counters
--
-- One round trip for the numbers the console shows on every page load, instead
-- of six count queries fired in parallel from Next.js. SECURITY DEFINER with a
-- pinned search_path, and it returns nothing but integers — no row from any of
-- these tables escapes through it.
-- =========================================================================
create or replace function public.admin_inbox_counts()
returns table (
    new_feedback     integer,
    open_requests    integer,
    waitlist_total   integer,
    unpublished_cases integer,
    unscheduled_days integer
)
language sql
security definer
set search_path = public
stable
as $$
    select
        (select count(*)::integer from public.feedback where status = 'new'),
        (select count(*)::integer from public.feature_requests where status = 'open'),
        (select count(*)::integer from public.platform_waitlist),
        (select count(*)::integer from public.cases where not is_published),
        (select greatest(
            0,
            30 - (select count(*)::integer
                    from public.daily_cases
                   where day between current_date and current_date + 29)
         ))
$$;

revoke all on function public.admin_inbox_counts() from public, anon, authenticated;

-- =========================================================================
-- Verify
-- =========================================================================
-- select * from public.admin_inbox_counts();
-- select status, count(*) from public.feedback group by status;
-- select platform, count(*) from public.platform_waitlist group by platform;
