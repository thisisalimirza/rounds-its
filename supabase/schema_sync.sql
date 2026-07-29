-- Rounds — account sync: subscription mirror + progress mirror
-- Safe to re-run.
--
-- Solves three gaps that made accounts inconsistent between iOS and the web:
--
--  1. An App Store purchase never reached the database. `pro_source` was only
--     ever written by redeem-code, and no RevenueCat webhook existed, so the
--     web showed "Free plan" to paying subscribers forever.
--
--  2. No local progress was ever uploaded. Streaks, stats and case history
--     lived only in SwiftData on one device, so signing in merged nothing and
--     the web had nothing to show.
--
--  3. Linking an email that already had an account failed outright, stranding
--     anyone who signed up on the web before installing the app.
--
-- The progress table is a MIRROR, not the source of truth: SwiftData remains
-- authoritative on-device and this is a backup the web can read and a new
-- device can restore from. That keeps offline play working without conflict
-- resolution. Revisit if/when Android makes a server-authoritative model
-- necessary.

-- =========================================================================
-- Subscription mirror on profiles, maintained by the revenuecat-webhook
-- function. Never written by clients.
-- =========================================================================
alter table public.profiles add column if not exists subscription_status      text not null default 'free';
alter table public.profiles add column if not exists subscription_product_id  text;
alter table public.profiles add column if not exists subscription_store       text;
alter table public.profiles add column if not exists subscription_expires_at  timestamptz;
alter table public.profiles add column if not exists subscription_will_renew  boolean;
alter table public.profiles add column if not exists subscription_period_type text;
alter table public.profiles add column if not exists subscription_updated_at  timestamptz;
alter table public.profiles add column if not exists rc_last_event_id         text;

do $$
begin
    if not exists (select 1 from pg_constraint where conname = 'profiles_subscription_status_check') then
        alter table public.profiles add constraint profiles_subscription_status_check
            check (subscription_status in ('free','active','trialing','grace_period','billing_issue','expired','paused'));
    end if;
end
$$;

create index if not exists profiles_subscription_status_idx on public.profiles(subscription_status);

