// Rounds — illness-script edge function
//
// Returns a structured illness script (Demographics / Diagnostics /
// Pathophysiology / Treatment) for a condition. Illness scripts are the same
// for every user, so they're cached GLOBALLY in the illness_scripts table.
//
// Resolution ladder (cheap → expensive) so typos & synonyms cost no API call:
//   1. Exact normalized key hit                → serve stored script.
//   2. Known alias hit                         → resolve → serve stored script.
//   3. Fuzzy (pg_trgm) match above threshold   → learn alias → serve stored.
//   4. Miss → ONE Claude call that returns the CANONICAL name + script:
//        a. canonical already stored → learn alias, discard dup, serve stored.
//        b. new → store under canonical key, learn alias, serve.
//
// The Anthropic API key lives ONLY here as a Supabase secret (ANTHROPIC_API_KEY).
//
// Deploy:  supabase functions deploy illness-script

import { createClient } from "jsr:@supabase/supabase-js@2";
import Anthropic from "npm:@anthropic-ai/sdk@0.68.0";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

const FUZZY_MIN_SIMILARITY = 0.6; // conservative: only very-close typos auto-resolve

/** Deterministic cache key so the same condition maps to one stored script. */
function normalizeKey(s: string): string {
  return s
    .normalize("NFKD")
    .replace(/\p{Diacritic}/gu, "")
    .toLowerCase()
    .replace(/[^a-z0-9 ]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

const SCRIPT_SCHEMA = {
  type: "object",
  additionalProperties: false,
  properties: {
    condition: { type: "string", description: "The CANONICAL condition name, well-formatted (e.g. 'Myocardial infarction'). Resolve typos/abbreviations/synonyms to the standard name." },
    system: { type: "string", description: "The single primary specialty/system, Title Case (e.g. 'Gastroenterology', 'Cardiology', 'Neurology', 'Infectious Disease'). Used to organize the library." },
    oneLiner: { type: "string", description: "One short sentence: the classic presentation / illness-script summary (max ~25 words)." },
    demographics: {
      type: "array",
      description: "Who gets it most (age, sex, risk factors, settings). 3-5 short bullets, each a phrase (max ~15 words).",
      items: { type: "string" },
    },
    diagnostics: {
      type: "array",
      description: "How it's diagnosed: key history/exam findings, first-line labs/imaging, gold standard. 3-6 short bullets.",
      items: { type: "string" },
    },
    pathophysiology: {
      type: "array",
      description: "What's going on mechanistically, at a level a strong clerkship student should hold. 3-5 short bullets.",
      items: { type: "string" },
    },
    treatment: {
      type: "array",
      description: "How it's treated / what to order: first-line management, key drugs/doses when high-yield, disposition. 3-6 short bullets.",
      items: { type: "string" },
    },
  },
  required: ["condition", "system", "oneLiner", "demographics", "diagnostics", "pathophysiology", "treatment"],
};

const SYSTEM_PROMPT = `You are writing a concise, high-yield ILLNESS SCRIPT for a medical student, for a single condition.

The user's input may be misspelled, abbreviated, or a synonym (e.g. "heart attack", "MI", "myocardial infraction"). Always resolve it to the correct CANONICAL condition and put the standard name in \`condition\`. If the input is genuinely ambiguous or not a real entity, choose the single most likely intended real condition.

Output tight, scannable bullets — never paragraphs. Each bullet is a short phrase or single clause (aim under ~15 words) that teaches the actual content a strong clerkship student should hold.

Cover exactly these sections:
- demographics: who gets it most (age, sex, risk factors, classic setting/geography).
- diagnostics: how it's diagnosed — key history/exam findings, first-line tests, and the gold standard.
- pathophysiology: the core mechanism.
- treatment: first-line management and what to order/give, plus disposition when relevant.
Also give a one-line classic presentation and the primary specialty/system.

Be accurate and board-relevant. This is an educational reference, not individualized medical advice.`;

function scriptResponse(row: {
  condition: string;
  system?: string | null;
  one_liner?: string | null;
  demographics?: string[] | null;
  diagnostics?: string[] | null;
  pathophysiology?: string[] | null;
  treatment?: string[] | null;
}, cached: boolean) {
  return json({
    condition: row.condition,
    system: row.system ?? "",
    oneLiner: row.one_liner ?? "",
    demographics: row.demographics ?? [],
    diagnostics: row.diagnostics ?? [],
    pathophysiology: row.pathophysiology ?? [],
    treatment: row.treatment ?? [],
    cached,
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const authHeader = req.headers.get("Authorization") ?? "";
  const anon = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
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
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const isMiss = reason === "miss";

  const SELECT = "condition, system, one_liner, demographics, diagnostics, pathophysiology, treatment";

  const serveByKey = async (key: string, learnAliasFrom?: string) => {
    const { data: row } = await admin.from("illness_scripts").select(SELECT).eq("condition_key", key).maybeSingle();
    if (!row) return null;
    await admin.rpc("bump_illness_counters", { p_key: key, p_miss: isMiss });
    if (learnAliasFrom && learnAliasFrom !== key) {
      await admin.from("illness_aliases").upsert({ alias_key: learnAliasFrom, condition_key: key }, { onConflict: "alias_key" });
    }
    return scriptResponse(row, true);
  };

  // 1. Exact hit.
  const exact = await serveByKey(inputKey);
  if (exact) return exact;

  // 2. Known alias hit.
  const { data: alias } = await admin.from("illness_aliases").select("condition_key").eq("alias_key", inputKey).maybeSingle();
  if (alias?.condition_key) {
    const viaAlias = await serveByKey(alias.condition_key);
    if (viaAlias) return viaAlias;
  }

  // 3. Fuzzy match (typo tolerance) — learn the alias if resolved.
  const { data: fuzzyKey } = await admin.rpc("resolve_illness_fuzzy", { q: inputKey, min_sim: FUZZY_MIN_SIMILARITY });
  if (typeof fuzzyKey === "string" && fuzzyKey) {
    const viaFuzzy = await serveByKey(fuzzyKey, inputKey);
    if (viaFuzzy) return viaFuzzy;
  }

  // 4. Generate once with Claude (also canonicalizes typos/synonyms).
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) return json({ error: "server_misconfigured", detail: "ANTHROPIC_API_KEY not set" }, 500);
  const client = new Anthropic({ apiKey });

  try {
    const stream = client.messages.stream({
      model: "claude-opus-4-8",
      max_tokens: 6000,
      thinking: { type: "adaptive" },
      system: [{ type: "text", text: SYSTEM_PROMPT, cache_control: { type: "ephemeral" } }],
      output_config: { format: { type: "json_schema", schema: SCRIPT_SCHEMA } },
      messages: [{ role: "user", content: `Write the illness script for: ${condition}` }],
    } as Anthropic.MessageStreamParams);

    const message = await stream.finalMessage();
    if (message.stop_reason === "refusal") return json({ error: "refused" }, 422);
    const textBlock = message.content.find((b) => b.type === "text");
    if (!textBlock || textBlock.type !== "text") return json({ error: "no_output" }, 502);

    const script = JSON.parse(textBlock.text);
    const canonicalKey = normalizeKey(script.condition ?? condition) || inputKey;

    // 4a. Claude canonicalized to something we already have → dedupe + learn alias.
    if (canonicalKey !== inputKey) {
      const dedup = await serveByKey(canonicalKey, inputKey);
      if (dedup) return dedup;
    }

    // 4b. New condition → store under canonical key, learn the input alias.
    await admin.from("illness_scripts").upsert({
      condition_key: canonicalKey,
      condition: script.condition ?? condition,
      system: script.system ?? null,
      one_liner: script.oneLiner ?? "",
      demographics: script.demographics ?? [],
      diagnostics: script.diagnostics ?? [],
      pathophysiology: script.pathophysiology ?? [],
      treatment: script.treatment ?? [],
      miss_count: isMiss ? 1 : 0,
      review_count: 1,
      model: "claude-opus-4-8",
      updated_at: new Date().toISOString(),
    }, { onConflict: "condition_key" });

    if (canonicalKey !== inputKey) {
      await admin.from("illness_aliases").upsert({ alias_key: inputKey, condition_key: canonicalKey }, { onConflict: "alias_key" });
    }

    return json({
      condition: script.condition ?? condition,
      system: script.system ?? "",
      oneLiner: script.oneLiner ?? "",
      demographics: script.demographics ?? [],
      diagnostics: script.diagnostics ?? [],
      pathophysiology: script.pathophysiology ?? [],
      treatment: script.treatment ?? [],
      cached: false,
    });
  } catch (err) {
    const detail = err instanceof Error ? err.message : String(err);
    return json({ error: "claude_failed", detail }, 502);
  }
});
