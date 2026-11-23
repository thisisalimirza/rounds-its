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
// Deploy (manual):  supabase functions deploy illness-script

import { createClient } from "jsr:@supabase/supabase-js@2";
import Anthropic from "npm:@anthropic-ai/sdk@0.68.0";
import {
  generateIllnessScript,
  normalizeKey,
  SCHEMA_VERSION,
  scriptRowUpdate,
  type IllnessScript,
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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const authHeader = req.headers.get("Authorization") ?? "";
  const anon = createClient(
    Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user }, error: userErr } = await anon.auth.getUser();
  if (userErr || !user) return json({ error: "not_authenticated" }, 401);

  let condition = "";
  let reason = "review";
  try {
    const body = await req.json();
    condition = (body?.condition ?? "").toString().trim();
    reason = (body?.reason ?? "review").toString();
  } catch { /* empty body */ }
  if (!condition) return json({ error: "missing_condition" }, 400);

  const inputKey = normalizeKey(condition);
  if (!inputKey) return json({ error: "missing_condition" }, 400);

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
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

  const generate = async (text: string): Promise<IllnessScript & { key: string }> => {
    const s = await generateIllnessScript(client(), text, { resolveTypos: true });
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

  const work = async (): Promise<Response> => {
  try {
    // 1. exact
    const exact = await getRow(inputKey);
    if (exact) return await serveRow(inputKey, exact);

    // 2. alias
    const { data: alias } = await admin.from("illness_aliases").select("condition_key").eq("alias_key", inputKey).maybeSingle();
    if (alias?.condition_key) {
      const row = await getRow(alias.condition_key as string);
      if (row) return await serveRow(alias.condition_key as string, row);
    }

    // 3. fuzzy
    const { data: fkey } = await admin.rpc("resolve_illness_fuzzy", { q: inputKey, min_sim: FUZZY_MIN_SIMILARITY });
    if (typeof fkey === "string" && fkey) {
      const row = await getRow(fkey);
      if (row) return await serveRow(fkey, row, inputKey);
    }

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
  };

  return await respondWithHeartbeat(work());
});