-- =========================================================================
-- Single definition of "has Pro", used by the app, the web and the admin
-- console so the three can never disagree.
--
-- Two independent routes to Pro:
--   * a redeemed code      -> pro_source <> 'none'
--   * a paid subscription  -> an unexpired subscription in a good state
-- =========================================================================
create or replace function public.profile_has_pro(p_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select coalesce(
        (select p.pro_source <> 'none'
             or (p.subscription_status in ('active','trialing','grace_period')
                 and (p.subscription_expires_at is null
                      or p.subscription_expires_at > now()))
           from public.profiles p
          where p.id = p_id),
        false
    );
$$;

-- =========================================================================
-- player_progress: server mirror of the on-device SwiftData stats.
--
-- One row per user. `completed_case_ids` is an array rather than a join table
-- deliberately — it is only ever read and written whole, and the set is small
-- enough (hundreds) that a table would add joins for no benefit.
-- =========================================================================
create table if not exists public.player_progress (
    user_id             uuid primary key references public.profiles(id) on delete cascade,

    games_played        integer not null default 0 check (games_played >= 0),
    games_won           integer not null default 0 check (games_won >= 0),
    total_score         integer not null default 0 check (total_score >= 0),
    current_streak      integer not null default 0 check (current_streak >= 0),
    max_streak          integer not null default 0 check (max_streak >= 0),

    guess_distribution  integer[] not null default '{0,0,0,0,0}',
    completed_case_ids  text[]    not null default '{}',

    last_played_date        date,
    last_daily_case_played  text,

    -- The device's own clock at capture time. Only used to decide which of two
    -- devices reported more recently for last-wins fields; never trusted for
    -- anything cumulative, because device clocks are wrong often enough to
    -- matter and a skewed clock must not be able to erase a streak.
    device_updated_at   timestamptz,
    updated_at          timestamptz not null default now(),
    created_at          timestamptz not null default now()
);

alter table public.player_progress enable row level security;

grant select, insert, update on public.player_progress to authenticated;

drop policy if exists "read own progress"   on public.player_progress;
drop policy if exists "insert own progress" on public.player_progress;
drop policy if exists "update own progress" on public.player_progress;

create policy "read own progress"   on public.player_progress for select using (auth.uid() = user_id);
create policy "insert own progress" on public.player_progress for insert with check (auth.uid() = user_id);
create policy "update own progress" on public.player_progress for update using (auth.uid() = user_id);

-- =========================================================================
-- sync_progress(): merge, never overwrite.
--
-- This is the heart of the whole feature and the easiest thing to get wrong.
-- A plain upsert would mean: play for 40 days on your phone, install on an
-- iPad, and the iPad's empty stats overwrite your streak. So cumulative fields
-- take the MAX of server and incoming, and completed cases take the UNION.
--
-- Only genuinely "latest wins" fields (which daily case was last played)
-- follow device_updated_at, and even then only when the incoming report is
-- newer than what we already stored.
--
-- Returns the merged row so the client can reconcile its local state against
-- the authoritative merge rather than assuming its own values won.
-- =========================================================================
create or replace function public.sync_progress(
    p_games_played       integer,
    p_games_won          integer,
    p_total_score        integer,
    p_current_streak     integer,
    p_max_streak         integer,
    p_guess_distribution integer[],
    p_completed_case_ids text[],
    p_last_played_date   date,
    p_last_daily_case    text,
    p_device_updated_at  timestamptz
)
returns public.player_progress
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user   uuid := auth.uid();
    v_row    public.player_progress%rowtype;
    v_newer  boolean;
begin
    if v_user is null then
        raise exception 'not_authenticated';
    end if;

    select * into v_row from public.player_progress where user_id = v_user for update;

    if not found then
        insert into public.player_progress (
            user_id, games_played, games_won, total_score,
            current_streak, max_streak, guess_distribution, completed_case_ids,
            last_played_date, last_daily_case_played, device_updated_at
        ) values (
            v_user,
            greatest(coalesce(p_games_played, 0), 0),
            greatest(coalesce(p_games_won, 0), 0),
            greatest(coalesce(p_total_score, 0), 0),
            greatest(coalesce(p_current_streak, 0), 0),
            greatest(coalesce(p_max_streak, 0), 0),
            coalesce(p_guess_distribution, '{0,0,0,0,0}'),
            coalesce(p_completed_case_ids, '{}'),
            p_last_played_date,
            p_last_daily_case,
            p_device_updated_at
        )
        returning * into v_row;
        return v_row;
    end if;

    -- Is this report more recent than the one we already have?
    v_newer := p_device_updated_at is not null
               and (v_row.device_updated_at is null
                    or p_device_updated_at > v_row.device_updated_at);

    update public.player_progress set
        -- Cumulative: max, so a fresh install can never reduce them.
        games_played   = greatest(v_row.games_played,   coalesce(p_games_played, 0)),
        games_won      = greatest(v_row.games_won,      coalesce(p_games_won, 0)),
        total_score    = greatest(v_row.total_score,    coalesce(p_total_score, 0)),
        max_streak     = greatest(v_row.max_streak,     coalesce(p_max_streak, 0)),

        -- Current streak is genuinely current, so the newer report wins — but
        -- it can still never drop below zero or lose to a stale device.
        current_streak = case when v_newer
                              then greatest(coalesce(p_current_streak, 0), 0)
                              else v_row.current_streak end,

        -- Element-wise max keeps a partial device from shrinking the histogram.
        guess_distribution = (
            select array_agg(greatest(
                coalesce(v_row.guess_distribution[i], 0),
                coalesce(p_guess_distribution[i], 0)
            ) order by i)
            from generate_series(1, greatest(
                coalesce(array_length(v_row.guess_distribution, 1), 0),
                coalesce(array_length(p_guess_distribution, 1), 0),
                5
            )) as i
        ),

        -- Union: a case solved on either device stays solved.
        completed_case_ids = (
            select coalesce(array_agg(distinct c), '{}')
            from unnest(v_row.completed_case_ids || coalesce(p_completed_case_ids, '{}')) as c
        ),

        last_played_date = greatest(v_row.last_played_date, p_last_played_date),

        -- Later of the two, not last-writer-wins.
        --
        -- These are "yyyy-MM-dd" strings, so greatest() is a date comparison,
        -- and it ignores nulls. The old rule handed the field to whichever
        -- device reported most recently, which was survivable only while the
        -- phone was the only thing that could play a daily.
        --
        -- Once the web could finish one, this actively undid it: the web sets
        -- today, the phone opens later and pushes *its* copy — still yesterday
        -- — with a newer device_updated_at, and overwrites. And because
        -- ProgressSyncManager.sync() pushes before it pulls, the phone then
        -- read back the stale value it had just written and went on offering
        -- the Daily Case button for a case already played.
        last_daily_case_played = greatest(v_row.last_daily_case_played, p_last_daily_case),

        device_updated_at = greatest(v_row.device_updated_at, p_device_updated_at),
        updated_at = now()
    where user_id = v_user
    returning * into v_row;

    return v_row;
end;
$$;

revoke all on function public.sync_progress(integer, integer, integer, integer, integer, integer[], text[], date, text, timestamptz) from public, anon;
grant execute on function public.sync_progress(integer, integer, integer, integer, integer, integer[], text[], date, text, timestamptz) to authenticated, service_role;

revoke all on function public.profile_has_pro(uuid) from public, anon;
grant execute on function public.profile_has_pro(uuid) to authenticated, service_role;

-- =========================================================================
-- claim_anonymous_account(): fold an abandoned anonymous account into the
-- account the user just signed into.
--
-- Someone who signs up on the web first, then installs the app, ends up with
-- two auth users: the web one (holding their email) and the app's anonymous
-- one (holding whatever they played before signing in). Linking used to fail
-- outright because the email was taken. Now the app signs into the email
-- account and calls this to carry the anonymous account's server-side state
-- across.
--
-- Only the anonymous side's *unclaimed* state moves. A redemption already on
-- the target is never overwritten — that would let someone launder a second
-- free Pro by redeeming anonymously and then merging.
-- =========================================================================
create or replace function public.claim_anonymous_account(p_anonymous_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_target   uuid := auth.uid();
    v_anon     public.profiles%rowtype;
    v_target_p public.profiles%rowtype;
    v_moved    jsonb := '{}'::jsonb;
begin
    if v_target is null then
        raise exception 'not_authenticated';
    end if;
    if p_anonymous_id is null or p_anonymous_id = v_target then
        return jsonb_build_object('status', 'nothing_to_claim');
    end if;

    select * into v_anon from public.profiles where id = p_anonymous_id;
    if not found then
        return jsonb_build_object('status', 'unknown_account');
    end if;

    -- Only an account that never gained an email may be absorbed. Without this
    -- check, knowing any user id would be enough to strip their redemption.
    if exists (select 1 from auth.users u
                where u.id = p_anonymous_id and u.email is not null) then
        return jsonb_build_object('status', 'not_anonymous');
    end if;

    select * into v_target_p from public.profiles where id = v_target;

    -- Carry a redeemed Pro grant across only if the target has none.
    if v_target_p.pro_source = 'none' and v_anon.pro_source <> 'none' then
        update public.profiles
           set pro_source     = v_anon.pro_source,
               pro_granted_at = v_anon.pro_granted_at,
               referred_by    = coalesce(v_target_p.referred_by, v_anon.referred_by),
               attributed_campaign_id = coalesce(v_target_p.attributed_campaign_id,
                                                 v_anon.attributed_campaign_id)
         where id = v_target;

        update public.redemptions set redeemer_id = v_target where redeemer_id = p_anonymous_id;
        v_moved := v_moved || jsonb_build_object('pro_source', v_anon.pro_source);
    end if;

    -- Campaign attribution is worth keeping even without a grant.
    if v_target_p.attributed_campaign_id is null and v_anon.attributed_campaign_id is not null then
        update public.profiles
           set attributed_campaign_id = v_anon.attributed_campaign_id,
               attribution_source     = v_anon.attribution_source,
               attribution_set_at     = v_anon.attribution_set_at
         where id = v_target;
        v_moved := v_moved || jsonb_build_object('campaign', true);
    end if;

    -- Merge the anonymous progress in using the same rules as sync_progress,
    -- so nothing is lost in either direction.
    if exists (select 1 from public.player_progress where user_id = p_anonymous_id) then
        insert into public.player_progress as t (
            user_id, games_played, games_won, total_score, current_streak, max_streak,
            guess_distribution, completed_case_ids, last_played_date,
            last_daily_case_played, device_updated_at
        )
        select v_target, games_played, games_won, total_score, current_streak, max_streak,
               guess_distribution, completed_case_ids, last_played_date,
               last_daily_case_played, device_updated_at
          from public.player_progress where user_id = p_anonymous_id
        on conflict (user_id) do update set
            games_played   = greatest(t.games_played, excluded.games_played),
            games_won      = greatest(t.games_won,    excluded.games_won),
            total_score    = greatest(t.total_score,  excluded.total_score),
            max_streak     = greatest(t.max_streak,   excluded.max_streak),
            current_streak = greatest(t.current_streak, excluded.current_streak),
            completed_case_ids = (
                select coalesce(array_agg(distinct c), '{}')
                from unnest(t.completed_case_ids || excluded.completed_case_ids) as c
            ),
            last_played_date = greatest(t.last_played_date, excluded.last_played_date),
            updated_at = now();

        delete from public.player_progress where user_id = p_anonymous_id;
        v_moved := v_moved || jsonb_build_object('progress', true);
    end if;

    -- Mark the source account so it is never absorbed twice.
    update public.profiles
       set pro_source = 'none', attributed_campaign_id = null
     where id = p_anonymous_id;

    return jsonb_build_object('status', 'claimed', 'moved', v_moved);
end;
$$;

revoke all on function public.claim_anonymous_account(uuid) from public, anon;
grant execute on function public.claim_anonymous_account(uuid) to authenticated, service_role;
