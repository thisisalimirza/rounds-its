// Rounds — illness-script edge function
//
// Returns a rich, shelf-ready ILLNESS SCRIPT for a condition, cached globally.
//
// Resolution ladder (cheap → expensive) so typos & synonyms cost no API call:
//   1. Exact normalized key hit                → serve stored script.
//   2. Known alias hit                         → resolve → serve stored script.
//   3. Fuzzy (pg_trgm) match above threshold   → learn alias → serve stored.
//   4. Miss → ONE Claude call returning the CANONICAL name + script.
// Stored scripts below the current schema version auto-regenerate on open.
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

const SCHEMA_VERSION = 1;               // bump to force auto-regeneration
const FUZZY_MIN_SIMILARITY = 0.6;

function normalizeKey(s: string): string {
  return s
    .normalize("NFKD").replace(/\p{Diacritic}/gu, "")
    .toLowerCase().replace(/[^a-z0-9 ]/g, " ").replace(/\s+/g, " ").trim();
}

const SCRIPT_SCHEMA = {
  type: "object",
  additionalProperties: false,
  properties: {
    condition: { type: "string", description: "The CANONICAL condition name. Resolve typos/abbreviations/synonyms to the standard name (e.g. 'Ovarian torsion')." },
    system: { type: "string", description: "Primary specialty/system, Title Case (e.g. 'Obstetrics & Gynecology', 'Cardiology', 'Neurology', 'Gastroenterology', 'Infectious Disease')." },
    definition: { type: "string", description: "One-line definition / classic snapshot of the condition (max ~28 words)." },
    predisposing: {
      type: "array",
      description: "Epidemiology & predisposing factors — who gets it (age, sex, risk factors, exposures). 3-6 short bullets.",
      items: { type: "string" },
    },
    pathophysiology: {
      type: "array",
      description: "The core mechanism — why it happens. 2-4 short bullets.",
      items: { type: "string" },
    },
    presentation: {
      type: "array",
      description: "Clinical presentation — classic triad, timeline/onset, pathognomonic signs, key exam findings. 3-6 short bullets.",
      items: { type: "string" },
    },
    diagnostics: {
      type: "array",
      description: "Work-up — first-line test, gold standard, and key pearls/pitfalls. 3-5 short bullets.",
      items: { type: "string" },
    },
    management: {
      type: "array",
      description: "Management — first-line treatment, definitive treatment, and key contraindications/disposition. 3-5 short bullets.",
      items: { type: "string" },
    },
    pivots: {
      type: "array",
      description: "Differential PIVOT POINTS — the closest lookalikes and the single sharpest feature that distinguishes THIS condition from each. 2-4 items.",
      items: {
        type: "object",
        additionalProperties: false,
        properties: {
          condition: { type: "string", description: "The competing/lookalike diagnosis." },
          distinguisher: { type: "string", description: "The sharp discriminating feature (one short sentence)." },
        },
        required: ["condition", "distinguisher"],
      },
    },
  },
  required: ["condition", "system", "definition", "predisposing", "pathophysiology", "presentation", "diagnostics", "management", "pivots"],
};

const SYSTEM_PROMPT = `You are writing a concise, high-yield, shelf-exam-ready ILLNESS SCRIPT for a medical student, for a single condition.

The user's input may be misspelled, abbreviated, or a synonym (e.g. "heart attack", "MI", "ovarian torsion"). Always resolve it to the correct CANONICAL condition and put the standard name in \`condition\`.

Output tight, scannable bullets — never paragraphs. Each bullet is a short phrase or single clause (aim under ~18 words) teaching the actual content a strong clerkship student holds. Lock down these dimensions:
- definition: one-line snapshot of what the condition is.
- predisposing: epidemiology + predisposing/risk factors (who gets it).
- pathophysiology: the core mechanism (why it happens).
- presentation: classic triad, timeline/onset, pathognomonic signs, key exam findings.
- diagnostics: first-line test, gold standard, and a clinical pearl/pitfall.
- management: first-line and definitive treatment, plus key contraindications/disposition.
- pivots: the closest lookalike diagnoses and the SINGLE sharpest feature that distinguishes this condition from each (this is the highest-yield part — think like a vignette).

Be accurate and board-relevant. This is an educational reference, not individualized medical advice.`;

// A response payload from either a stored row or a freshly generated script.
type ScriptShape = {
  condition: string; system: string; definition: string;
  predisposing: string[]; pathophysiology: string[]; presentation: string[];
  diagnostics: string[]; management: string[];
  pivots: { condition: string; distinguisher: string }[];
};

function rowToShape(row: Record<string, unknown>): ScriptShape {
  return {
    condition: (row.condition as string) ?? "",
    system: (row.system as string) ?? "",
    definition: (row.one_liner as string) ?? "",
    predisposing: (row.predisposing as string[]) ?? [],
    pathophysiology: (row.pathophysiology as string[]) ?? [],
    presentation: (row.presentation as string[]) ?? [],
    diagnostics: (row.diagnostics as string[]) ?? [],
    management: (row.management as string[]) ?? [],
    pivots: (row.pivots as { condition: string; distinguisher: string }[]) ?? [],
  };
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

  const generate = async (text: string): Promise<ScriptShape & { key: string }> => {
    const stream = client().messages.stream({
      model: "claude-sonnet-4-6",
      max_tokens: 6000,
      thinking: { type: "adaptive" },
      system: [{ type: "text", text: SYSTEM_PROMPT, cache_control: { type: "ephemeral" } }],
      output_config: { format: { type: "json_schema", schema: SCRIPT_SCHEMA } },
      messages: [{ role: "user", content: `Write the illness script for: ${text}` }],
    } as Anthropic.MessageStreamParams);
    const message = await stream.finalMessage();
    const block = message.content.find((b) => b.type === "text");
    if (!block || block.type !== "text") throw new Error("no_output");
    const s = JSON.parse(block.text) as ScriptShape;
    return { ...s, key: normalizeKey(s.condition || text) || inputKey };
  };

  // Regenerate an existing (stale) row IN PLACE, preserving its counters.
  const upgrade = async (existingKey: string, conditionText: string) => {
    const s = await generate(conditionText);
    await admin.from("illness_scripts").update({
      condition: s.condition, system: s.system, one_liner: s.definition,
      predisposing: s.predisposing, pathophysiology: s.pathophysiology, presentation: s.presentation,
      diagnostics: s.diagnostics, management: s.management, pivots: s.pivots,
      schema_version: SCHEMA_VERSION, model: "claude-sonnet-4-6", updated_at: new Date().toISOString(),
    }).eq("condition_key", existingKey);
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

    await admin.from("illness_scripts").upsert({
      condition_key: s.key, condition: s.condition, system: s.system, one_liner: s.definition,
      predisposing: s.predisposing, pathophysiology: s.pathophysiology, presentation: s.presentation,
      diagnostics: s.diagnostics, management: s.management, pivots: s.pivots,
      miss_count: isMiss ? 1 : 0, review_count: 1, schema_version: SCHEMA_VERSION,
      model: "claude-sonnet-4-6", updated_at: new Date().toISOString(),
    }, { onConflict: "condition_key" });
    await learnAlias(inputKey, s.key);

    return json({ ...s, cached: false });
  } catch (err) {
    const detail = err instanceof Error ? err.message : String(err);
    return json({ error: "claude_failed", detail }, 502);
  }
});
