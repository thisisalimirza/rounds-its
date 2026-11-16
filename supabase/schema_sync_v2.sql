-- Rounds — sync correctness, full anonymous claim, streak freezes, migration marker
--
-- NOT YET APPLIED. Apply this file once, in the Supabase SQL editor, after the
-- schema files already on production. Safe to re-run.
--
-- Backward compatible with the shipping 1.5 app and the web:
--   * no columns or tables are dropped or renamed
--   * sync_progress keeps its argument list, so 1.5 clients keep calling it
--   * no RLS policy is created, dropped, or replaced. "update own profile"
--     stays. The privileged-column trigger is extended so that policy cannot
--     write profiles.migrated_v2_at (see the trigger section and Rollback).
--   * anonymous_claim_tickets has row level security enabled and no policies,
--     which is default deny. The table privileges are revoked from
--     public, anon, and authenticated. That is not a policy.
--
-- Do NOT re-apply supabase/schema_sync.sql or supabase/schema_claim_full_data.sql
-- after this file. Both define older copies of functions replaced here.
-- schema_sync.sql's claim does not move case history. Live production matches
-- schema_claim_full_data.sql, and the replacement below keeps every move in
-- that body. Running either older file later would put the streak bug and the
-- partial claim back.
--
-- play_events is intentionally not created or altered, and no policy on it is
-- replaced. The web migration (roundsapp-landing#164) owns the table. iOS only
-- inserts rows (PlayTelemetry). A duplicate primary key (23505) counts as
-- delivered. claim_anonymous_account reassigns play_events.user_id from the
-- anonymous id to the email account before either auth user can be deleted
-- (the column references auth.users ON DELETE CASCADE). Existing case_history
-- and missed_items rows are not updated to retag browse plays or to add a
-- play_mode column.
--
-- record_case_play is owned by the web app and is already live (PR 202).
-- This file does not create or replace it, and it does not add an overload.
-- faculty_assignments (web PR 203) is applied. It has no user_id, so claim
-- does not move it, and this file does not touch the table.
--
-- Web PR 200 (app_config, announcements, changelog, player_announcement_events)
-- and web PR 203 (faculty_assignments, profiles.cohort_reporting) are applied.
-- profiles.show_in_activity is on production too. The functions still check
-- with to_regclass / information_schema and use EXECUTE, so a missing column
-- does not fail the apply. feed_reactions, feed_reads, and feed_mentions have
-- no foreign key to auth.users.
--
-- Functions created or replaced (conflict-check these names):
--   REPLACE public.sync_progress(integer, integer, integer, integer, integer,
--           integer[], text[], date, text, timestamptz)
--   REPLACE public.claim_anonymous_account(uuid, text)
--   REPLACE public.claim_anonymous_account(uuid)
--           wrapper: calls the two-argument function with a null token
--   CREATE  public.begin_anonymous_claim()
--   REPLACE public.protect_profiles_privileged_columns()
--   CREATE  public.sync_streak_freeze(date, boolean, boolean)
--   CREATE  public.confirm_migration_v2(integer, integer, integer, boolean)
--   CREATE  public.delete_own_account()
--
-- pgcrypto is in the extensions schema on production:
--   extensions.gen_random_bytes(integer)
--   extensions.digest(text, text) and extensions.digest(bytea, text)
-- auth.users.is_anonymous is boolean. The ticket functions call those by name.
--
-- Grants (not policies) are re-applied on the replaced functions because a
-- future CREATE OR REPLACE from an older file would reset them, and on the new
-- functions because they are executable by PUBLIC by default.

-- =========================================================================
-- Account-level marker. Null until confirm_migration_v2 has checked counts.
-- =========================================================================
alter table public.profiles
    add column if not exists migrated_v2_at timestamptz;

-- =========================================================================
-- "update own profile" is FOR UPDATE USING (auth.uid() = id) with no column
-- check, so a signed-in player can write migrated_v2_at unless the
-- privileged-column trigger strips it. This is the live function from
-- roundsapp-landing
-- supabase/migrations/20261008211720_profiles_lockdown_privileged_columns.sql,
-- plus that one column.
--
-- pro_source, the subscription mirror, role, and attribution stay as they
-- are: service_role, postgres, and supabase_admin may write them, and every
-- other role keeps the old values. migrated_v2_at is tighter. Only
-- service_role, or postgres while confirm_migration_v2 has set
-- rounds.migrated_v2_writer, may set or change it. supabase_admin and a
-- plain postgres session cannot. confirm_migration_v2 clears that setting
-- as soon as its update returns. A player insert stores null. A player
-- update keeps the previous value. The policy itself is not replaced.
--
-- The trigger trg_protect_profiles_privileged already calls this function.
-- It is dropped and recreated so a database missing it gets the same
-- BEFORE INSERT OR UPDATE trigger. Table grants are not revoked here; the
-- live lockdown migration already did that, and repeating the revoke would
-- not change who can write the marker.
-- =========================================================================
create or replace function public.protect_profiles_privileged_columns()
returns trigger
language plpgsql
set search_path to 'public'
as $function$
declare
  jwt_claims text;
  jwt_role   text := '';
  trusted    boolean := false;
  marker_ok  boolean := false;
begin
  begin
    jwt_claims := current_setting('request.jwt.claims', true);
  exception when others then
    jwt_claims := null;
  end;

  if jwt_claims is not null and jwt_claims <> '' then
    begin
      jwt_role := coalesce(jwt_claims::jsonb->>'role', '');
    exception when others then
      jwt_role := '';
    end;
  end if;

  trusted :=
    jwt_role = 'service_role'
    or current_user in ('postgres', 'supabase_admin', 'service_role');

  -- confirm_migration_v2 is security definer, so current_user is its owner
  -- (postgres) and the caller's jwt role is still authenticated. The marker
  -- moves only for service_role, or for postgres while that function's GUC
  -- is set. confirm_migration_v2 clears the GUC as soon as the update returns.
  -- A failure reading the setting locks the marker and leaves every other
  -- column on the existing trusted path, so profile writes keep working.
  begin
    marker_ok :=
      jwt_role = 'service_role'
      or current_user = 'service_role'
      or (
        current_user = 'postgres'
        and current_setting('rounds.migrated_v2_writer', true) = 'confirm_migration_v2'
      );
  exception when others then
    marker_ok := jwt_role = 'service_role' or current_user = 'service_role';
  end;

  if tg_op = 'INSERT' then
    if not marker_ok then
      new.migrated_v2_at := null;
    end if;
    if trusted then
      return new;
    end if;

    new.role                     := 'user';
    new.role_slug                := null;
    new.pro_source               := 'none';
    new.pro_granted_at           := null;
    new.subscription_status      := 'free';
    new.subscription_product_id  := null;
    new.subscription_store       := null;
    new.subscription_expires_at  := null;
    new.subscription_will_renew  := null;
    new.subscription_period_type := null;
    new.subscription_updated_at  := null;
    new.rc_last_event_id         := null;
    new.referred_by              := null;
    new.attributed_campaign_id   := null;
    new.attribution_source       := null;
    new.attribution_set_at       := null;
    new.migrated_v2_at           := null;
    if current_user in ('anon', 'authenticated', 'authenticator') then
      new.referral_code := null;
    end if;
    return new;
  end if;

  if tg_op = 'UPDATE' then
    if not marker_ok then
      new.migrated_v2_at := old.migrated_v2_at;
    end if;
    if trusted then
      return new;
    end if;

    new.id                       := old.id;
    new.created_at               := old.created_at;
    new.role                     := old.role;
    new.role_slug                := old.role_slug;
    new.pro_source               := old.pro_source;
    new.pro_granted_at           := old.pro_granted_at;
    new.subscription_status      := old.subscription_status;
    new.subscription_product_id  := old.subscription_product_id;
    new.subscription_store       := old.subscription_store;
    new.subscription_expires_at  := old.subscription_expires_at;
    new.subscription_will_renew  := old.subscription_will_renew;
    new.subscription_period_type := old.subscription_period_type;
    new.subscription_updated_at  := old.subscription_updated_at;
    new.rc_last_event_id         := old.rc_last_event_id;
    new.referral_code            := old.referral_code;
    new.referred_by              := old.referred_by;
    new.attributed_campaign_id   := old.attributed_campaign_id;
    new.attribution_source       := old.attribution_source;
    new.attribution_set_at       := old.attribution_set_at;
    new.migrated_v2_at           := old.migrated_v2_at;
    return new;
  end if;

  return new;
end;
$function$;

drop trigger if exists trg_protect_profiles_privileged on public.profiles;
create trigger trg_protect_profiles_privileged
  before insert or update on public.profiles
  for each row execute function public.protect_profiles_privileged_columns();

-- =========================================================================
-- Streak freeze lives with the progress row: one number, one spend.
-- The achievements columns stay; sync_streak_freeze writes both so a reader
-- still looking at achievements sees the same allowance.
-- =========================================================================
alter table public.player_progress
    add column if not exists streak_freezes_available integer not null default 0;

alter table public.player_progress
    add column if not exists last_streak_freeze_reset date;

alter table public.player_progress
    add column if not exists streak_freeze_used_on date;

alter table public.player_progress
    drop constraint if exists player_progress_freezes_nonnegative;

alter table public.player_progress
    add constraint player_progress_freezes_nonnegative
    check (streak_freezes_available >= 0);

-- =========================================================================
-- sync_progress: same signature as 1.5. Only the streak rule changes.
--
-- current_streak follows the later last_played_date, matching
-- last_daily_case_played. device_updated_at is still stored, but it no longer
-- decides the streak — a phone that opened later and pushed an older streak
-- was winning, and undoing a day played on the web.
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

    update public.player_progress set
        games_played   = greatest(v_row.games_played,   coalesce(p_games_played, 0)),
        games_won      = greatest(v_row.games_won,      coalesce(p_games_won, 0)),
        total_score    = greatest(v_row.total_score,    coalesce(p_total_score, 0)),
        max_streak     = greatest(v_row.max_streak,     coalesce(p_max_streak, 0)),

        -- Later calendar day owns the streak. Same day keeps the higher number
        -- so a partial upload cannot shrink a streak earned today.
        current_streak = case
            when p_last_played_date is not null
                 and (v_row.last_played_date is null
                      or p_last_played_date > v_row.last_played_date)
                then greatest(coalesce(p_current_streak, 0), 0)
            when p_last_played_date is not distinct from v_row.last_played_date
                then greatest(v_row.current_streak, greatest(coalesce(p_current_streak, 0), 0))
            else v_row.current_streak
        end,

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

        completed_case_ids = (
            select coalesce(array_agg(distinct c), '{}')
            from unnest(v_row.completed_case_ids || coalesce(p_completed_case_ids, '{}')) as c
        ),

        last_played_date = greatest(v_row.last_played_date, p_last_played_date),
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

-- =========================================================================
-- Proof that the caller held the anonymous session. leaderboard_entries
-- exposes user_id, so a signed-in player who only knows an anon id must not
-- be able to pull that account's Pro or subscription onto themselves.
--
-- The anonymous session calls begin_anonymous_claim() and keeps the returned
-- token in memory. After the email sign-in, claim_anonymous_account checks
-- the hash. The row stays until expires_at so a retry of the same token
-- still works. There is no policy: row level security is on, and public,
-- anon, and authenticated have no table privileges.
--
-- Checked on production before this file was written:
--   extensions.gen_random_bytes(integer)
--   extensions.digest(text, text)
--   auth.users.is_anonymous boolean
-- =========================================================================
create table if not exists public.anonymous_claim_tickets (
  anon_id uuid primary key references auth.users(id) on delete cascade,
  token_hash bytea not null,
  expires_at timestamptz not null,
  claimed_by uuid
);

alter table public.anonymous_claim_tickets
  add column if not exists claimed_by uuid;

alter table public.anonymous_claim_tickets enable row level security;

revoke all on table public.anonymous_claim_tickets from public, anon, authenticated;

create or replace function public.begin_anonymous_claim()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_token text;
begin
  if v_uid is null or not exists (
    select 1 from auth.users where id = v_uid and is_anonymous
  ) then
    raise exception 'not_anonymous';
  end if;
  v_token := encode(extensions.gen_random_bytes(32), 'hex');
  insert into public.anonymous_claim_tickets (anon_id, token_hash, expires_at)
  values (v_uid, extensions.digest(v_token, 'sha256'), now() + interval '1 hour')
  on conflict (anon_id) do update
    set token_hash = excluded.token_hash,
        expires_at = excluded.expires_at;
  return v_token;
end $$;

revoke all on function public.begin_anonymous_claim() from public, anon;
grant execute on function public.begin_anonymous_claim() to authenticated;

-- =========================================================================
-- claim_anonymous_account: move every row, merge conflicts, drop nothing
-- that the target does not already have.
--
-- Live production matches supabase/schema_claim_full_data.sql, not the older
-- claim in schema_sync.sql (that one never moves history). This body starts
-- from the live function and still moves everything it moves:
--   * pro_source, pro_granted_at, referred_by, and attributed_campaign_id,
--     only when the token is proven, the target's pro_source is 'none', and
--     the anonymous one is not
--   * redemptions.redeemer_id, inside that same proven grant
--   * attribution_source and attribution_set_at when the target has no campaign
--   * player_progress: games_played, games_won, total_score, max_streak,
--     current_streak, guess_distribution, completed_case_ids,
--     last_played_date, last_daily_case_played, device_updated_at
--   * case_history, missed_items, ddx_sessions (user_id reassigned)
--   * achievements: unlocked union, greatest first_hint_win_count,
--     category_stats with the target's keys winning (excluded || target),
--     and the freeze columns when the target has no achievements row
--   * leaderboard_entries reassigned when the target has no row
--   * anonymous pro_source set back to 'none' and attributed_campaign_id null,
--     and the subscription mirror cleared, only when the claim token proves
--     the caller held that anonymous session
--
-- The two-argument function is the body. claim_anonymous_account(uuid) is a
-- one-line wrapper that passes a null token, so shipping 1.5 (which cannot
-- send a token) still resolves to one function and still moves progress.
-- There is no default argument, so a one-argument call is not ambiguous.
-- Pro grant, redemptions.redeemer_id, the subscription mirror, campaign
-- attribution, and empty profile fields run only when the token matches an
-- unexpired ticket that this caller has not already lost to someone else.
-- The ticket row is not deleted. claimed_by is set on the first proven
-- claim and a later caller can reuse that ticket only when claimed_by is
-- their own id. A school or global leaderboard row cannot be claimed at
-- all without a ticket: the function returns proof_required and writes
-- nothing. private is not in that check. Production's visibility check is
-- ('private','school','global').
-- Both profile rows are locked with SELECT ... FOR UPDATE, lower uuid first.
-- An unproven claim does not clear pro_source or the subscription mirror:
-- that would destroy a stranger's Pro without moving it.
--
-- The live ON CONFLICT omits guess_distribution, last_daily_case_played, and
-- device_updated_at, and it deletes the anonymous leaderboard row without
-- copying scores. Those values are merged here. current_streak follows the
-- later last_played_date (same day still takes the greater count). The weekly
-- freeze is merged by the later reset, and by the lower count when the reset
-- day matches, so a second device cannot refill it. None of that removes a
-- move the live function performs.
--
-- Works whether case_history / missed_items / ddx_sessions are keyed on id
-- alone (shipping) or on (user_id, id) (schema_identity.sql, not yet applied).
-- A plain UPDATE of user_id is used only for ids the target does not hold.
-- Where both accounts have the same id, reviewed flags are OR-ed and the
-- anonymous copy is removed only after that merge.
-- =========================================================================
create or replace function public.claim_anonymous_account(
    p_anonymous_id uuid,
    p_claim_token text
)
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
    v_count    integer;
    v_anon_prog public.player_progress%rowtype;
    v_anon_live boolean;
    v_tgt_live boolean;
    v_take_anon boolean := false;
    v_proven   boolean := false;
    v_campaign_copied boolean := false;
    v_anon_miss_keys text[] := '{}';
begin
    if v_target is null then
        raise exception 'not_authenticated';
    end if;
    if p_anonymous_id is null or p_anonymous_id = v_target then
        return jsonb_build_object('status', 'nothing_to_claim');
    end if;

    if not exists (select 1 from auth.users u
                    where u.id = p_anonymous_id and u.is_anonymous) then
        return jsonb_build_object('status', 'not_anonymous');
    end if;

    -- Lock both rows, lower uuid first, so two claims cannot deadlock.
    if v_target < p_anonymous_id then
        select * into v_target_p from public.profiles where id = v_target for update;
        select * into v_anon from public.profiles where id = p_anonymous_id for update;
        if not found then
            return jsonb_build_object('status', 'unknown_account');
        end if;
    else
        select * into v_anon from public.profiles where id = p_anonymous_id for update;
        if not found then
            return jsonb_build_object('status', 'unknown_account');
        end if;
        select * into v_target_p from public.profiles where id = v_target for update;
    end if;

    -- A ticket is reusable until it expires, but only by the account that
    -- first completed a proven claim. claimed_by stays null until then.
    v_proven := p_claim_token is not null and exists (
        select 1 from public.anonymous_claim_tickets
         where anon_id = p_anonymous_id
           and token_hash = extensions.digest(p_claim_token, 'sha256')
           and expires_at > now()
           and (claimed_by is null or claimed_by = v_target)
    );

    -- leaderboard_entries.visibility is text, check
    -- ('private','school','global'), default 'school'. Strangers can read
    -- user_id where visibility is school or global. Without a ticket, refuse
    -- the claim before any row is updated or deleted. A private row, or no
    -- leaderboard row, is not publicly readable, so 1.5 can still move
    -- progress for that id.
    --
    -- TODO: once app_config.min_supported_version is a build that sends a
    -- claim ticket, return proof_required for every claim that has no ticket,
    -- including private and unlisted accounts.
    if not v_proven and exists (
        select 1 from public.leaderboard_entries
         where user_id = p_anonymous_id
           and visibility in ('school', 'global')
    ) then
        return jsonb_build_object('status', 'proof_required');
    end if;

    if v_proven and v_target_p.pro_source = 'none' and v_anon.pro_source <> 'none' then
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

    if v_proven and v_target_p.attributed_campaign_id is null and v_anon.attributed_campaign_id is not null then
        update public.profiles
           set attributed_campaign_id = v_anon.attributed_campaign_id,
               attribution_source     = v_anon.attribution_source,
               attribution_set_at     = v_anon.attribution_set_at
         where id = v_target;
        get diagnostics v_count = row_count;
        v_campaign_copied := v_count > 0;
        if v_campaign_copied then
            v_moved := v_moved || jsonb_build_object('campaign', true);
        end if;
    end if;

    -- Empty profile fields on the email account take the anonymous values.
    -- A field the email account already filled stays. Only a proven claim
    -- copies them. cohort_reporting and show_in_activity are the same kind
    -- of profile write, so they stay inside this block too.
    if v_proven then
    update public.profiles t
       set first_name = case
               when t.first_name is not null and btrim(t.first_name) <> '' then t.first_name
               when a.first_name is not null and char_length(btrim(a.first_name)) between 1 and 40
                   then btrim(a.first_name)
               else t.first_name
           end,
           school = case
               when t.school is not null and btrim(t.school) <> '' then t.school
               when a.school is not null and char_length(btrim(a.school)) between 1 and 120
                   then btrim(a.school)
               else t.school
           end,
           school_id = case
               when t.school_id is null or btrim(t.school_id) = '' then nullif(btrim(a.school_id), '')
               else t.school_id
           end,
           school_source = case
               when t.school_source is null or btrim(t.school_source) = '' then nullif(btrim(a.school_source), '')
               else t.school_source
           end,
           school_year = case
               when t.school_year is not null and btrim(t.school_year) <> '' then t.school_year
               when a.school_year in ('MS1', 'MS2', 'MS3', 'MS4', 'Resident', 'Other') then a.school_year
               else t.school_year
           end,
           exam_date = coalesce(t.exam_date, a.exam_date),
           target_score = case
               when t.target_score is not null then t.target_score
               when a.target_score between 1 and 300 then a.target_score
               else t.target_score
           end
      from public.profiles a
     where t.id = v_target
       and a.id = p_anonymous_id;

    -- cohort_reporting (web PR 203) and show_in_activity are on production.
    -- They stay behind a column check so this function still runs if one is
    -- absent. Null counts as opted in: coalesce(target, true) AND coalesce(anon, true).
    if exists (
        select 1 from information_schema.columns
         where table_schema = 'public'
           and table_name = 'profiles'
           and column_name = 'cohort_reporting'
    ) then
        execute $claim_cohort$
            update public.profiles t
               set cohort_reporting = coalesce(t.cohort_reporting, true)
                                   and coalesce(a.cohort_reporting, true)
              from public.profiles a
             where t.id = $1
               and a.id = $2
        $claim_cohort$ using v_target, p_anonymous_id;
    end if;

    if exists (
        select 1 from information_schema.columns
         where table_schema = 'public'
           and table_name = 'profiles'
           and column_name = 'show_in_activity'
    ) then
        execute $claim_activity$
            update public.profiles t
               set show_in_activity = coalesce(t.show_in_activity, true)
                                   and coalesce(a.show_in_activity, true)
              from public.profiles a
             where t.id = $1
               and a.id = $2
        $claim_activity$ using v_target, p_anonymous_id;
    end if;
    end if;

    -- play_events.user_id references auth.users ON DELETE CASCADE. Move the
    -- rows while the anonymous user still exists.
    update public.play_events
       set user_id = v_target
     where user_id = p_anonymous_id;
    get diagnostics v_count = row_count;
    if v_count > 0 then
        v_moved := v_moved || jsonb_build_object('play_events', v_count);
    end if;

    -- Progress. Later last_played_date owns current_streak. last_daily_case_played
    -- is preserved with greatest(), which the previous ON CONFLICT omitted.
    if exists (select 1 from public.player_progress where user_id = p_anonymous_id) then
        select * into v_anon_prog from public.player_progress where user_id = p_anonymous_id;

        insert into public.player_progress as t (
            user_id, games_played, games_won, total_score, current_streak, max_streak,
            guess_distribution, completed_case_ids, last_played_date,
            last_daily_case_played, device_updated_at,
            streak_freezes_available, last_streak_freeze_reset, streak_freeze_used_on
        )
        values (
            v_target, v_anon_prog.games_played, v_anon_prog.games_won, v_anon_prog.total_score,
            v_anon_prog.current_streak, v_anon_prog.max_streak, v_anon_prog.guess_distribution,
            v_anon_prog.completed_case_ids, v_anon_prog.last_played_date,
            v_anon_prog.last_daily_case_played, v_anon_prog.device_updated_at,
            v_anon_prog.streak_freezes_available, v_anon_prog.last_streak_freeze_reset,
            v_anon_prog.streak_freeze_used_on
        )
        on conflict (user_id) do update set
            games_played   = greatest(t.games_played, excluded.games_played),
            games_won      = greatest(t.games_won,    excluded.games_won),
            total_score    = greatest(t.total_score,  excluded.total_score),
            max_streak     = greatest(t.max_streak,   excluded.max_streak),
            current_streak = case
                when excluded.last_played_date is not null
                     and (t.last_played_date is null or excluded.last_played_date > t.last_played_date)
                    then excluded.current_streak
                when t.last_played_date is not null
                     and (excluded.last_played_date is null or t.last_played_date > excluded.last_played_date)
                    then t.current_streak
                else greatest(t.current_streak, excluded.current_streak)
            end,
            completed_case_ids = (
                select coalesce(array_agg(distinct c), '{}')
                from unnest(t.completed_case_ids || excluded.completed_case_ids) as c
            ),
            guess_distribution = (
                select array_agg(greatest(
                    coalesce(t.guess_distribution[i], 0),
                    coalesce(excluded.guess_distribution[i], 0)
                ) order by i)
                from generate_series(1, greatest(
                    coalesce(array_length(t.guess_distribution, 1), 0),
                    coalesce(array_length(excluded.guess_distribution, 1), 0),
                    5
                )) as i
            ),
            last_played_date = greatest(t.last_played_date, excluded.last_played_date),
            last_daily_case_played = greatest(t.last_daily_case_played, excluded.last_daily_case_played),
            device_updated_at = greatest(t.device_updated_at, excluded.device_updated_at),
            streak_freezes_available = case
                when t.last_streak_freeze_reset is null then excluded.streak_freezes_available
                when excluded.last_streak_freeze_reset is null then t.streak_freezes_available
                when excluded.last_streak_freeze_reset > t.last_streak_freeze_reset
                    then excluded.streak_freezes_available
                when t.last_streak_freeze_reset > excluded.last_streak_freeze_reset
                    then t.streak_freezes_available
                else least(t.streak_freezes_available, excluded.streak_freezes_available)
            end,
            last_streak_freeze_reset = greatest(t.last_streak_freeze_reset, excluded.last_streak_freeze_reset),
            streak_freeze_used_on = greatest(t.streak_freeze_used_on, excluded.streak_freeze_used_on),
            updated_at = now();

        delete from public.player_progress where user_id = p_anonymous_id;
        v_moved := v_moved || jsonb_build_object('progress', true);
    end if;

    -- Keys of the anonymous misses, taken before those rows change owner.
    -- The collapse below only touches a diagnosis-day that came from this
    -- anonymous account. Older duplicates that belong only to the email
    -- account are left in place.
    select coalesce(array_agg(distinct lower(btrim(item)) || '|' || (occurred_at::date)::text), '{}')
      into v_anon_miss_keys
      from public.missed_items
     where user_id = p_anonymous_id
       and btrim(coalesce(item, '')) <> '';

    -- Reviewed wins if either copy was reviewed, then reassign the rest.
    update public.missed_items t
       set reviewed = t.reviewed or a.reviewed
      from public.missed_items a
     where t.user_id = v_target
       and a.user_id = p_anonymous_id
       and t.id = a.id;

    update public.case_history h
       set user_id = v_target
     where h.user_id = p_anonymous_id
       and not exists (
           select 1 from public.case_history t
            where t.user_id = v_target and t.id = h.id
       );
    get diagnostics v_count = row_count;
    if v_count > 0 then
        v_moved := v_moved || jsonb_build_object('case_history', v_count);
    end if;
    delete from public.case_history h
     where h.user_id = p_anonymous_id
       and exists (
           select 1 from public.case_history t
            where t.user_id = v_target and t.id = h.id
       );

    update public.missed_items h
       set user_id = v_target
     where h.user_id = p_anonymous_id
       and not exists (
           select 1 from public.missed_items t
            where t.user_id = v_target and t.id = h.id
       );
    get diagnostics v_count = row_count;
    if v_count > 0 then
        v_moved := v_moved || jsonb_build_object('missed_items', v_count);
    end if;
    delete from public.missed_items h
     where h.user_id = p_anonymous_id
       and exists (
           select 1 from public.missed_items t
            where t.user_id = v_target and t.id = h.id
       );

    -- One row per diagnosis per database date of occurred_at, matching the
    -- day comparison in the live record_case_play. The reviewed copy is kept
    -- (true sorts first). Other copies are deleted. reviewed is never set
    -- back to false, and detail and source on the kept row are not rewritten.
    with ranked as (
        select id,
               row_number() over (
                   partition by lower(btrim(item)), occurred_at::date
                   order by reviewed desc, occurred_at, id
               ) as rn
          from public.missed_items
         where user_id = v_target
           and btrim(coalesce(item, '')) <> ''
           and (lower(btrim(item)) || '|' || (occurred_at::date)::text) = any(v_anon_miss_keys)
    )
    delete from public.missed_items m
     using ranked r
     where m.id = r.id
       and r.rn > 1;

    update public.ddx_sessions h
       set user_id = v_target
     where h.user_id = p_anonymous_id
       and not exists (
           select 1 from public.ddx_sessions t
            where t.user_id = v_target and t.id = h.id
       );
    get diagnostics v_count = row_count;
    if v_count > 0 then
        v_moved := v_moved || jsonb_build_object('ddx_sessions', v_count);
    end if;
    delete from public.ddx_sessions h
     where h.user_id = p_anonymous_id
       and exists (
           select 1 from public.ddx_sessions t
            where t.user_id = v_target and t.id = h.id
       );

    if exists (select 1 from public.achievements where user_id = p_anonymous_id) then
        insert into public.achievements as t (
            user_id, unlocked, first_hint_win_count, category_stats,
            streak_freezes_available, last_streak_freeze_reset
        )
        select v_target, unlocked, first_hint_win_count, category_stats,
               streak_freezes_available, last_streak_freeze_reset
          from public.achievements where user_id = p_anonymous_id
        on conflict (user_id) do update set
            unlocked = (
                select coalesce(array_agg(distinct a), '{}')
                from unnest(t.unlocked || excluded.unlocked) as a
            ),
            first_hint_win_count = greatest(t.first_hint_win_count, excluded.first_hint_win_count),
            category_stats = excluded.category_stats || t.category_stats,
            streak_freezes_available = case
                when t.last_streak_freeze_reset is null then excluded.streak_freezes_available
                when excluded.last_streak_freeze_reset is null then t.streak_freezes_available
                when excluded.last_streak_freeze_reset > t.last_streak_freeze_reset
                    then excluded.streak_freezes_available
                when t.last_streak_freeze_reset > excluded.last_streak_freeze_reset
                    then t.streak_freezes_available
                else least(t.streak_freezes_available, excluded.streak_freezes_available)
            end,
            last_streak_freeze_reset = greatest(t.last_streak_freeze_reset, excluded.last_streak_freeze_reset),
            updated_at = now();

        delete from public.achievements where user_id = p_anonymous_id;
        v_moved := v_moved || jsonb_build_object('achievements', true);
    end if;

    -- One leaderboard row per account. Scores take the max; an empty name or
    -- school on the email account is filled from the anonymous row. The
    -- anonymous row is removed only after those fields have been copied.
    if exists (select 1 from public.leaderboard_entries where user_id = p_anonymous_id) then
        if exists (select 1 from public.leaderboard_entries where user_id = v_target) then
            update public.leaderboard_entries t
               set total_score  = greatest(t.total_score, a.total_score),
                   games_played = greatest(t.games_played, a.games_played),
                   games_won    = greatest(t.games_won, a.games_won),
                   display_name = case when t.display_name = '' then a.display_name else t.display_name end,
                   school_id    = case when t.school_id = '' then a.school_id else t.school_id end,
                   school_name  = case when t.school_name = '' then a.school_name else t.school_name end,
                   state        = case when t.state = '' then a.state else t.state end,
                   legacy_player_id = coalesce(t.legacy_player_id, a.legacy_player_id),
                   updated_at = now()
              from public.leaderboard_entries a
             where t.user_id = v_target
               and a.user_id = p_anonymous_id;
            delete from public.leaderboard_entries where user_id = p_anonymous_id;
        else
            update public.leaderboard_entries
               set user_id = v_target, updated_at = now()
             where user_id = p_anonymous_id;
        end if;
        v_moved := v_moved || jsonb_build_object('leaderboard', true);
    end if;

    -- Paid-subscription mirror. pro_source was already carried when the token
    -- proved ownership; these columns were not, so an App Store purchase on
    -- the anonymous id vanished on claim. Keep the live side, preferring a
    -- non-expiring (lifetime) grant, then the later expiry, then the later
    -- update. Without a matching ticket this block does not run.
    if v_proven then
    v_anon_live := v_anon.subscription_status in ('active','trialing','grace_period','billing_issue')
        and (v_anon.subscription_expires_at is null or v_anon.subscription_expires_at > now());
    v_tgt_live := v_target_p.subscription_status in ('active','trialing','grace_period','billing_issue')
        and (v_target_p.subscription_expires_at is null or v_target_p.subscription_expires_at > now());

    if v_anon_live and not v_tgt_live then
        v_take_anon := true;
    elsif v_anon_live and v_tgt_live then
        if v_anon.subscription_expires_at is null and v_target_p.subscription_expires_at is not null then
            v_take_anon := true;
        elsif v_anon.subscription_expires_at is not null
              and v_target_p.subscription_expires_at is not null
              and v_anon.subscription_expires_at > v_target_p.subscription_expires_at then
            v_take_anon := true;
        elsif v_anon.subscription_expires_at is not distinct from v_target_p.subscription_expires_at
              and coalesce(v_anon.subscription_updated_at, '-infinity'::timestamptz)
                  > coalesce(v_target_p.subscription_updated_at, '-infinity'::timestamptz) then
            v_take_anon := true;
        end if;
    elsif not v_tgt_live
          and v_anon.subscription_status is distinct from 'free'
          and coalesce(v_anon.subscription_updated_at, '-infinity'::timestamptz)
              > coalesce(v_target_p.subscription_updated_at, '-infinity'::timestamptz) then
        v_take_anon := true;
    end if;

    if v_take_anon then
        update public.profiles
           set subscription_status = v_anon.subscription_status,
               subscription_product_id = v_anon.subscription_product_id,
               subscription_store = v_anon.subscription_store,
               subscription_expires_at = v_anon.subscription_expires_at,
               subscription_will_renew = v_anon.subscription_will_renew,
               subscription_period_type = v_anon.subscription_period_type,
               subscription_updated_at = v_anon.subscription_updated_at,
               rc_last_event_id = v_anon.rc_last_event_id
         where id = v_target;
        v_moved := v_moved || jsonb_build_object('subscription', true);
    end if;
    end if;

    -- A migration marker on the anonymous id must not count as the email
    -- account being migrated. Leave the target's marker untouched.
    -- Pro and the subscription mirror are cleared only after a proven copy.
    -- An unproven claim leaves them on the anonymous row. Campaign attribution
    -- is cleared only when this call copied it, or when the token was proven
    -- (the same clear the live function always did for the owner).
    if v_proven then
        update public.profiles
           set pro_source = 'none',
               attributed_campaign_id = null,
               subscription_status = 'free',
               subscription_will_renew = false
         where id = p_anonymous_id;
    elsif v_campaign_copied then
        update public.profiles
           set attributed_campaign_id = null
         where id = p_anonymous_id;
    end if;

    if v_proven then
        update public.anonymous_claim_tickets
           set claimed_by = v_target
         where anon_id = p_anonymous_id
           and claimed_by is null;
    end if;

    return jsonb_build_object('status', 'claimed', 'moved', v_moved);
end;
$$;

revoke all on function public.claim_anonymous_account(uuid, text) from public, anon;
grant execute on function public.claim_anonymous_account(uuid, text) to authenticated, service_role;

-- Shipping 1.5 calls claim_anonymous_account with one argument. No default on
-- the two-argument function, so that call resolves here and passes a null
-- token. Progress moves only when that anonymous id is not on a school or
-- global leaderboard row. A public row returns proof_required and deletes
-- nothing. The paid subscription never moves without a token.
create or replace function public.claim_anonymous_account(p_anonymous_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
    return public.claim_anonymous_account(p_anonymous_id, null);
end;
$$;

revoke all on function public.claim_anonymous_account(uuid) from public, anon;
grant execute on function public.claim_anonymous_account(uuid) to authenticated, service_role;

-- =========================================================================
-- One weekly freeze, one spend per local day. The client may call this as
-- often as it likes; a second spend on the same day is a no-op.
-- p_is_pro stays in the signature so shipping 1.5 clients can still call this.
-- The grant and the spend use public.profile_has_pro(auth.uid()), which is
-- already on production. The argument is not trusted.
-- =========================================================================
create or replace function public.sync_streak_freeze(
    p_local_day date,
    p_is_pro boolean,
    p_spend boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user uuid := auth.uid();
    v_row  public.player_progress%rowtype;
    v_spent boolean := false;
    v_is_pro boolean := false;
begin
    if v_user is null then
        raise exception 'not_authenticated';
    end if;
    if p_local_day is null then
        raise exception 'missing_day';
    end if;
    -- The phone's local today is at most one day off UTC. Anything further
    -- away is rejected rather than granting or spending a freeze for it.
    if p_local_day < (timezone('utc', now()))::date - 1
       or p_local_day > (timezone('utc', now()))::date + 1 then
        raise exception 'bad_day';
    end if;

    insert into public.player_progress (user_id)
    values (v_user)
    on conflict (user_id) do nothing;

    select * into v_row
      from public.player_progress
     where user_id = v_user
       for update;

    v_is_pro := public.profile_has_pro(v_user);

    if v_is_pro then
        if v_row.last_streak_freeze_reset is null
           or (p_local_day - v_row.last_streak_freeze_reset) >= 7 then
            v_row.streak_freezes_available := 1;
            v_row.last_streak_freeze_reset := p_local_day;
            v_row.streak_freeze_used_on := null;
        end if;
    end if;

    if coalesce(p_spend, false)
       and v_is_pro
       and v_row.streak_freezes_available > 0
       and (v_row.streak_freeze_used_on is null or v_row.streak_freeze_used_on < p_local_day) then
        v_row.streak_freezes_available := v_row.streak_freezes_available - 1;
        v_row.streak_freeze_used_on := p_local_day;
        v_spent := true;
    end if;

    update public.player_progress
       set streak_freezes_available = v_row.streak_freezes_available,
           last_streak_freeze_reset = v_row.last_streak_freeze_reset,
           streak_freeze_used_on = v_row.streak_freeze_used_on,
           updated_at = now()
     where user_id = v_user;

    update public.achievements
       set streak_freezes_available = v_row.streak_freezes_available,
           last_streak_freeze_reset = v_row.last_streak_freeze_reset::timestamptz,
           updated_at = now()
     where user_id = v_user;

    return jsonb_build_object(
        'available', v_row.streak_freezes_available,
        'used_on', v_row.streak_freeze_used_on,
        'reset_on', v_row.last_streak_freeze_reset,
        'spent', v_spent
    );
end;
$$;

revoke all on function public.sync_streak_freeze(date, boolean, boolean) from public, anon;
grant execute on function public.sync_streak_freeze(date, boolean, boolean) to authenticated, service_role;

-- =========================================================================
-- Sets profiles.migrated_v2_at only when the server already holds at least
-- as many rows as the device counted. The device must not set its own flag
-- unless this returns confirmed = true.
--
-- The privileged-column trigger ignores a marker write unless this function
-- has set rounds.migrated_v2_writer for the transaction, or the caller is
-- service_role. The returned confirmed flag is true only when the row still
-- holds a timestamp after that trigger runs.
-- =========================================================================
create or replace function public.confirm_migration_v2(
    p_case_history_count integer,
    p_missed_items_count integer,
    p_ddx_sessions_count integer,
    p_has_achievements boolean
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user uuid := auth.uid();
    v_history integer;
    v_misses integer;
    v_ddx integer;
    v_achievements boolean;
    v_ok boolean;
    v_marker timestamptz;
begin
    if v_user is null then
        raise exception 'not_authenticated';
    end if;

    select count(*) into v_history from public.case_history where user_id = v_user;
    select count(*) into v_misses from public.missed_items where user_id = v_user;
    select count(*) into v_ddx from public.ddx_sessions where user_id = v_user;
    select exists (select 1 from public.achievements where user_id = v_user) into v_achievements;

    v_ok := v_history >= greatest(coalesce(p_case_history_count, 0), 0)
        and v_misses >= greatest(coalesce(p_missed_items_count, 0), 0)
        and v_ddx >= greatest(coalesce(p_ddx_sessions_count, 0), 0)
        and (not coalesce(p_has_achievements, false) or v_achievements);

    if v_ok then
        perform set_config('rounds.migrated_v2_writer', 'confirm_migration_v2', true);
        update public.profiles
           set migrated_v2_at = coalesce(migrated_v2_at, now())
         where id = v_user
         returning migrated_v2_at into v_marker;
        perform set_config('rounds.migrated_v2_writer', '', true);
        v_ok := v_marker is not null;
    end if;

    return jsonb_build_object(
        'confirmed', v_ok,
        'server_case_history', v_history,
        'server_missed_items', v_misses,
        'server_ddx_sessions', v_ddx,
        'server_achievements', v_achievements
    );
end;
$$;

revoke all on function public.confirm_migration_v2(integer, integer, integer, boolean) from public, anon;
grant execute on function public.confirm_migration_v2(integer, integer, integer, boolean) to authenticated, service_role;

-- =========================================================================
-- Deletes the signed-in auth user. profiles.id references auth.users
-- ON DELETE CASCADE, and the progress tables cascade from profiles, so the
-- backup goes with the account. referred_by has no ON DELETE clause, so those
-- pointers are cleared first. The phone's SwiftData copy is not touched;
-- the app never sends a local wipe.
-- =========================================================================
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
    uid uuid := auth.uid();
begin
    if uid is null then
        raise exception 'not_authenticated';
    end if;

    -- Staff and live team memberships are not self-serve deletes.
    if exists (
        select 1 from public.profiles
         where id = uid
           and (role in ('owner', 'admin') or role_slug is not null)
    ) or exists (
        select 1 from public.team_members
         where user_id = uid
           and status <> 'suspended'
    ) then
        raise exception 'team_account';
    end if;

    -- These have no foreign key to auth.users, so deleting the auth user
    -- would leave them behind. Each statement runs only when the table and
    -- the column exist. feed_mentions keeps the row and clears
    -- mentioned_user_id, which is nullable. player_announcement_events is
    -- on production (web PR 200); the check stays so a missing table is skipped.
    if to_regclass('public.feed_reactions') is not null
       and exists (
           select 1 from information_schema.columns
            where table_schema = 'public' and table_name = 'feed_reactions' and column_name = 'user_id'
       ) then
        execute 'delete from public.feed_reactions where user_id = $1' using uid;
    end if;

    if to_regclass('public.feed_reads') is not null
       and exists (
           select 1 from information_schema.columns
            where table_schema = 'public' and table_name = 'feed_reads' and column_name = 'user_id'
       ) then
        execute 'delete from public.feed_reads where user_id = $1' using uid;
    end if;

    if to_regclass('public.feed_mentions') is not null
       and exists (
           select 1 from information_schema.columns
            where table_schema = 'public' and table_name = 'feed_mentions' and column_name = 'mentioned_user_id'
       ) then
        execute 'update public.feed_mentions set mentioned_user_id = null where mentioned_user_id = $1' using uid;
    end if;

    if to_regclass('public.player_announcement_events') is not null
       and exists (
           select 1 from information_schema.columns
            where table_schema = 'public'
              and table_name = 'player_announcement_events'
              and column_name = 'user_id'
       ) then
        execute 'delete from public.player_announcement_events where user_id = $1' using uid;
    end if;

    update public.profiles set referred_by = null where referred_by = uid;
    delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated, service_role;

-- =========================================================================
-- Rollback (do not run as part of applying this file)
--
-- Nothing in this file drops a column, table, or policy. "update own
-- profile" stays. anonymous_claim_tickets has row level security and no
-- policies. Run the steps below by hand, in this order, only to take the
-- file back after it has been applied.
--
-- 1. Trigger, then the marker column. protect_profiles_privileged_columns()
--    assigns new.migrated_v2_at. Dropping the column first makes every
--    profile insert and update fail.
--      a. Replace the function with the body recorded in roundsapp-landing
--         supabase/migrations/20261008211720_profiles_lockdown_privileged_columns.sql.
--         That body does not mention migrated_v2_at. Leave the trigger
--         trg_protect_profiles_privileged in place. Do not re-run that
--         file's REVOKE. Live column UPDATE grants for authenticated are
--         first_name, school_year, exam_date, target_score,
--         show_in_activity, and nudges. school is not among them.
--      b. Then, only if nothing in production reads the marker:
--           alter table public.profiles drop column if exists migrated_v2_at;
--         Shipping 1.5 and the web do not read it.
--      c. To set or clear one row without dropping the column, as
--         service_role, or as postgres in the same transaction:
--           select set_config('rounds.migrated_v2_writer', 'confirm_migration_v2', true);
--           update public.profiles set migrated_v2_at = null where id = '...';
--           select set_config('rounds.migrated_v2_writer', '', true);
--         supabase_admin cannot write the marker. postgres cannot either
--         unless that setting is confirm_migration_v2 during the update.
--
-- 2. Both claim functions. Drop the two-argument one first so the name is
--    not overloaded, then put the one-argument function back to the live
--    body in supabase/schema_claim_full_data.sql. Do not apply
--    schema_sync.sql: that body does not move case history, misses,
--    differentials, achievements, or the leaderboard row.
--      drop function if exists public.claim_anonymous_account(uuid, text);
--      -- then re-apply only the function in schema_claim_full_data.sql,
--      -- which is claim_anonymous_account(uuid)
--
-- 3. The ticket. Drop the function before the table. claimed_by is a column
--    of anonymous_claim_tickets; dropping the table drops it. To remove only
--    that column and keep the table:
--      alter table public.anonymous_claim_tickets drop column if exists claimed_by;
--      drop function if exists public.begin_anonymous_claim();
--      drop table if exists public.anonymous_claim_tickets;
--    There is no policy to drop. The table's ON DELETE CASCADE follows
--    auth.users, so dropping the table does not delete users.
--
-- 4. Functions this file created, after the app that calls them is gone.
--    Dropping them while 1.5 or this build still calls them breaks those
--    clients. Drop the functions before the columns they read.
--      drop function if exists public.sync_streak_freeze(date, boolean, boolean);
--      drop function if exists public.confirm_migration_v2(integer, integer, integer, boolean);
--      drop function if exists public.delete_own_account();
--      alter table public.player_progress drop constraint if exists player_progress_freezes_nonnegative;
--      alter table public.player_progress drop column if exists streak_freeze_used_on;
--      alter table public.player_progress drop column if exists last_streak_freeze_reset;
--      alter table public.player_progress drop column if exists streak_freezes_available;
--
-- 5. sync_progress. This file replaces the body and keeps the argument list.
--    Production's current body is whatever is live before this file runs.
--    Restore that body from a dump taken before the apply. Do not restore
--    it by re-applying schema_sync.sql, because that file also replaces
--    claim_anonymous_account with the short version.
-- =========================================================================
