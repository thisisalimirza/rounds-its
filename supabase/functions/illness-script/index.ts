// Rounds — illness-script edge function
//
// Returns a rich, shelf-ready ILLNESS SCRIPT for a condition, cached globally.
//
// Resolution ladder (cheap → expensive) so typos & synonyms cost no API call:
//   1. Exact normalized key hit                → serve stored script.
//   2. Known alias hit                         → resolve → serve stored script.
//   3. Fuzzy (pg_trgm) match above threshold   → learn alias → serve stored.
//   4. Miss → draft + one review pass, then store the corrected script only.
// Stored scripts below the current schema version regenerate in place on open.
// That update keeps condition_key (so aliases still resolve) and does not
// reset miss_count / review_count; the request then bumps the counters.
//
// Sync callers (the shipped iOS app — no "async" field) stay on this ladder,
// including the whitespace keepalive that survives the 150s gateway idle
// limit. They use the fast thinking profile.
//
// Async callers (body `{async: true}`) use the same ladder. A fresh v2 row
// is returned immediately as 200 in the same shape. Otherwise the function
// claims a row in illness_script_builds, returns
//   202 {status:"building", condition_key, condition}
// and finishes a full-quality build in EdgeRuntime.waitUntil. A claim that
// is still building and started less than 8 minutes ago does not start a
// second build; it returns the same 202.
//
// Status (does not bump counters):
//   GET  /illness-script?status_for=<name or key>
//   POST {"status_for":"<name or key>"}
//   → {status:"building", condition_key, condition, started_at}
//   → {status:"done", condition_key, cached:true, ...script}
//   → {status:"failed", condition_key, condition, error}
//   → 404 {error:"not_found", condition_key} when nothing is cached or queued
// Poll the condition_key from the 202. A display name normalizes to the same
// key. A building row older than 8 minutes is reported as failed/timed_out.
//
// Deploy (manual):  supabase functions deploy illness-script
// The builds table migration is applied separately and is not deployed here.

import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";
import Anthropic from "npm:@anthropic-ai/sdk@0.68.0";
import { buildIsInFlight } from "../_shared/illness-script-build.ts";
import {
  generateIllnessScript,
  normalizeKey,
  SCHEMA_VERSION,
  scriptRowUpdate,
  type IllnessScript,
  type ScriptQuality,
} from "../_shared/illness-script-prompt.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

const FUZZY_MIN_SIMILARITY = 0.6;

function rowToShape(row: Record<string, unknown>): IllnessScript {
  return {
    condition: (row.condition as string) ?? "",
    system: (row.system as string) ?? "",
    definition: (row.one_liner as string) ?? "",
    predisposing: (row.predisposing as string[]) ?? [],
    pathophysiology: (row.pathophysiology as string[]) ?? [],
    presentation: (row.presentation as string[]) ?? [],
    diagnostics: (row.diagnostics as string[]) ?? [],
    management: (row.management as string[]) ?? [],
    pivots: (row.pivots as IllnessScript["pivots"]) ?? [],
  };
}

function isFresh(row: Record<string, unknown> | null): row is Record<string, unknown> {
  return !!row && ((row.schema_version as number | null) ?? 0) >= SCHEMA_VERSION;
}

function publicError(err: unknown): string {
  const raw = err instanceof Error ? err.message : String(err);
  return raw.replace(/sk-ant-[A-Za-z0-9_-]+/g, "[redacted]").slice(0, 500);
}

// A cached script answers in well under a second, so it is returned as-is.
// Building one takes about a minute: past HEARTBEAT_AFTER_MS the response
// switches to a 200 stream that sends a space every HEARTBEAT_EVERY_MS (JSON
// allows leading whitespace) and ends with the real JSON body. That keeps the
// gateway's 150s idle timer and client idle timeouts (iOS 60s) from cutting
// the request. Errors after the switch arrive as {"error": ...} with 200.
const HEARTBEAT_AFTER_MS = 4_000;
const HEARTBEAT_EVERY_MS = 5_000;

