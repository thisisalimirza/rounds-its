-- Rounds — recount player_progress from case_history
--
-- APPLIED once on 2026-07-27. Kept for the record and safe to re-run.
--
-- player_progress mirrors the phone's PlayerStats object, which is a running
-- total incremented after each game and therefore has no way to notice it is
-- wrong. Reinstalling the app creates a fresh zeroed one before CloudKit has
-- delivered anything; CloudKit then restores the CaseHistoryEntry rows without
-- necessarily restoring the aggregate. The phone uploads the corrupted total
-- faithfully.
--
-- That produced a live account reporting 1 game and 400 points on top of 206
-- games and 45,750 points of real history.
--
-- case_history is the record — one row per completed game — so the totals are
-- recounted from it. `greatest` throughout means this can only ever raise a
-- value: history cannot see games played before case_history existed, so a
-- stored number that is larger is treated as real.
--
-- The client-side half of this fix is PlayerStatsRepair.swift, which does the
-- same recount on device so the phone stops uploading the wrong number in the
-- first place.

with truth as (
    select h.user_id,
           count(*)                              as played,
           count(*) filter (where h.was_correct) as won,
           coalesce(sum(h.score), 0)             as score,
           max(h.played_at)::date                as last_day
      from public.case_history h
     group by h.user_id
)
update public.player_progress p
   set games_played     = greatest(p.games_played, t.played),
       games_won        = greatest(p.games_won,    t.won),
       total_score      = greatest(p.total_score,  t.score),
       last_played_date = greatest(p.last_played_date, t.last_day),
       updated_at       = now()
  from truth t
 where p.user_id = t.user_id
   and (p.games_played < t.played or p.games_won < t.won or p.total_score < t.score);
