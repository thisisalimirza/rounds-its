// Rounds — seed-illness-scripts (one-off admin tool)
//
// Bulk-generates a curated set of high-yield illness scripts (a few per
// specialty) into the global illness_scripts table, using the SAME schema +
// prompt as the on-demand illness-script function. Gated by a shared secret
// (x-seed-secret) instead of a user JWT.
//
// Because generation is slow, each call processes a small BATCH of the
// still-missing conditions and reports how many remain — call it repeatedly
// until remaining = 0.
//
// Setup:
//   supabase secrets set SEED_SECRET=<pick-a-long-secret>
//   supabase functions deploy seed-illness-scripts   (verify_jwt=false via config.toml)
// Run (loop until remaining=0):
//   curl -s -X POST "$URL/functions/v1/seed-illness-scripts" -H "x-seed-secret: <SECRET>"

import { createClient } from "jsr:@supabase/supabase-js@2";
import Anthropic from "npm:@anthropic-ai/sdk@0.68.0";

const MODEL = "claude-sonnet-4-6";
const SCHEMA_VERSION = 1;
const BATCH = 1;   // ONE generation per invocation — edge functions can't do more
                   // without hitting WORKER_RESOURCE_LIMIT. The loop calls it repeatedly.

const json = (b: unknown, s = 200) => new Response(JSON.stringify(b), { status: s, headers: { "Content-Type": "application/json" } });

function normalizeKey(s: string): string {
  return s.normalize("NFKD").replace(/\p{Diacritic}/gu, "")
    .toLowerCase().replace(/[^a-z0-9 ]/g, " ").replace(/\s+/g, " ").trim();
}

// A few high-yield, board-relevant conditions per specialty.
const SEED_CONDITIONS: string[] = [
  // Cardiology
  "Myocardial infarction", "Acute decompensated heart failure", "Aortic dissection", "Atrial fibrillation", "Infective endocarditis",
  // Pulmonology
  "Pulmonary embolism", "COPD exacerbation", "Community-acquired pneumonia", "Asthma exacerbation", "Tension pneumothorax",
  // Gastroenterology
  "Acute pancreatitis", "Acute appendicitis", "Acute cholecystitis", "Upper gastrointestinal bleed", "Small bowel obstruction",
  // Nephrology
  "Acute kidney injury", "Nephrotic syndrome", "Hyperkalemia", "Nephrolithiasis",
  // Neurology
  "Ischemic stroke", "Subarachnoid hemorrhage", "Bacterial meningitis", "Guillain-Barré syndrome", "Status epilepticus",
  // Endocrinology
  "Diabetic ketoacidosis", "Thyroid storm", "Adrenal (Addisonian) crisis", "Hyperosmolar hyperglycemic state",
  // Infectious Disease
  "Sepsis", "Cellulitis", "Necrotizing fasciitis", "Osteomyelitis",
  // Hematology & Oncology
  "Iron deficiency anemia", "Sickle cell vaso-occlusive crisis", "Tumor lysis syndrome", "Deep vein thrombosis",
  // Rheumatology
  "Systemic lupus erythematosus", "Gout", "Giant cell arteritis", "Septic arthritis",
  // Psychiatry
  "Major depressive disorder", "Serotonin syndrome", "Neuroleptic malignant syndrome", "Alcohol withdrawal",
  // Obstetrics & Gynecology
  "Preeclampsia with severe features", "Ectopic pregnancy", "Ovarian torsion", "Placental abruption", "Pelvic inflammatory disease",
  // Pediatrics
  "Bronchiolitis", "Kawasaki disease", "Intussusception", "Pyloric stenosis", "Epiglottitis",
  // Emergency / Dermatology
  "Anaphylaxis", "Acute compartment syndrome", "Stevens-Johnson syndrome",
];