async function respondWithHeartbeat(pending: Promise<Response>): Promise<Response> {
  const early = await Promise.race([
    pending,
    new Promise<null>((resolve) => setTimeout(() => resolve(null), HEARTBEAT_AFTER_MS)),
  ]);
  if (early) return early;

  const enc = new TextEncoder();
  let beat: ReturnType<typeof setInterval> | undefined;
  const body = new ReadableStream<Uint8Array>({
    start(ctrl) {
      ctrl.enqueue(enc.encode(" "));
      beat = setInterval(() => {
        try { ctrl.enqueue(enc.encode(" ")); } catch { /* client gone */ }
      }, HEARTBEAT_EVERY_MS);
      pending
        .then((res) => res.text())
        .catch((err) => JSON.stringify({ error: "claude_failed", detail: String(err) }))
        .then((text) => {
          clearInterval(beat);
          try { ctrl.enqueue(enc.encode(text)); ctrl.close(); } catch { /* client gone */ }
        });
    },
    cancel() { clearInterval(beat); },
  });
  return new Response(body, { status: 200, headers: { ...cors, "Content-Type": "application/json" } });
}

type EdgeRuntimeGlobal = { waitUntil(promise: Promise<unknown>): void };

function backgroundRuntime(): EdgeRuntimeGlobal {
  const runtime = (globalThis as { EdgeRuntime?: EdgeRuntimeGlobal }).EdgeRuntime;
  if (!runtime?.waitUntil) throw new Error("background_unsupported");
  return runtime;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const authHeader = req.headers.get("Authorization") ?? "";
  const anon = createClient(
    Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user }, error: userErr } = await anon.auth.getUser();
  if (userErr || !user) return json({ error: "not_authenticated" }, 401);

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  if (req.method === "GET") {
    const url = new URL(req.url);
    const q = url.searchParams.get("status_for") ?? url.searchParams.get("condition") ?? "";
    if (!q.trim()) return json({ error: "missing_condition" }, 400);
    return await readStatus(admin, q);
  }
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  let condition = "";
  let reason = "review";
  let wantAsync = false;
  let statusFor: string | null = null;
  try {
    const body = await req.json();
    condition = (body?.condition ?? "").toString().trim();
    reason = (body?.reason ?? "review").toString();
    wantAsync = body?.async === true;
    if (typeof body?.status_for === "string") statusFor = body.status_for;
  } catch { /* empty body */ }

  if (statusFor !== null) {
    if (!statusFor.trim()) return json({ error: "missing_condition" }, 400);
    return await readStatus(admin, statusFor);
  }
  if (!condition) return json({ error: "missing_condition" }, 400);

  const inputKey = normalizeKey(condition);
  if (!inputKey) return json({ error: "missing_condition" }, 400);

  const isMiss = reason === "miss";
  const SELECT = "condition, system, one_liner, predisposing, pathophysiology, presentation, diagnostics, management, pivots, schema_version";

  const getRow = async (key: string) => {
    const { data } = await admin.from("illness_scripts").select(SELECT).eq("condition_key", key).maybeSingle();
    return data as Record<string, unknown> | null;
  };
  const bump = (key: string) => admin.rpc("bump_illness_counters", { p_key: key, p_miss: isMiss });
  const learnAlias = (from: string, to: string) =>
    from === to ? Promise.resolve() : admin.from("illness_aliases").upsert({ alias_key: from, condition_key: to }, { onConflict: "alias_key" });

  const client = () => new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY")! });

  const generate = async (text: string, quality: ScriptQuality = "fast"): Promise<IllnessScript & { key: string }> => {
    const s = await generateIllnessScript(client(), text, { resolveTypos: true, quality });
    return { ...s, key: normalizeKey(s.condition || text) || inputKey };
  };

  // Regenerate an existing (stale) row IN PLACE. condition_key is the WHERE
  // clause, not a column we write, so aliases keep pointing at this row.
  // Counters are not in the payload; bump() adds this request on top.
  const upgrade = async (existingKey: string, conditionText: string) => {
    const s = await generate(conditionText);
    const { error } = await admin.from("illness_scripts").update(scriptRowUpdate(s))
      .eq("condition_key", existingKey);
    if (error) throw new Error(error.message);
    await bump(existingKey);
    return json({ ...s, cached: false });
  };

  const serveRow = async (key: string, row: Record<string, unknown>, aliasFrom?: string) => {
    if (aliasFrom) await learnAlias(aliasFrom, key);
    if ((row.schema_version as number ?? 0) >= SCHEMA_VERSION) {
      await bump(key);
      return json({ ...rowToShape(row), cached: true });
    }
    return await upgrade(key, (row.condition as string) ?? key);
  };

  type Hit = { key: string; row: Record<string, unknown>; aliasFrom?: string };

  // Reads only. Side effects stay in serveRow / the async claim path so a
  // fresh hit and a miss keep the same order as the synchronous ladder.
  const resolve = async (): Promise<Hit | null> => {
    const exact = await getRow(inputKey);
    if (exact) return { key: inputKey, row: exact };

    const { data: alias } = await admin.from("illness_aliases").select("condition_key").eq("alias_key", inputKey).maybeSingle();
    if (alias?.condition_key) {
      const row = await getRow(alias.condition_key as string);
      if (row) return { key: alias.condition_key as string, row };
    }

    const { data: fkey } = await admin.rpc("resolve_illness_fuzzy", { q: inputKey, min_sim: FUZZY_MIN_SIMILARITY });
    if (typeof fkey === "string" && fkey) {
      const row = await getRow(fkey);
      if (row) return { key: fkey, row, aliasFrom: inputKey };
    }
    return null;
  };

  if (wantAsync) return await startAsyncBuild();
  return await respondWithHeartbeat(syncWork());

  async function syncWork(): Promise<Response> {
    try {
      const found = await resolve();
      if (found) return await serveRow(found.key, found.row, found.aliasFrom);

      // 4. generate new
      if (!Deno.env.get("ANTHROPIC_API_KEY")) return json({ error: "server_misconfigured" }, 500);
      const s = await generate(condition);

      if (s.key !== inputKey) {
        const canon = await getRow(s.key);
        if (canon) { await learnAlias(inputKey, s.key); return await serveRow(s.key, canon); }
      }

      const { error } = await admin.from("illness_scripts").upsert({
        condition_key: s.key,
        ...scriptRowUpdate(s),
        miss_count: isMiss ? 1 : 0,
        review_count: 1,
      }, { onConflict: "condition_key" });
      if (error) throw new Error(error.message);
      await learnAlias(inputKey, s.key);

      return json({ ...s, cached: false });
    } catch (err) {
      const detail = err instanceof Error ? err.message : String(err);
      return json({ error: "claude_failed", detail }, 502);
    }
  }

  async function startAsyncBuild(): Promise<Response> {
    try {
      const found = await resolve();
      if (found && isFresh(found.row)) {
        return await serveRow(found.key, found.row, found.aliasFrom);
      }
      // Learn the fuzzy alias before returning so a status poll of the typed
      // text resolves to the same condition_key we are building.
      if (found?.aliasFrom) await learnAlias(found.aliasFrom, found.key);

      if (!Deno.env.get("ANTHROPIC_API_KEY")) return json({ error: "server_misconfigured" }, 500);

      const buildKey = found?.key ?? inputKey;
      const display = (found?.row.condition as string | undefined) ?? condition;
      const { data: claimed, error: claimError } = await admin.rpc("claim_illness_script_build", {
        p_key: buildKey,
        p_condition: display,
        p_miss: isMiss,
      });
      if (claimError) return json({ error: "build_queue_unavailable", detail: claimError.message }, 500);

      const token = typeof claimed === "string" && claimed.trim() ? claimed : null;
      if (token) {
        // Resolve the runtime before starting the task so a missing
        // EdgeRuntime cannot leave a build running after we mark it failed.
        let runtime: EdgeRuntimeGlobal;
        try {
          runtime = backgroundRuntime();
        } catch (err) {
          await markBuild(admin, buildKey, token, {
            status: "failed",
            error: publicError(err),
            finished_at: new Date().toISOString(),
          });
          return json({ error: "background_unsupported" }, 500);
        }
        runtime.waitUntil(runBuild({
          admin,
          getRow,
          bump,
          learnAlias,
          generate,
          buildKey,
          token,
          conditionText: display,
          existingKey: found ? found.key : null,
          isMiss,
        }));
      }

      return json({ status: "building", condition_key: buildKey, condition: display }, 202);
    } catch (err) {
      const detail = err instanceof Error ? err.message : String(err);
      return json({ error: "claude_failed", detail }, 502);
    }
  }
});

