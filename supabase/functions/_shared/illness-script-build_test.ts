import {
  BUILD_STALE_MS,
  BUILD_STALE_SECONDS,
  PAID_WALL_CLOCK_MS,
  buildIsInFlight,
} from "./illness-script-build.ts";

function assert(cond: unknown, msg = "assertion failed"): asserts cond {
  if (!cond) throw new Error(msg);
}

function assertEquals(actual: unknown, expected: unknown, msg?: string) {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a !== e) throw new Error(msg ?? `expected ${e} got ${a}`);
}

Deno.test("in-flight window is 8 minutes and outlives the paid wall clock", () => {
  assertEquals(BUILD_STALE_SECONDS, 480);
  assertEquals(BUILD_STALE_MS, 8 * 60 * 1000);
  assertEquals(PAID_WALL_CLOCK_MS, 400_000);
  // Reclaiming sooner than the worker can legally run would start a second
  // build while the first is still inside waitUntil.
  assert(BUILD_STALE_MS > PAID_WALL_CLOCK_MS);
});

Deno.test("a build is in flight through exactly 8 minutes", () => {
  const started = 1_700_000_000_000;
  assert(buildIsInFlight(started, started));
  assert(buildIsInFlight(started, started + BUILD_STALE_MS - 1));
  assert(buildIsInFlight(started, started + BUILD_STALE_MS));
  assert(!buildIsInFlight(started, started + BUILD_STALE_MS + 1));
});

Deno.test("migration matches the stale window and lets players read", async () => {
  const sql = await Deno.readTextFile(
    new URL("../../migrations/20261123131500_illness_script_builds.sql", import.meta.url),
  );
  assert(sql.includes("default 480"));
  assert(sql.includes("p_stale_seconds int default 480"));
  assert(sql.includes("illness_script_builds_read"));
  assert(sql.includes("grant select on public.illness_script_builds to authenticated"));
  assert(sql.includes("to service_role"));
  assert(sql.includes("security definer"));
  assert(sql.includes("set search_path = public"));
  assert(sql.includes("revoke all on function public.claim_illness_script_build(text, text, boolean, int)"));
  assert(sql.includes("status in ('building', 'done', 'failed')"));
  assert(!sql.includes("grant insert") && !sql.includes("grant select, insert on public.illness_script_builds to authenticated"));
});
