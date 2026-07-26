-- Rounds — the rest of the user data model
-- Applied to production as migrations `full_user_data_model`,
-- `leaderboard_ranking_and_weak_spots` and `leaderboard_views_security_invoker`.
-- Kept here so the repo matches the database. Safe to re-run.
--
-- Brings the SwiftData models that never left the device into Supabase. Before
-- this, only PlayerStats aggregates were mirrored — achievements, weak spots,
-- differential sessions and the rich case history existed solely on one phone,
-- so switching devices reset a student's weak-spot analysis and the web and
-- admin console could see none of it.
--
-- Every table is keyed on the Supabase user id and carries a client-generated
-- row id where one exists, so uploads are idempotent: the app can retry freely
-- and re-sync from a restored device without creating duplicates.

create table if not exists public.case_history (
    id             uuid primary key,           -- client-generated (CaseHistoryEntry.id)
    user_id        uuid not null references public.profiles(id) on delete cascade,
    case_id        uuid not null,
    diagnosis      text not null default '',
    category       text not null default '',
    difficulty     integer not null default 3,
    was_correct    boolean not null default false,
    guess_count    integer not null default 0,
    score          integer not null default 0,
    hints_used     integer not null default 0,
    guesses        text[]  not null default '{}',
    was_daily_case boolean not null default false,
    played_at      timestamptz not null default now(),
    created_at     timestamptz not null default now()
);

create index if not exists case_history_user_idx     on public.case_history(user_id, played_at desc);
create index if not exists case_history_case_idx     on public.case_history(user_id, case_id);
create index if not exists case_history_category_idx on public.case_history(user_id, category);

create table if not exists public.achievements (
    user_id                  uuid primary key references public.profiles(id) on delete cascade,
    unlocked                 text[] not null default '{}',
    first_hint_win_count     integer not null default 0,
    category_stats           jsonb  not null default '{}'::jsonb,
    streak_freezes_available integer not null default 0,
    last_streak_freeze_reset timestamptz,
    updated_at               timestamptz not null default now()
);

-- The mistake log behind Weak Spots and Study Plans. Device-only until now,
-- which meant changing phone silently reset a student's weak-spot analysis —
-- one of the main reasons the app exists.
create table if not exists public.missed_items (
    id          uuid primary key,              -- client-generated
    user_id     uuid not null references public.profiles(id) on delete cascade,
    source      text not null default '',      -- ddxBuilder | connections | ddxChallenge | case
    topic       text not null default '',
    item        text not null default '',
    detail      text not null default '',
    reviewed    boolean not null default false,
    occurred_at timestamptz not null default now(),
    created_at  timestamptz not null default now()
);

create index if not exists missed_items_user_idx  on public.missed_items(user_id, occurred_at desc);
create index if not exists missed_items_topic_idx on public.missed_items(user_id, topic);

create table if not exists public.ddx_sessions (
    id              uuid primary key,          -- client-generated
    user_id         uuid not null references public.profiles(id) on delete cascade,
    findings        text not null default '',
    context         text not null default '',
    chief_complaint text not null default '',
    system          text not null default '',
    result          jsonb,
    created_at      timestamptz not null default now()
);

create index if not exists ddx_sessions_user_idx on public.ddx_sessions(user_id, created_at desc);

-- Replaces the public CloudKit LeaderboardEntry.
--
-- Keyed on the account rather than a locally-generated playerID. That is the
-- fix for the duplication in the CloudKit data, where one player holds three
-- rows because LeaderboardManager falls back to creating a record with an
-- auto-generated id when a fetch fails. A primary key makes that impossible.
create table if not exists public.leaderboard_entries (
    user_id          uuid primary key references public.profiles(id) on delete cascade,
    display_name     text not null default '',
    school_id        text not null default '',
    school_name      text not null default '',
    state            text not null default '',
    country          text not null default 'US',
    is_international boolean not null default false,
    visibility       text not null default 'school'
                        check (visibility in ('private', 'school', 'global')),
    total_score      integer not null default 0 check (total_score >= 0),
    games_played     integer not null default 0 check (games_played >= 0),
    games_won        integer not null default 0 check (games_won >= 0),
    legacy_player_id text,   -- so a device can recognise the CloudKit row it replaces
    updated_at       timestamptz not null default now(),
    created_at       timestamptz not null default now()
);

create index if not exists leaderboard_school_idx on public.leaderboard_entries(school_id, total_score desc);
create index if not exists leaderboard_state_idx  on public.leaderboard_entries(state, total_score desc);
create index if not exists leaderboard_global_idx on public.leaderboard_entries(total_score desc)
    where visibility = 'global';

-- =========================================================================
-- Row Level Security. Personal tables are own-rows-only; the leaderboard is
-- the deliberate exception, since entries marked school/global exist to be
-- seen by other players. Writes stay restricted to the owner either way.
-- =========================================================================
alter table public.case_history        enable row level security;
alter table public.achievements        enable row level security;
alter table public.missed_items        enable row level security;
alter table public.ddx_sessions        enable row level security;
alter table public.leaderboard_entries enable row level security;

