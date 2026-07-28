-- Rounds — one human, one row, even when they have two accounts
--
-- NOT YET APPLIED.
--
-- The bug this fixes is small, invisible, and eats real data.
--
-- case_history, missed_items and ddx_sessions are keyed on a client-generated
-- uuid alone. That id comes off the device — CaseHistoryEntry.id — and the
-- same id can legitimately arrive from two different accounts, because two
-- accounts belonging to one person is the normal state of this app: it makes
-- an anonymous account silently at first launch, so a reinstall produces a
-- second one while CloudKit restores the *same* rows, ids and all, onto it.
--
-- With `id` as the sole primary key, the second account's copy collides. The
-- upload uses ignoreDuplicates, so the collision does not raise an error — the
-- rows are simply dropped, and the account ends up permanently missing history
-- it is holding on the device and trying to send. Silent, and it looks like
-- sync is working.
--
-- The row is only unique *per account*. So the key should say so.
--
-- Safe on the live database: `id` was unique on its own, so every existing row
-- already satisfies the stricter-looking (user_id, id) — no row can violate
-- this, and nothing is deleted or rewritten. Nothing references these tables
-- by foreign key, so there is nothing to cascade.

begin;

-- =========================================================================
-- case_history
-- =========================================================================
alter table public.case_history
    drop constraint if exists case_history_pkey;

alter table public.case_history
    add constraint case_history_pkey primary key (user_id, id);

-- The client still fetches and reconciles by id within one account, and RLS
-- already narrows every read to one user_id, so this covers those lookups.
create index if not exists case_history_id_idx on public.case_history (id);

-- =========================================================================
-- missed_items
-- =========================================================================
alter table public.missed_items
    drop constraint if exists missed_items_pkey;

alter table public.missed_items
    add constraint missed_items_pkey primary key (user_id, id);

create index if not exists missed_items_id_idx on public.missed_items (id);

-- =========================================================================
-- ddx_sessions
-- =========================================================================
alter table public.ddx_sessions
    drop constraint if exists ddx_sessions_pkey;

alter table public.ddx_sessions
    add constraint ddx_sessions_pkey primary key (user_id, id);

create index if not exists ddx_sessions_id_idx on public.ddx_sessions (id);

commit;

-- =========================================================================
-- How anonymous is the population, and is it moving?
--
-- The single number this whole effort is judged on. Read it before shipping
-- the new prompts and again a fortnight later; if it has not moved, the
-- argument is wrong and no amount of placement will save it.
--
-- Deliberately a view rather than a one-off query, so the console and any
-- future dashboard read the same definition of "anonymous" rather than each
-- inventing one.
-- =========================================================================
create or replace view public.identity_health as
select
    count(*)                                                as accounts,
    count(*) filter (where u.email is null)                 as anonymous,
    count(*) filter (where u.email is not null)             as linked,
    round(
        100.0 * count(*) filter (where u.email is not null)
        / nullif(count(*), 0), 1
    )                                                       as linked_pct,
    -- Anonymous accounts that have actually played are the ones with something
    -- to lose. They are the real denominator: an anonymous account that never
    -- opened a case is not a retention problem, it is an install.
    count(*) filter (
        where u.email is null and pp.games_played > 0
    )                                                       as anonymous_with_progress,
    count(*) filter (
        where u.email is null and pp.games_played >= 10
    )                                                       as anonymous_invested
from public.profiles p
left join auth.users u              on u.id = p.id
left join public.player_progress pp on pp.user_id = p.id;

revoke all on public.identity_health from public, anon, authenticated;

-- =========================================================================
-- Verify
-- =========================================================================
-- select * from public.identity_health;
--
-- Confirm the new keys took, and that nothing was lost:
-- select conname, pg_get_constraintdef(oid)
--   from pg_constraint
--  where conrelid in ('public.case_history'::regclass,
--                     'public.missed_items'::regclass,
--                     'public.ddx_sessions'::regclass)
--    and contype = 'p';
--
-- select count(*) from public.case_history;
