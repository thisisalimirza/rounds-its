-- Rounds — sync correctness, full anonymous claim, streak freezes, migration marker
--
-- NOT YET APPLIED. Apply this file once, in the Supabase SQL editor, after the
-- schema files already on production. Safe to re-run.
--
-- Backward compatible with the shipping 1.5 app and the web:
--   * no columns or tables are dropped or renamed
--   * sync_progress keeps its argument list, so 1.5 clients keep calling it
--   * no RLS policy on profiles, player_progress, or play_events is replaced
--
-- Do NOT re-apply supabase/schema_sync.sql or supabase/schema_claim_full_data.sql
-- after this file. Both define older copies of the two functions replaced here,
-- and running them later would put the streak bug and the partial claim back.
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
-- faculty_assignments (web PR 203) is not applied and is not touched.
--
-- Objects that are not on production yet are referenced only after a check,
-- via EXECUTE, so this file applies and runs today:
--   * profiles.cohort_reporting (web PR 203) and profiles.show_in_activity
--   * player_announcement_events (web PR 200)
--   * feed_reactions, feed_reads, feed_mentions (no foreign keys)
-- Web PR 200 (app_config, announcements, changelog public read) is not applied.
--
-- Functions created or replaced (conflict-check these names):
--   REPLACE public.sync_progress(integer, integer, integer, integer, integer,
--           integer[], text[], date, text, timestamptz)
--   REPLACE public.claim_anonymous_account(uuid)
--   CREATE  public.sync_streak_freeze(date, boolean, boolean)
--   CREATE  public.confirm_migration_v2(integer, integer, integer, boolean)
--   CREATE  public.delete_own_account()
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
-- claim_anonymous_account: move every row, merge conflicts, drop nothing
-- that the target does not already have.
--
-- Works whether case_history / missed_items / ddx_sessions are keyed on id
-- alone (shipping) or on (user_id, id) (schema_identity.sql, not yet applied).
-- A plain UPDATE of user_id is used only for ids the target does not hold.
-- Where both accounts have the same id, reviewed flags are OR-ed and the
-- anonymous copy is removed only after that merge.
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
    v_count    integer;
    v_anon_prog public.player_progress%rowtype;
    v_anon_live boolean;
    v_tgt_live boolean;
    v_take_anon boolean := false;
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

    if exists (select 1 from auth.users u
                where u.id = p_anonymous_id and u.email is not null) then
        return jsonb_build_object('status', 'not_anonymous');
    end if;

    select * into v_target_p from public.profiles where id = v_target;

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

    if v_target_p.attributed_campaign_id is null and v_anon.attributed_campaign_id is not null then
        update public.profiles
           set attributed_campaign_id = v_anon.attributed_campaign_id,
               attribution_source     = v_anon.attribution_source,
               attribution_set_at     = v_anon.attribution_set_at
         where id = v_target;
        v_moved := v_moved || jsonb_build_object('campaign', true);
    end if;

    -- Empty profile fields on the email account take the anonymous values.
    -- A field the email account already filled stays.
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

    -- cohort_reporting is added by web PR 203, which is not applied.
    -- show_in_activity may or may not be present. Neither is named in static
    -- SQL, so this function still compiles and runs when a column is absent.
    -- Null counts as opted in: coalesce(target, true) AND coalesce(anon, true).
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

    -- Paid-subscription mirror. pro_source was already carried; these columns
    -- were not, so an App Store purchase on the anonymous id vanished on claim.
    -- Keep the live side, preferring a non-expiring (lifetime) grant, then the
    -- later expiry, then the later update. The anonymous row is cleared below.
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

    -- A migration marker on the anonymous id must not count as the email
    -- account being migrated. Leave the target's marker untouched. Clearing
    -- the anonymous subscription mirror stops the abandoned id from also
    -- looking paid after the columns have been copied.
    update public.profiles
       set pro_source = 'none',
           attributed_campaign_id = null,
           subscription_status = 'free',
           subscription_will_renew = false
     where id = p_anonymous_id;

    return jsonb_build_object('status', 'claimed', 'moved', v_moved);
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
        update public.profiles
           set migrated_v2_at = coalesce(migrated_v2_at, now())
         where id = v_user;
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

    -- These have no foreign key to auth.users, so the cascade would leave them
    -- behind and a later constraint would not remove them. Each statement runs
    -- only when the table and the column exist. feed_mentions stores the
    -- person on mentioned_user_id (there is no user_id column).
    -- player_announcement_events is created by web PR 200, which is not applied.
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

    if to_regclass('public.feed_mentions') is not null then
        if exists (
            select 1 from information_schema.columns
             where table_schema = 'public' and table_name = 'feed_mentions' and column_name = 'user_id'
        ) then
            execute 'delete from public.feed_mentions where user_id = $1' using uid;
        elsif exists (
            select 1 from information_schema.columns
             where table_schema = 'public' and table_name = 'feed_mentions' and column_name = 'mentioned_user_id'
        ) then
            execute 'delete from public.feed_mentions where mentioned_user_id = $1' using uid;
        end if;
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
