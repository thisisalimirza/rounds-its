-- Rounds — carry the full data model across an anonymous-account claim
--
-- NOT YET APPLIED. Run this in the Supabase SQL editor.
--
-- `claim_anonymous_account()` was written when the only server-side state was
-- `player_progress` plus the referral/campaign columns on `profiles`. The rest
-- of the model — case history, the miss log, saved differentials, achievements,
-- the leaderboard entry — landed later, and the claim never learned about it.
--
-- The gap shows up in the most common two-account path there is: play the app
-- anonymously for a week, then sign in with an email that already exists from
-- the web. The app signs into the email account and calls this function; today
-- the anonymous account's aggregate counters merge across and every actual
-- record stays behind on an account nobody can reach again. Games played would
-- say 40 while Case History showed nothing.
--
-- Safe to re-run. Only the function body changes.

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

    -- =====================================================================
    -- Per-row history. These tables are keyed on a client-generated id, so
    -- reassigning the owner is enough — the rows are already unique across
    -- both accounts and no merge rule is needed.
    -- =====================================================================
    update public.case_history set user_id = v_target where user_id = p_anonymous_id;
    get diagnostics v_count = row_count;
    if v_count > 0 then
        v_moved := v_moved || jsonb_build_object('case_history', v_count);
    end if;

    update public.missed_items set user_id = v_target where user_id = p_anonymous_id;
    get diagnostics v_count = row_count;
    if v_count > 0 then
        v_moved := v_moved || jsonb_build_object('missed_items', v_count);
    end if;

    update public.ddx_sessions set user_id = v_target where user_id = p_anonymous_id;
    get diagnostics v_count = row_count;
    if v_count > 0 then
        v_moved := v_moved || jsonb_build_object('ddx_sessions', v_count);
    end if;

    -- =====================================================================
    -- One-row-per-user tables. user_id is the primary key, so these cannot
    -- simply be reassigned when the target already has a row.
    -- =====================================================================

    -- Achievements merge: unlocks are a union and counters take the max,
    -- mirroring the client-side merge so both sides agree.
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
            -- Object merge, so categories only one side knows about survive.
            -- Overlapping keys keep the target's, which is the account the
            -- user is actually keeping.
            category_stats = excluded.category_stats || t.category_stats,
            -- Deliberately NOT merged: the weekly Pro freeze allowance. Taking
            -- the max would hand out a second freeze for redeeming and merging.
            updated_at = now();

        delete from public.achievements where user_id = p_anonymous_id;
        v_moved := v_moved || jsonb_build_object('achievements', true);
    end if;

    -- Leaderboard: one entry per account by design. The target's own entry
    -- wins when it has one, since that is the identity tied to the email the
    -- user just proved they own; the scores are re-pushed by the client from
    -- the merged progress on the next sync either way.
    if exists (select 1 from public.leaderboard_entries where user_id = p_anonymous_id) then
        if exists (select 1 from public.leaderboard_entries where user_id = v_target) then
            delete from public.leaderboard_entries where user_id = p_anonymous_id;
        else
            update public.leaderboard_entries
               set user_id = v_target, updated_at = now()
             where user_id = p_anonymous_id;
            v_moved := v_moved || jsonb_build_object('leaderboard', true);
        end if;
    end if;

    -- Mark the source account so it is never absorbed twice.
    update public.profiles
       set pro_source = 'none', attributed_campaign_id = null
     where id = p_anonymous_id;

    return jsonb_build_object('status', 'claimed', 'moved', v_moved);
end;
$$;

-- Functions are executable by PUBLIC by default, and this one takes the
-- account to absorb as a parameter. Re-applied on every redefinition because
-- `create or replace` resets the grants.
revoke all on function public.claim_anonymous_account(uuid) from public, anon;
grant execute on function public.claim_anonymous_account(uuid) to authenticated, service_role;
