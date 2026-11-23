// Rounds — seed-illness-scripts (one-off admin tool)
//
// Bulk-generates a curated set of high-yield illness scripts (a few per
// specialty) into the global illness_scripts table, using the SAME schema +
// prompt as the on-demand illness-script function. Gated by a shared secret
// (x-seed-secret) instead of a user JWT.
//
// Because generation is slow (draft + one review pass), each call processes a
// small BATCH of the still-missing conditions and reports how many remain —
// call it repeatedly until remaining = 0. Rows below the current schema
// version count as missing and are updated in place: the existing
// condition_key is kept (aliases still resolve) and counters are not reset.
//
// Preview (no database write) — still requires x-seed-secret:
//   curl -s -X POST "$URL/functions/v1/seed-illness-scripts" \
//     -H "x-seed-secret: <SECRET>" -H "content-type: application/json" \
//     -d '{"preview":true,"conditions":["Schizoaffective disorder","Cardiac amyloidosis","Diabetic ketoacidosis","Pulmonary embolism"]}'
// Each name is two model calls. Keep a preview to a few names or the worker
// limit may kill the invocation. At most PREVIEW_LIMIT names per call.
//
// Setup:
//   supabase secrets set SEED_SECRET=<pick-a-long-secret>
//   supabase functions deploy seed-illness-scripts   (verify_jwt=false via config.toml)
// Run (loop until remaining=0):
//   curl -s -X POST "$URL/functions/v1/seed-illness-scripts" -H "x-seed-secret: <SECRET>"

import { createClient } from "jsr:@supabase/supabase-js@2";
import Anthropic from "npm:@anthropic-ai/sdk@0.68.0";
import {
  generateIllnessScript,
  normalizeKey,
  SCHEMA_VERSION,
  scriptRowUpdate,
  type IllnessScript,
} from "../_shared/illness-script-prompt.ts";

const BATCH = 1; // ONE condition per invocation — edge functions can't do more
                 // without hitting WORKER_RESOURCE_LIMIT. The loop calls it repeatedly.
const PREVIEW_LIMIT = 8;

const json = (b: unknown, s = 200) => new Response(JSON.stringify(b), { status: s, headers: { "Content-Type": "application/json" } });

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

async function readJsonBody(req: Request): Promise<Record<string, unknown>> {
  const text = await req.text();
  if (!text.trim()) return {};
  const parsed = JSON.parse(text) as unknown;
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error("invalid_body");
  }
  return parsed as Record<string, unknown>;
}

function previewNames(body: Record<string, unknown>): string[] | null {
  if (!Array.isArray(body.conditions)) return null;
  return body.conditions
    .filter((name): name is string => typeof name === "string")
    .map((name) => name.trim())
    .filter((name) => name.length > 0);
}

Deno.serve(async (req) => {
  if (req.headers.get("x-seed-secret") !== Deno.env.get("SEED_SECRET")) {
    return json({ error: "forbidden" }, 403);
  }

  let body: Record<string, unknown>;
  try {
    body = await readJsonBody(req);
  } catch {
    return json({ error: "invalid_body" }, 400);
  }

  if (body.preview === true) {
    const names = previewNames(body);
    if (!names || names.length === 0) return json({ error: "missing_conditions" }, 400);
    if (names.length > PREVIEW_LIMIT) {
      return json({ error: "too_many_conditions", limit: PREVIEW_LIMIT }, 400);
    }
    const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!apiKey) return json({ error: "server_misconfigured" }, 500);
    const client = new Anthropic({ apiKey });

    const scripts: { requested: string; script: IllnessScript }[] = [];
    const failed: { condition: string; error: string }[] = [];
    for (const condition of names) {
      try {
        const script = await generateIllnessScript(client, condition, { resolveTypos: false });
        scripts.push({ requested: condition, script });
      } catch (err) {
        failed.push({ condition, error: err instanceof Error ? err.message : String(err) });
      }
    }
    return json({ preview: true, schema_version: SCHEMA_VERSION, scripts, failed });
  }

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  // Which conditions are already stored (at the current schema version)?
  // An alias counts too, so a seed name whose canonical key differs does not
  // regenerate on every call once that alias points at a current row.
  const { data: rows, error: readError } = await admin.from("illness_scripts").select("condition_key, schema_version");
  if (readError) return json({ error: "read_failed", detail: readError.message }, 500);
  const { data: aliasRows, error: aliasError } = await admin.from("illness_aliases").select("alias_key, condition_key");
  if (aliasError) return json({ error: "read_failed", detail: aliasError.message }, 500);
  const existing = new Map((rows ?? []).map((r) => [r.condition_key as string, r.schema_version as number | null]));
  const aliasTo = new Map((aliasRows ?? []).map((r) => [r.alias_key as string, r.condition_key as string]));
  const done = new Set(
    [...existing.entries()].filter(([, version]) => (version ?? 0) >= SCHEMA_VERSION).map(([key]) => key),
  );
  const missing = SEED_CONDITIONS.filter((c) => {
    const key = normalizeKey(c);
    if (done.has(key)) return false;
    const target = aliasTo.get(key);
    return !(target && done.has(target));
  });

  const batch = missing.slice(0, BATCH);
  const generated: string[] = [];
  const failed: { condition: string; error: string }[] = [];

  if (batch.length > 0) {
    const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!apiKey) return json({ error: "server_misconfigured" }, 500);
    const client = new Anthropic({ apiKey });

    for (const condition of batch) {
      try {
        const script = await generateIllnessScript(client, condition, { resolveTypos: false });
        const seedKey = normalizeKey(condition);
        const canonKey = normalizeKey(script.condition) || seedKey;
        // Keep an existing condition_key so aliases and counters stay put.
        // Otherwise store under the canonical key and remember the seed name.
        const key = existing.has(seedKey) ? seedKey : canonKey;

        const { error } = await admin.from("illness_scripts").upsert({
          condition_key: key,
          ...scriptRowUpdate(script),
        }, { onConflict: "condition_key" });
        if (error) throw new Error(error.message);
        if (seedKey !== key) {
          const { error: linkError } = await admin.from("illness_aliases").upsert(
            { alias_key: seedKey, condition_key: key },
            { onConflict: "alias_key" },
          );
          if (linkError) throw new Error(linkError.message);
        }
        generated.push(script.condition);
      } catch (err) {
        failed.push({ condition, error: err instanceof Error ? err.message : String(err) });
      }
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
