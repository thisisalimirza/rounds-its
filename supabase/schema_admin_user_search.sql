-- Rounds — server-side user search for the admin console
--
-- NOT YET APPLIED.
--
-- The console's user list reads every account into Node to render forty rows:
-- one listUsers() call capped at 1000, a profiles query capped at 1000, the
-- whole of player_progress, then a stitch, filter, sort and slice in
-- JavaScript. At 35 accounts that is invisible. At 3,500 it is three large
-- payloads per page load, and at 10,000 the caps silently start hiding people
-- — the worst version of the bug, because the page still looks like it works.
--
-- It is written that way because the pieces live in different places: the email
-- is in auth.users, which PostgREST does not expose, and everything else is in
-- public. Postgres can see both. So the join, the search, the ordering and the
-- paging all belong here, and Next.js gets one page of rows.

-- =========================================================================
-- One page of users, already stitched.
--
-- SECURITY DEFINER because auth.users is not readable by any client role, and
-- REVOKEd from everyone — the console reaches it through the service role
-- after requirePermission('users.read'), which is the only caller.
--
-- total_count rides along as a window function so the caller gets "showing 40
-- of 3,412" without a second round trip.
-- =========================================================================
create or replace function public.admin_list_users(
    p_query  text default '',
    p_plan   text default '',
    p_limit  integer default 40,
    p_offset integer default 0
)
returns table (
    id                        uuid,
    email                     text,
    role                      text,
    role_slug                 text,
    pro_source                text,
    subscription_status       text,
    subscription_expires_at   timestamptz,
    referral_code             text,
    created_at                timestamptz,
    games_played              integer,
    total_score               integer,
    current_streak            integer,
    has_played                boolean,
    total_count               bigint
)
language sql
security definer
set search_path = public
stable
as $$
    with matched as (
        select
            p.id,
            u.email::text                as email,
            p.role,
            p.role_slug,
            p.pro_source,
            p.subscription_status,
            p.subscription_expires_at,
            p.referral_code,
            -- auth.users.created_at is the account's real birthday; profiles
            -- can be backfilled later, so it is the less reliable of the two.
            coalesce(u.created_at, p.created_at) as created_at,
            coalesce(pp.games_played, 0)   as games_played,
            coalesce(pp.total_score, 0)    as total_score,
            coalesce(pp.current_streak, 0) as current_streak,
            (pp.user_id is not null)       as has_played
        from public.profiles p
        left join auth.users u            on u.id = p.id
        left join public.player_progress pp on pp.user_id = p.id
        where
            (
                p_query = ''
                -- Anchored on neither side: support looks people up by the
                -- fragment they were given, which is as often a domain or the
                -- middle of an id as it is the start of an address.
                or u.email     ilike '%' || p_query || '%'
                or p.id::text  ilike '%' || p_query || '%'
                or p.referral_code ilike '%' || p_query || '%'
            )
            and (
                p_plan = ''
                or (p_plan = 'pro'       and p.pro_source <> 'none')
                or (p_plan = 'paid'      and p.subscription_status = 'active')
                or (p_plan = 'anonymous' and u.email is null)
                or (p_plan = 'linked'    and u.email is not null)
            )
    )
    select
        m.*,
        count(*) over () as total_count
    from matched m
    order by m.created_at desc nulls last
    limit  greatest(1, least(p_limit, 200))
    offset greatest(0, p_offset)
$$;

revoke all on function public.admin_list_users(text, text, integer, integer)
    from public, anon, authenticated;

-- =========================================================================
-- The headline counts, which are about the whole population rather than the
-- page — so they cannot be derived from the rows above.
--
-- "Anonymous" is the number that matters most right now: an account with no
-- email cannot reach the web dashboard, cannot be emailed, and loses its
-- progress on a new phone.
-- =========================================================================
create or replace function public.admin_user_totals()
returns table (
    total     bigint,
    anonymous bigint,
    linked    bigint,
    pro       bigint,
    paid      bigint,
    played    bigint
)
language sql
security definer
set search_path = public
stable
as $$
    select
        count(*),
        count(*) filter (where u.email is null),
        count(*) filter (where u.email is not null),
        count(*) filter (where p.pro_source <> 'none'),
        count(*) filter (where p.subscription_status = 'active'),
        count(*) filter (where pp.user_id is not null)
    from public.profiles p
    left join auth.users u              on u.id = p.id
    left join public.player_progress pp on pp.user_id = p.id
$$;

revoke all on function public.admin_user_totals() from public, anon, authenticated;

-- =========================================================================
-- Indexes for the search paths above.
--
-- gin_trgm_ops rather than a plain btree because every one of these predicates
-- is an unanchored ILIKE, which a btree index cannot serve at all.
-- =========================================================================
create extension if not exists pg_trgm;

create index if not exists profiles_referral_code_trgm
    on public.profiles using gin (referral_code gin_trgm_ops);

create index if not exists profiles_created_idx
    on public.profiles (created_at desc);

-- =========================================================================
-- Verify
-- =========================================================================
-- select * from public.admin_user_totals();
-- select id, email, games_played, total_count
--   from public.admin_list_users('', '', 5, 0);
-- select id, email from public.admin_list_users('gmail', '', 5, 0);
