// Rounds — study-plan edge function
//
// Takes a summary of the student's weak spots (what they got wrong, and which
// presentations they practiced) and asks Claude for a targeted, teaching-rich
// study plan: prioritized focus areas, why each is a gap, what to study, and
// the actual high-yield knowledge for each area.
//
// The Anthropic API key lives ONLY here as a Supabase secret (ANTHROPIC_API_KEY)
// — never shipped in the app. Gated to signed-in users like the other funcs.
//
// Deploy:  supabase functions deploy study-plan

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

// Tight, componentized schema — every field maps to a small UI element, so the
// app never renders a wall of text. Each bullet is a SHORT phrase / one line.
const PLAN_SCHEMA = {
  type: "object",
  additionalProperties: false,
  properties: {
    headline: {
      type: "string",
      description: "One short, punchy sentence (max ~18 words) summarizing the student's single biggest focus right now.",
    },
    focusAreas: {
      type: "array",
      description: "Prioritized focus areas, most important first. 2-5 areas.",
      items: {
        type: "object",
        additionalProperties: false,
        properties: {
          area: { type: "string", description: "Short title of the area (e.g. 'Acute low back pain', 'Cardiology'). Max ~6 words." },
          priority: { type: "string", enum: ["high", "medium", "low"] },
          summary: { type: "string", description: "ONE short sentence (max ~20 words) on why this is a gap for this student." },
          keyFacts: {
            type: "array",
            description: "3-6 high-yield facts to KNOW. Each is a short phrase or single clause (max ~15 words) — teach the actual content, not a pointer to go read it.",
            items: { type: "string" },
          },
          cantMiss: {
            type: "array",
            description: "Can't-miss diagnoses / red flags for this area. Each a short phrase (max ~12 words). Empty array if not applicable.",
            items: { type: "string" },
          },
          review: {
            type: "array",
            description: "2-4 concrete things to study/review. Each a short phrase (max ~12 words).",
            items: { type: "string" },
          },
        },
        required: ["area", "priority", "summary", "keyFacts", "cantMiss", "review"],
      },
    },
  },
  required: ["headline", "focusAreas"],
};

const SYSTEM_PROMPT = `You are a clinical reasoning coach for a medical student using the Rounds app. You receive a structured summary of the student's weak spots: what they got wrong (topic, count, which activity) and the presentations they practiced.

Produce a TIGHT, scannable study plan that the app renders as small UI components. Rules:
- Group related misses into 2-5 coherent focus areas, prioritized (most important first).
- Write in SHORT bullets, never paragraphs. Every keyFact / cantMiss / review item is a short phrase or single clause — aim for under ~15 words each. The headline and each area summary are ONE short sentence.
- keyFacts must TEACH the actual high-yield content (discriminating features, mechanisms, numbers a strong clerkship student holds) — not "review X". Deliver the knowledge concisely.
- cantMiss lists the dangerous diagnoses / red flags for that area.
- review lists concrete things to study.
- Be specific to the data provided, not generic. With little data, focus tightly on what's there.

This is an educational study aid and does not replace formal curriculum or supervision.`;

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

  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) return json({ error: "server_misconfigured", detail: "ANTHROPIC_API_KEY not set" }, 500);

  let weakSpots: unknown = [];
  let practiced: unknown = [];
  try {
    const body = await req.json();
    weakSpots = body?.weakSpots ?? [];
    practiced = body?.practiced ?? [];
  } catch { /* empty body */ }

  const summary = JSON.stringify({ weakSpots, practiced }, null, 2);
  const userText = `Here is the student's weak-spot data:\n\n${summary}\n\nBuild their targeted study plan.`;

  const client = new Anthropic({ apiKey });

  try {
    const stream = client.messages.stream({
      model: "claude-opus-4-8",
      max_tokens: 8000,
      thinking: { type: "adaptive" },
      system: [
        { type: "text", text: SYSTEM_PROMPT, cache_control: { type: "ephemeral" } },
      ],
      output_config: { format: { type: "json_schema", schema: PLAN_SCHEMA } },
      messages: [{ role: "user", content: userText }],
    } as Anthropic.MessageStreamParams);

    const message = await stream.finalMessage();

    if (message.stop_reason === "refusal") {
      return json({ error: "refused", detail: "The request was declined." }, 422);
    }
    const textBlock = message.content.find((b) => b.type === "text");
    if (!textBlock || textBlock.type !== "text") {
      return json({ error: "no_output" }, 502);
    }
    return json(JSON.parse(textBlock.text));
  } catch (err) {
    const detail = err instanceof Error ? err.message : String(err);
    return json({ error: "claude_failed", detail }, 502);
  }
});
