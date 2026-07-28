-- Rounds — recording a completed case from anywhere
--
-- NOT YET APPLIED.
--
-- The web is about to become a place you can actually play, which means a
-- second client has to produce the same side effects as the iPhone when a case
-- ends: a history row, updated totals, a streak that moves correctly, and a
-- miss logged when the answer was wrong.
--
-- Reimplementing that in TypeScript would guarantee drift. Streak rules in
-- particular are fiddly — play twice in a day and the streak must not move,
-- lose your first game of the day and it breaks, lose your second and it must
-- not — and two implementations of that will not stay identical through a
-- single refactor. So the rule lives here once, and every client calls it.
--
-- The logic below is a deliberate transcription of PlayerStats.recordGame in
-- GameModels.swift. Where the two could differ, the Swift wins; if you change
-- one, change both.
--
-- WHY THE CLIENT SENDS ITS OWN DATE
--
-- Streaks and the daily case are both reckoned on the *device's* calendar day,
-- not the server's. Postgres current_date is UTC, so a student playing at 8pm
-- in California would have their play land on tomorrow and their streak would
-- break every single night. p_local_day is the browser's own date, exactly as
-- iOS uses Calendar.current.

create or replace function public.record_case_play(
    p_entry_id   uuid,
    p_case_id    uuid,
    p_diagnosis  text,
    p_category   text,
    p_difficulty integer,
    p_was_correct boolean,
    p_guess_count integer,
    p_score      integer,
    p_hints_used integer,
    p_guesses    text[],
    p_was_daily  boolean,
    p_local_day  date,
    p_played_at  timestamptz default now()
)
returns table (
    games_played   integer,
    games_won      integer,
    total_score    integer,
    current_streak integer,
    max_streak     integer,
    already_recorded boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
    v_uid          uuid := auth.uid();
    v_inserted     integer;
    v_progress     public.player_progress%rowtype;
    v_days_between integer;
    v_new_streak   integer;
    v_new_max      integer;
    v_dist         integer[];
begin
    if v_uid is null then
        raise exception 'not authenticated' using errcode = '28000';
    end if;

    -- Clamp rather than trust. These arrive from a browser, and the CHECK
    -- constraints on player_progress would otherwise turn a bad client into a
    -- failed insert the user cannot get past.
    p_guess_count := greatest(0, least(coalesce(p_guess_count, 0), 5));
    p_hints_used  := greatest(0, least(coalesce(p_hints_used, 0), 5));
    p_score       := greatest(0, least(coalesce(p_score, 0), 500));
    p_difficulty  := greatest(1, least(coalesce(p_difficulty, 3), 5));
    p_local_day   := coalesce(p_local_day, current_date);

    -- The history row is the idempotency key for this whole function. The
    -- client generates the id, so a double-submit — a retried request, a
    -- double-tapped button, a page restored from bfcache — inserts nothing the
    -- second time and must not then go on to increment the totals again.
    insert into public.case_history (
        id, user_id, case_id, diagnosis, category, difficulty,
        was_correct, guess_count, score, hints_used, guesses,
        was_daily_case, played_at
    )
    values (
        p_entry_id, v_uid, p_case_id, coalesce(p_diagnosis, ''), coalesce(p_category, ''),
        p_difficulty, coalesce(p_was_correct, false), p_guess_count, p_score,
        p_hints_used, coalesce(p_guesses, '{}'), coalesce(p_was_daily, false), p_played_at
    )
    on conflict (user_id, id) do nothing;

    get diagnostics v_inserted = row_count;

    select * into v_progress from public.player_progress where user_id = v_uid;

    if v_inserted = 0 then
        -- Already counted. Report the current standing rather than erroring:
        -- from the player's point of view the case is recorded, which is true.
        return query select
            coalesce(v_progress.games_played, 0),
            coalesce(v_progress.games_won, 0),
            coalesce(v_progress.total_score, 0),
            coalesce(v_progress.current_streak, 0),
            coalesce(v_progress.max_streak, 0),
            true;
        return;
    end if;

    if v_progress.user_id is null then
        insert into public.player_progress (user_id) values (v_uid)
        returning * into v_progress;
    end if;

    v_new_streak := v_progress.current_streak;
    v_new_max    := v_progress.max_streak;
    v_dist       := v_progress.guess_distribution;

    if v_progress.last_played_date is null then
        v_days_between := null;
    else
        v_days_between := p_local_day - v_progress.last_played_date;
    end if;

    if p_was_correct then
        -- Streak moves at most once per calendar day, mirroring the Swift:
        -- same day leaves it alone, yesterday extends it, a longer gap resets
        -- it to 1 rather than 0 — the win still counts as day one.
        if v_days_between is null then
            v_new_streak := 1;
            v_new_max    := greatest(v_new_max, 1);
        elsif v_days_between = 0 then
            null;  -- already played today
        elsif v_days_between = 1 then
            v_new_streak := v_new_streak + 1;
            v_new_max    := greatest(v_new_max, v_new_streak);
        else
            v_new_streak := 1;
            v_new_max    := greatest(v_new_max, 1);
        end if;

        if p_guess_count between 1 and array_length(v_dist, 1) then
            v_dist[p_guess_count] := coalesce(v_dist[p_guess_count], 0) + 1;
        end if;
    else
        -- A loss only breaks the streak if it is the first game of the day.
        -- Losing your second case after already winning one should not undo
        -- the day, and the Swift is careful about this.
        if v_days_between is null then
            v_new_streak := 0;
        elsif v_days_between >= 1 then
            v_new_streak := 0;
        end if;
    end if;

    update public.player_progress
       set games_played  = games_played + 1,
           games_won     = games_won + (case when p_was_correct then 1 else 0 end),
           total_score   = total_score + (case when p_was_correct then p_score else 0 end),
           current_streak = v_new_streak,
           max_streak     = greatest(v_new_max, v_new_streak),
           guess_distribution = v_dist,
           -- A set, kept as text[] to match what the device uploads.
           completed_case_ids = (
               select array(
                   select distinct e from unnest(
                       completed_case_ids || array[p_case_id::text]
                   ) as e
               )
           ),
           last_played_date = greatest(coalesce(last_played_date, p_local_day), p_local_day),
           last_daily_case_played = case
               when p_was_daily then to_char(p_local_day, 'YYYY-MM-DD')
               else last_daily_case_played
           end,
           updated_at = now()
     where user_id = v_uid
     returning * into v_progress;

    -- A wrong answer feeds Weak Spots and the study plan. Deduped by topic and
    -- day, the same way the iOS backfill does it, so replaying a case you keep
    -- getting wrong on one afternoon does not bury everything else.
    if not p_was_correct and coalesce(p_diagnosis, '') <> '' then
        insert into public.missed_items (id, user_id, source, topic, item, occurred_at)
        select gen_random_uuid(), v_uid, 'dailyCase',
               nullif(coalesce(p_category, ''), ''), p_diagnosis, p_played_at
        where not exists (
            select 1 from public.missed_items m
             where m.user_id = v_uid
               and lower(m.item) = lower(p_diagnosis)
               and m.occurred_at::date = p_local_day
        );
    end if;

    return query select
        v_progress.games_played,
        v_progress.games_won,
        v_progress.total_score,
        v_progress.current_streak,
        v_progress.max_streak,
        false;
end;
$$;

revoke all on function public.record_case_play(
    uuid, uuid, text, text, integer, boolean, integer, integer, integer,
    text[], boolean, date, timestamptz
) from public, anon;

grant execute on function public.record_case_play(
    uuid, uuid, text, text, integer, boolean, integer, integer, integer,
    text[], boolean, date, timestamptz
) to authenticated;

-- =========================================================================
-- The daily case for a given local day.
--
-- A function rather than a direct select so the web and the app agree on the
-- fallback: an unscheduled day returns nothing, and the caller decides what to
-- do, rather than each client inventing its own pick and showing two different
-- people two different "daily" cases.
-- =========================================================================
create or replace function public.daily_case_for(p_day date)
returns table (
    id uuid,
    diagnosis text,
    diagnosis_slug text,
    alternative_names text[],
    hints text[],
    category text,
    difficulty integer
)
language sql
stable
security definer
set search_path = public
as $$
    select c.id, c.diagnosis, c.diagnosis_slug, c.alternative_names,
           c.hints, c.category, c.difficulty
      from public.daily_cases d
      join public.cases c on c.id = d.case_id
     where d.day = p_day
       and c.is_published
     limit 1
$$;

grant execute on function public.daily_case_for(date) to anon, authenticated;

-- =========================================================================
-- Verify
-- =========================================================================
-- select * from public.daily_case_for(current_date);
--
-- Idempotency — run twice, games_played must move exactly once:
-- select * from public.record_case_play(
--     gen_random_uuid(), '<case uuid>', 'Sarcoidosis', 'Pulm', 3,
--     true, 2, 300, 2, array['asthma','sarcoidosis'], false, current_date);
