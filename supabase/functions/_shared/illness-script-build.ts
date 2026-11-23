// Timing shared by the illness-script background builder and its migration.
//
// Supabase's paid-plan edge worker lives 400s of wall clock, and that clock
// includes EdgeRuntime.waitUntil
// (https://supabase.com/docs/guides/functions/limits). The claim function's
// stale window must be longer than that, so a live build is not started twice,
// and shorter than "forever", so a worker the runtime killed can be replaced.

/** Default of claim_illness_script_build(p_stale_seconds). 8 minutes. */
export const BUILD_STALE_SECONDS = 480;
export const BUILD_STALE_MS = BUILD_STALE_SECONDS * 1000;

/** Paid-plan worker lifetime. Free plan is 150s and cannot host a full build. */
export const PAID_WALL_CLOCK_MS = 400_000;

/**
 * True while a build started at `startedAtMs` should be left alone.
 * Matches the SQL reclaim predicate: a row is still in flight when
 * `started_at >= now() - interval`, i.e. its age is <= 8 minutes.
 * At exactly 8 minutes it is still in flight; 1ms later it can be reclaimed.
 */
export function buildIsInFlight(startedAtMs: number, nowMs: number): boolean {
  return nowMs - startedAtMs <= BUILD_STALE_MS;
}
