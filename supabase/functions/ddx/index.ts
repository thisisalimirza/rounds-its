// Rounds — ddx edge function
//
// Takes free-text clinical findings (what a student saw on a patient) and asks
// Claude for a structured differential diagnosis: for each dx, the features that
// support it, the features that argue against it, and the recommended next
// steps / workup to narrow it down.
//
// The Anthropic API key lives ONLY here as a Supabase secret — it is never
// shipped in the app (a key in the client binary is trivially extractable).
// The iOS app posts free text through supabase.functions.invoke("ddx") on its
// authenticated client, exactly like redeem-code / my-status.
//
// Deploy:  supabase functions deploy ddx
// Secrets (supabase secrets set ...):
//   ANTHROPIC_API_KEY   your Anthropic API key (sk-ant-...)  NEVER ship in the app
// SUPABASE_URL and SUPABASE_ANON_KEY are injected automatically.

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

// The model is asked to fill exactly this shape. Structured outputs guarantee
// the response is valid JSON matching it — no brittle parsing on the client.
// (JSON Schema for structured outputs: every object needs additionalProperties
// false; no min/max/length constraints.)
const DDX_SCHEMA = {
  type: "object",
  additionalProperties: false,
  properties: {
    summary: {
      type: "string",
      description: "One short sentence reframing the presentation as a clinician would (a one-line summary).",
    },
    chiefComplaint: {
      type: "string",
      description: "A concise 2-4 word label for the presenting problem being worked up (e.g. 'Acute chest pain', 'Painless jaundice'). Used to track which presentations the student practices.",
    },
    system: {
      type: "string",
      description: "The single primary clinical category/system for this presentation, Title Case (e.g. 'Cardiovascular', 'Gastrointestinal', 'Neurologic', 'Respiratory'). Used to group study topics.",
    },
    differential: {
      type: "array",
      description: "Ranked differential, most likely / most important first. Always include dangerous 'can't-miss' causes even if less likely.",
      items: {
        type: "object",
        additionalProperties: false,
        properties: {
          diagnosis: { type: "string" },
          likelihood: {
            type: "string",
            enum: ["high", "moderate", "low"],
            description: "How likely this dx is given the findings provided.",
          },
          cantMiss: {
            type: "boolean",
            description: "True if this is a dangerous / can't-miss diagnosis that must be actively excluded.",
          },
          supporting: {
            type: "array",
            description: "Findings the student actually mentioned that point toward this diagnosis (pertinent positives). Each item is a short phrase (a few words), not a full sentence. Reference the student's own findings.",
            items: { type: "string" },
          },
          toConfirm: {
            type: "array",
            description: "The concrete next steps to move forward with THIS diagnosis: the additional history, exam findings, labs, or imaging that would raise suspicion or confirm it. Each item is a short, actionable phrase (a few words), highest-yield first.",
            items: { type: "string" },
          },
          rationale: {
            type: "string",
            description: "One brief, teaching-oriented sentence on why this is on the differential.",
          },
        },
        required: ["diagnosis", "likelihood", "cantMiss", "supporting", "toConfirm", "rationale"],
      },
    },
    redFlags: {
      type: "array",
      description: "Red-flag features to watch for that would demand urgent escalation. Each is a short phrase. Empty array if none apply.",
      items: { type: "string" },
    },
  },
  required: ["summary", "chiefComplaint", "system", "differential", "redFlags"],
};

// Stable system prompt → marked cacheable. Kept first so the cached prefix is
// reused across requests (prompt caching activates once the prefix crosses the
// model's minimum-cacheable size; the breakpoint is correct regardless).
const SYSTEM_PROMPT = `You are a clinical reasoning tutor for medical students using the Rounds app. A student has just seen a patient and will describe, in free text, the symptoms, signs, and findings they gathered. Your job is to model how an experienced clinician builds a differential diagnosis from that presentation.

For the findings given:
- Produce a focused, prioritized differential (aim for 4-6 diagnoses). Order it by a combination of likelihood and clinical importance — most likely first, but ALWAYS surface dangerous "can't-miss" diagnoses (mark cantMiss: true) even when they are less likely, because ruling them out is the point of a good differential.
- For each diagnosis, list in "supporting" the specific findings the STUDENT ACTUALLY MENTIONED that point toward it (pertinent positives), phrased as short phrases of a few words that map to what they said.
- For each diagnosis, list in "toConfirm" the concrete next steps to move forward with it: the additional history, exam findings, labs, or imaging that would most raise suspicion or confirm this specific diagnosis. Short, actionable phrases, highest-yield first. This is how the student advances the workup for the diagnosis they suspect.
- Give one brief, teaching-oriented sentence of rationale for each.
- Note any red-flag features that would demand urgent escalation.
- Also label the presentation itself: a concise chiefComplaint (2-4 words) and its primary clinical system (Title Case). These are used to track which topics the student is practicing.

Keep every list item short (a few words), not full sentences — the app renders them as compact bullet points. Reason carefully and be specific to the findings provided rather than generic. If the input is too vague to build a meaningful differential, still return your best structured attempt and use the summary to say what additional information is most needed.

This is an educational study aid, not a diagnostic device, and it does not replace clinical judgment or supervision. Do not address the patient; address the student's learning.`;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  // Identify the caller from their JWT (functions verify_jwt by default). This
  // gates the endpoint to signed-in app users and gives us a user id to
  // attribute / rate-limit usage against later.
  const authHeader = req.headers.get("Authorization") ?? "";
  const anon = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user }, error: userErr } = await anon.auth.getUser();
  if (userErr || !user) return json({ error: "not_authenticated" }, 401);

  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) return json({ error: "server_misconfigured", detail: "ANTHROPIC_API_KEY not set" }, 500);

  let findings = "";
  let context = "";
  try {
    const body = await req.json();
    findings = (body?.findings ?? "").toString().trim();
    context = (body?.context ?? "").toString().trim();
  } catch { /* empty / invalid body */ }
  if (!findings) return json({ error: "missing_findings" }, 400);

  // Volatile, per-request content goes AFTER the cached system prefix.
  const userText = context
    ? `Patient context: ${context}\n\nFindings the student gathered:\n${findings}`
    : `Findings the student gathered:\n${findings}`;

  const client = new Anthropic({ apiKey });

  try {
    // Stream internally (adaptive thinking can produce a long response) and
    // collect the final message, then hand the app a single JSON payload.
    // Structured outputs (output_config.format) guarantees the text block is
    // valid JSON matching DDX_SCHEMA.
    const stream = client.messages.stream({
      model: "claude-opus-4-8",
      max_tokens: 8000,
      thinking: { type: "adaptive" },
      system: [
        { type: "text", text: SYSTEM_PROMPT, cache_control: { type: "ephemeral" } },
      ],
      output_config: { format: { type: "json_schema", schema: DDX_SCHEMA } },
      messages: [{ role: "user", content: userText }],
    } as Anthropic.MessageStreamParams);

    const message = await stream.finalMessage();

    if (message.stop_reason === "refusal") {
      return json({ error: "refused", detail: "The request was declined." }, 422);
    }

    const textBlock = message.content.find((b) => b.type === "text");
    if (!textBlock || textBlock.type !== "text") {
      return json({ error: "no_output", detail: "Model returned no text block." }, 502);
    }

    // Parse to validate it's well-formed before returning, then pass through.
    const parsed = JSON.parse(textBlock.text);
    return json(parsed);
  } catch (err) {
    const detail = err instanceof Error ? err.message : String(err);
    return json({ error: "claude_failed", detail }, 502);
  }
});