type Admin = SupabaseClient;

function markBuild(
  admin: Admin,
  key: string,
  token: string,
  patch: Record<string, unknown>,
) {
  return admin.from("illness_script_builds").update({
    ...patch,
    updated_at: new Date().toISOString(),
  }).eq("condition_key", key).eq("build_token", token);
}

async function runBuild(args: {
  admin: Admin;
  getRow: (key: string) => Promise<Record<string, unknown> | null>;
  bump: (key: string) => PromiseLike<unknown>;
  learnAlias: (from: string, to: string) => PromiseLike<unknown>;
  generate: (text: string, quality?: ScriptQuality) => Promise<IllnessScript & { key: string }>;
  buildKey: string;
  token: string;
  conditionText: string;
  existingKey: string | null;
  isMiss: boolean;
}) {
  const { admin, getRow, bump, learnAlias, generate, buildKey, token, conditionText, existingKey, isMiss } = args;
  try {
    const currentKey = existingKey ?? buildKey;
    const current = await getRow(currentKey);
    if (current && isFresh(current)) {
      await markBuild(admin, buildKey, token, {
        status: "done",
        error: null,
        script_key: currentKey,
        condition: (current.condition as string) ?? conditionText,
        finished_at: new Date().toISOString(),
      });
      return;
    }

    console.log(JSON.stringify({ event: "illness_script_build_start", condition_key: buildKey, quality: "full" }));
    const s = await generate(conditionText, "full");
    const scriptKey = await saveScript({
      admin, getRow, bump, learnAlias, script: s, buildKey, existingKey, isMiss,
    });
    await markBuild(admin, buildKey, token, {
      status: "done",
      error: null,
      script_key: scriptKey,
      condition: s.condition || conditionText,
      finished_at: new Date().toISOString(),
    });
    console.log(JSON.stringify({ event: "illness_script_build_done", condition_key: buildKey, script_key: scriptKey }));
  } catch (err) {
    const detail = publicError(err);
    console.error(JSON.stringify({ event: "illness_script_build_failed", condition_key: buildKey, detail }));
    try {
      await markBuild(admin, buildKey, token, {
        status: "failed",
        error: detail,
        finished_at: new Date().toISOString(),
      });
    } catch (markErr) {
      console.error("illness_script_build_mark_failed", markErr);
    }
  }
}

