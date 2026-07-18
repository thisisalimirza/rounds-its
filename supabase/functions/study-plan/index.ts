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

const PLAN_SCHEMA = {
  type: "object",
  additionalProperties: false,
  properties: {
    overview: {
      type: "string",
      description: "Two or three sentences summarizing the student's biggest gaps and the through-line across them.",
    },
    focusAreas: {
      type: "array",
      description: "Prioritized focus areas, most important first. 3-6 areas.",
      items: {
        type: "object",
        additionalProperties: false,
        properties: {
          area: { type: "string", description: "The topic / system / theme (e.g. 'Acute abdominal pain', 'Cardiology')." },
          priority: { type: "string", enum: ["high", "medium", "low"] },
          why: { type: "string", description: "One or two sentences on why this is a gap for THIS student, referencing what they missed." },
          studyPoints: {
            type: "array",
            description: "3-6 specific, high-yield things to study or review for this area.",
            items: { type: "string" },
          },
          teaching: {
            type: "string",
            description: "A compact, high-yield teaching block that actually delivers the core knowledge for this area — the discriminating features, can't-miss diagnoses, and the reasoning a strong student should hold. A few sentences to a short paragraph.",
          },
        },
        required: ["area", "priority", "why", "studyPoints", "teaching"],
      },
    },
    nextSteps: {
      type: "array",
      description: "A short ordered checklist of concrete next actions this week.",
      items: { type: "string" },
    },
  },
  required: ["overview", "focusAreas", "nextSteps"],
};

const SYSTEM_PROMPT = `You are a clinical reasoning coach for a medical student using the Rounds app. You will receive a structured summary of the student's weak spots: the specific things they got wrong (with the topic, how many times, and which activity it came from) and the presentations they practiced building a differential for.

Produce a focused, genuinely useful study plan:
- Identify the highest-leverage focus areas, prioritized. Group related misses into coherent themes rather than repeating every single item.
- For each area, explain briefly why it's a gap for THIS student, referencing what they actually missed.
- Give specific, high-yield study points — what to review, in concrete terms.
- Most importantly, TEACH: include a compact, high-yield knowledge block for each area that delivers the core content a strong clerkship student should hold — discriminating features, can't-miss diagnoses, and the clinical reasoning. This should be substantive enough to actually learn from, not just a pointer to go read elsewhere.
- End with a short, concrete checklist of next steps for the week.

Be specific to the data provided, not generic. Calibrate depth to how much data there is: with little data, focus on what's there and note that recommendations will sharpen as they do more cases. This is an educational study aid and does not replace formal curriculum or supervision.`;

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