grant select, insert, update, delete on public.case_history        to authenticated;
grant select, insert, update, delete on public.achievements        to authenticated;
grant select, insert, update, delete on public.missed_items        to authenticated;
grant select, insert, update, delete on public.ddx_sessions        to authenticated;
grant select, insert, update, delete on public.leaderboard_entries to authenticated;

do $$
declare t text;
begin
    foreach t in array array['case_history','achievements','missed_items','ddx_sessions']
    loop
        execute format('drop policy if exists "own rows select" on public.%I', t);
        execute format('drop policy if exists "own rows insert" on public.%I', t);
        execute format('drop policy if exists "own rows update" on public.%I', t);
        execute format('drop policy if exists "own rows delete" on public.%I', t);

        execute format('create policy "own rows select" on public.%I for select using (auth.uid() = user_id)', t);
        execute format('create policy "own rows insert" on public.%I for insert with check (auth.uid() = user_id)', t);
        execute format('create policy "own rows update" on public.%I for update using (auth.uid() = user_id)', t);
        execute format('create policy "own rows delete" on public.%I for delete using (auth.uid() = user_id)', t);
    end loop;
end
$$;

drop policy if exists "leaderboard public read" on public.leaderboard_entries;
drop policy if exists "leaderboard own write"   on public.leaderboard_entries;
drop policy if exists "leaderboard own update"  on public.leaderboard_entries;

create policy "leaderboard public read" on public.leaderboard_entries
    for select using (visibility in ('school', 'global') or auth.uid() = user_id);
create policy "leaderboard own write" on public.leaderboard_entries
    for insert with check (auth.uid() = user_id);
create policy "leaderboard own update" on public.leaderboard_entries
    for update using (auth.uid() = user_id);

-- =========================================================================
-- Server-side ranking and analysis.
--
-- LeaderboardManager fetched every matching CloudKit record and sorted on the
-- client — fine at 55 rows, untenable at a few thousand, and it means every
-- device computes its own idea of the standings. Postgres ranks once.
-- =========================================================================
create or replace view public.leaderboard_ranked as
select
    e.user_id, e.display_name, e.school_id, e.school_name, e.state, e.country,
    e.visibility, e.total_score, e.games_played, e.games_won, e.updated_at,
    rank() over (order by e.total_score desc, e.updated_at asc)                          as global_rank,
    rank() over (partition by e.school_id order by e.total_score desc, e.updated_at asc) as school_rank,
    rank() over (partition by e.state     order by e.total_score desc, e.updated_at asc) as state_rank
from public.leaderboard_entries e
where e.visibility in ('school', 'global');

create or replace view public.school_leaderboard as
select
    e.school_id,
    max(e.school_name) as school_name,
    max(e.state)       as state,
    count(*)           as player_count,
    sum(e.total_score) as total_score,
    round(avg(e.total_score))::integer as avg_score,
    rank() over (order by sum(e.total_score) desc) as rank
from public.leaderboard_entries e
where e.visibility in ('school', 'global') and e.school_id <> ''
group by e.school_id;

-- Views default to SECURITY DEFINER, which runs them as the creator and so
-- bypasses the querying user's RLS. The WHERE clauses happen to exclude
-- private rows today, but that makes the filter the only thing between a
-- private entry and every client — one edit away from leaking.
alter view public.leaderboard_ranked set (security_invoker = true);
alter view public.school_leaderboard set (security_invoker = true);

grant select on public.leaderboard_ranked to authenticated;
grant select on public.school_leaderboard to authenticated;

-- What a student keeps getting wrong. Previously computed on-device over local
-- MissedItems, so it reset on a device change; in Postgres it is also available
-- to the web and the admin console.
create or replace function public.weak_spots(p_limit integer default 20)
returns table (topic text, miss_count bigint, last_missed timestamptz, unreviewed bigint)
language sql stable security invoker set search_path = public
as $$
    select m.topic, count(*), max(m.occurred_at), count(*) filter (where not m.reviewed)
      from public.missed_items m
     where m.user_id = auth.uid() and m.topic <> ''
     group by m.topic
     order by count(*) desc, max(m.occurred_at) desc
     limit greatest(p_limit, 1);
$$;

create or replace function public.category_performance()
returns table (category text, played bigint, won bigint, accuracy numeric,
               avg_score numeric, last_played timestamptz)
language sql stable security invoker set search_path = public
as $$
    select h.category,
           count(*),
           count(*) filter (where h.was_correct),
           round(100.0 * count(*) filter (where h.was_correct) / nullif(count(*), 0), 1),
           round(avg(h.score), 1),
           max(h.played_at)
      from public.case_history h
     where h.user_id = auth.uid() and h.category <> ''
     group by h.category
     order by count(*) desc;
$$;

grant execute on function public.weak_spots(integer)       to authenticated;
grant execute on function public.category_performance()    to authenticated;