async function saveScript(args: {
  admin: Admin;
  getRow: (key: string) => Promise<Record<string, unknown> | null>;
  bump: (key: string) => PromiseLike<unknown>;
  learnAlias: (from: string, to: string) => PromiseLike<unknown>;
  script: IllnessScript & { key: string };
  buildKey: string;
  existingKey: string | null;
  isMiss: boolean;
}): Promise<string> {
  const { admin, getRow, bump, learnAlias, script, buildKey, existingKey, isMiss } = args;

  const updateInPlace = async (key: string) => {
    const { error } = await admin.from("illness_scripts").update(scriptRowUpdate(script)).eq("condition_key", key);
    if (error) throw new Error(error.message);
    await bump(key);
    await learnAlias(buildKey, key);
    return key;
  };

  // The caller already decided this stored row needs a new script. Keep its
  // condition_key so existing aliases and counters stay put.
  if (existingKey) return await updateInPlace(existingKey);

  if (script.key !== buildKey) {
    const canon = await getRow(script.key);
    if (canon) {
      await learnAlias(buildKey, script.key);
      if (isFresh(canon)) {
        await bump(script.key);
        return script.key;
      }
      return await updateInPlace(script.key);
    }
  }

  const already = await getRow(script.key);
  if (already) return await updateInPlace(script.key);

  const { error } = await admin.from("illness_scripts").upsert({
    condition_key: script.key,
    ...scriptRowUpdate(script),
    miss_count: isMiss ? 1 : 0,
    review_count: 1,
  }, { onConflict: "condition_key" });
  if (error) throw new Error(error.message);
  await learnAlias(buildKey, script.key);
  return script.key;
}

