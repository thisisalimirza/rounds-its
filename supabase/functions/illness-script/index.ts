// Rounds — illness-script edge function
//
// Returns a structured illness script (Demographics / Diagnostics /
// Pathophysiology / Treatment) for a condition. Illness scripts are the same
// for every user, so they're cached GLOBALLY in the illness_scripts table:
// the first user to need a condition triggers one Claude call; everyone after
// gets the stored script for free. Counters track how often each condition is
// missed and reviewed.
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

/** Deterministic cache key so the same condition maps to one stored script. */
function normalizeKey(s: string): string {
  return s
    .toLowerCase()
    .normalize("NFKD").replace(/[̀-ͯ]/g, "")
    .replace(/[^a-z0-9 ]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

const SCRIPT_SCHEMA = {
  type: "object",
  additionalProperties: false,
  properties: {
    condition: { type: "string", description: "The canonical condition name, well-formatted (e.g. 'Spinal epidural abscess')." },
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
  required: ["condition", "oneLiner", "demographics", "diagnostics", "pathophysiology", "treatment"],
};

const SYSTEM_PROMPT = `You are writing a concise, high-yield ILLNESS SCRIPT for a medical student, for a single condition. Output tight, scannable bullets — never paragraphs. Each bullet is a short phrase or single clause (aim under ~15 words) that teaches the actual content a strong clerkship student should hold.

Cover exactly these sections:
- demographics: who gets it most (age, sex, risk factors, classic setting/geography).
- diagnostics: how it's diagnosed — key history/exam findings, first-line tests, and the gold standard.
- pathophysiology: the core mechanism.
- treatment: first-line management and what to order/give, plus disposition when relevant.
Also give a one-line classic presentation.

Be accurate and board-relevant. This is an educational reference, not individualized medical advice. If the input isn't a real/recognized condition, still return your best-effort script for the closest real entity and use the canonical name.`;

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

  const key = normalizeKey(condition);
  if (!key) return json({ error: "missing_condition" }, 400);

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const isMiss = reason === "miss";

  // 1. Cache hit → serve stored script, bump counters, no Claude call.
  const { data: existing } = await admin
    .from("illness_scripts")
    .select("condition, one_liner, demographics, diagnostics, pathophysiology, treatment")
    .eq("condition_key", key)
    .maybeSingle();

  if (existing) {
    await admin.rpc("bump_illness_counters", { p_key: key, p_miss: isMiss });
    return json({
      condition: existing.condition,
      oneLiner: existing.one_liner,
      demographics: existing.demographics ?? [],
      diagnostics: existing.diagnostics ?? [],
      pathophysiology: existing.pathophysiology ?? [],
      treatment: existing.treatment ?? [],
      cached: true,
    });
  }

  // 2. Cache miss → generate once with Claude, store, serve.
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

    // Store for everyone (idempotent on condition_key). Seed counters for this request.
    await admin.from("illness_scripts").upsert({
      condition_key: key,
      condition: script.condition ?? condition,
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

    return json({ ...script, cached: false });
  } catch (err) {
    const detail = err instanceof Error ? err.message : String(err);
    return json({ error: "claude_failed", detail }, 502);
  }
});