const SCRIPT_SCHEMA = {
  type: "object", additionalProperties: false,
  properties: {
    condition: { type: "string", description: "The CANONICAL condition name." },
    system: { type: "string", description: "Primary specialty/system, Title Case (e.g. 'Obstetrics & Gynecology', 'Cardiology')." },
    definition: { type: "string", description: "One-line snapshot (max ~28 words)." },
    predisposing: { type: "array", description: "Epidemiology & predisposing factors. 3-6 short bullets.", items: { type: "string" } },
    pathophysiology: { type: "array", description: "Core mechanism. 2-4 short bullets.", items: { type: "string" } },
    presentation: { type: "array", description: "Classic triad, timeline, pathognomonic signs, key exam. 3-6 short bullets.", items: { type: "string" } },
    diagnostics: { type: "array", description: "First-line test, gold standard, pearl/pitfall. 3-5 short bullets.", items: { type: "string" } },
    management: { type: "array", description: "First-line + definitive treatment, key contraindications/disposition. 3-5 short bullets.", items: { type: "string" } },
    pivots: {
      type: "array", description: "Differential pivot points — closest lookalikes + the sharpest distinguisher. 2-4 items.",
      items: {
        type: "object", additionalProperties: false,
        properties: { condition: { type: "string" }, distinguisher: { type: "string" } },
        required: ["condition", "distinguisher"],
      },
    },
  },
  required: ["condition", "system", "definition", "predisposing", "pathophysiology", "presentation", "diagnostics", "management", "pivots"],
};

const SYSTEM_PROMPT = `You are writing a concise, high-yield, shelf-exam-ready ILLNESS SCRIPT for a medical student, for a single condition.

Output tight, scannable bullets — never paragraphs. Each bullet is a short phrase or single clause (aim under ~18 words) teaching the actual content a strong clerkship student holds. Lock down: definition (one-line snapshot), predisposing (epidemiology + risk factors), pathophysiology (core mechanism), presentation (classic triad, timeline, pathognomonic signs, exam), diagnostics (first-line, gold standard, a pearl), management (first-line + definitive treatment, key contraindications), and pivots (the closest lookalike diagnoses and the SINGLE sharpest distinguishing feature for each — the highest-yield part).

Be accurate and board-relevant. Put the canonical condition name in \`condition\`. This is an educational reference, not individualized medical advice.`;

Deno.serve(async (req) => {
  if (req.headers.get("x-seed-secret") !== Deno.env.get("SEED_SECRET")) {
    return json({ error: "forbidden" }, 403);
  }

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const client = new Anthropic({ apiKey: Deno.env.get("ANTHROPIC_API_KEY")! });

  // Which conditions are already stored (at the current schema version)?
  const { data: rows } = await admin.from("illness_scripts").select("condition_key, schema_version");
  const done = new Set((rows ?? []).filter((r) => (r.schema_version ?? 0) >= SCHEMA_VERSION).map((r) => r.condition_key as string));
  const missing = SEED_CONDITIONS.filter((c) => !done.has(normalizeKey(c)));

  const batch = missing.slice(0, BATCH);
  const generated: string[] = [];
  const failed: { condition: string; error: string }[] = [];

  for (const condition of batch) {
    try {
      const stream = client.messages.stream({
        model: MODEL,
        max_tokens: 6000,
        thinking: { type: "adaptive" },
        system: [{ type: "text", text: SYSTEM_PROMPT, cache_control: { type: "ephemeral" } }],
        output_config: { format: { type: "json_schema", schema: SCRIPT_SCHEMA } },
        messages: [{ role: "user", content: `Write the illness script for: ${condition}` }],
      } as Anthropic.MessageStreamParams);
      const message = await stream.finalMessage();
      const block = message.content.find((b) => b.type === "text");
      if (!block || block.type !== "text") throw new Error("no_output");
      const s = JSON.parse(block.text);
      const key = normalizeKey(s.condition || condition);

      await admin.from("illness_scripts").upsert({
        condition_key: key, condition: s.condition, system: s.system, one_liner: s.definition,
        predisposing: s.predisposing, pathophysiology: s.pathophysiology, presentation: s.presentation,
        diagnostics: s.diagnostics, management: s.management, pivots: s.pivots,
        schema_version: SCHEMA_VERSION, model: MODEL, updated_at: new Date().toISOString(),
      }, { onConflict: "condition_key" });
      generated.push(s.condition);
    } catch (err) {
      failed.push({ condition, error: err instanceof Error ? err.message : String(err) });
    }
  }

  return json({
    generated,
    failed,
    processed: batch.length,
    remaining: Math.max(0, missing.length - batch.length),
    total: SEED_CONDITIONS.length,
    already_done: done.size,
  });
});