async function readStatus(admin: Admin, raw: string): Promise<Response> {
  const key = normalizeKey(raw);
  if (!key) return json({ error: "missing_condition" }, 400);

  const SELECT = "condition, system, one_liner, predisposing, pathophysiology, presentation, diagnostics, management, pivots, schema_version";
  const getRow = async (rowKey: string) => {
    const { data } = await admin.from("illness_scripts").select(SELECT).eq("condition_key", rowKey).maybeSingle();
    return data as Record<string, unknown> | null;
  };

  // Exact, then alias. No fuzzy match: a status poll must not attach to a
  // neighboring condition. Fresh script wins over a stale build row.
  const exact = await getRow(key);
  if (isFresh(exact)) {
    return json({ status: "done", condition_key: key, ...rowToShape(exact), cached: true });
  }
  const { data: alias } = await admin.from("illness_aliases").select("condition_key").eq("alias_key", key).maybeSingle();
  const aliasKey = (alias?.condition_key as string | undefined) ?? null;
  if (aliasKey) {
    const row = await getRow(aliasKey);
    if (isFresh(row)) {
      return json({ status: "done", condition_key: key, ...rowToShape(row), cached: true });
    }
  }

  const buildKey = (!exact && aliasKey) ? aliasKey : key;
  const { data: build, error } = await admin.from("illness_script_builds")
    .select("condition_key, condition, status, started_at, error, script_key")
    .eq("condition_key", buildKey)
    .maybeSingle();
  if (error) return json({ error: "status_unavailable", detail: error.message }, 500);
  if (!build) return json({ error: "not_found", condition_key: key }, 404);

  const status = build.status as string;
  const condition = (build.condition as string) ?? "";
  if (status === "building") {
    const started = Date.parse(build.started_at as string);
    if (!Number.isFinite(started) || !buildIsInFlight(started, Date.now())) {
      await admin.from("illness_script_builds").update({
        status: "failed",
        error: "timed_out",
        finished_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      }).eq("condition_key", buildKey).eq("status", "building");
      return json({ status: "failed", condition_key: key, condition, error: "timed_out" });
    }
    return json({
      status: "building",
      condition_key: key,
      condition,
      started_at: build.started_at,
    });
  }

  if (status === "done") {
    const scriptKey = (build.script_key as string | null) || buildKey;
    const row = await getRow(scriptKey);
    if (isFresh(row)) {
      return json({ status: "done", condition_key: key, ...rowToShape(row), cached: true });
    }
    return json({ status: "failed", condition_key: key, condition, error: "script_missing" });
  }

  return json({
    status: "failed",
    condition_key: key,
    condition,
    error: (build.error as string | null) ?? "failed",
  });
}
