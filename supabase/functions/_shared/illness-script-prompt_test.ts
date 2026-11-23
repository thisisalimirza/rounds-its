import {
  FULL_EFFORT,
  FULL_MAX_TOKENS,
  MODEL,
  REVIEW_TASK,
  SCHEMA_VERSION,
  SCRIPT_SCHEMA,
  SHARED_RULES,
  TYPO_RESOLUTION_PARAGRAPH,
  WRITE_TASK,
  generationProfile,
  normalizeKey,
  scriptRowUpdate,
  systemBlocks,
  type IllnessScript,
} from "./illness-script-prompt.ts";

function assert(cond: unknown, msg = "assertion failed"): asserts cond {
  if (!cond) throw new Error(msg);
}

function assertEquals(actual: unknown, expected: unknown, msg?: string) {
  const a = JSON.stringify(actual);
  const e = JSON.stringify(expected);
  if (a !== e) throw new Error(msg ?? `expected ${e} got ${a}`);
}

Deno.test("schema stays string bullets at version 2", () => {
  assertEquals(SCHEMA_VERSION, 2);
  assertEquals(MODEL, "claude-sonnet-4-6");
  const props = SCRIPT_SCHEMA.properties as Record<string, { type?: string; items?: { type?: string } }>;
  for (const field of ["predisposing", "pathophysiology", "presentation", "diagnostics", "management"]) {
    assertEquals(props[field].type, "array", field);
    assertEquals(props[field].items?.type, "string", field);
  }
  assertEquals(SCRIPT_SCHEMA.required, [
    "condition",
    "system",
    "definition",
    "predisposing",
    "pathophysiology",
    "presentation",
    "diagnostics",
    "management",
    "pivots",
  ]);
  assert(!JSON.stringify(SCRIPT_SCHEMA).includes("minLength"));
  assert(!JSON.stringify(SCRIPT_SCHEMA).includes("maxLength"));
});

Deno.test("typo paragraph is only on the on-demand writer", () => {
  const text = (purpose: "write" | "review", resolveTypos: boolean) =>
    systemBlocks(purpose, resolveTypos).map((block) => block.text).join("\n");

  const seedWrite = text("write", false);
  const onDemandWrite = text("write", true);
  const review = text("review", true);

  assert(!seedWrite.includes("misspelled"), "seeder prompt picked up typo resolution");
  assert(onDemandWrite.includes(TYPO_RESOLUTION_PARAGRAPH), "on-demand prompt lost typo resolution");
  assert(!review.includes(TYPO_RESOLUTION_PARAGRAPH), "review prompt should not re-resolve the name");
  assert(seedWrite.includes(WRITE_TASK));
  assert(review.includes(REVIEW_TASK));
  assert(seedWrite.startsWith(SHARED_RULES));
  assert(onDemandWrite.startsWith(SHARED_RULES));
  assert(review.startsWith(SHARED_RULES));
});

Deno.test("shared prefix is cached and carries the why rules", () => {
  for (const blocks of [
    systemBlocks("write", false),
    systemBlocks("write", true),
    systemBlocks("review", false),
  ]) {
    assertEquals(blocks[0].text, SHARED_RULES);
    assertEquals(blocks[0].cache_control.type, "ephemeral");
    assertEquals(blocks[1].cache_control.type, "ephemeral");
  }
  assert(SHARED_RULES.includes('knows the "what" but not the "why"'));
  assert(SHARED_RULES.includes(
    "Test: why it's ordered (what it looks for or rules out, and what a positive/negative result means for this patient)",
  ));
  assert(SHARED_RULES.includes(
    "Boards vs wards: boards want head CT first to rule out bleed fast; wards often go straight to MRI because it shows posterior fossa and white matter lesions CT misses.",
  ));
  assert(SHARED_RULES.includes("about 35 words"));
  assert(SHARED_RULES.includes("about 25 words"));
  assert(SHARED_RULES.includes("Never invent one"));
  assert(REVIEW_TASK.includes("without its why"));
  assert(REVIEW_TASK.includes("Boards vs wards:"));
  assert(SHARED_RULES.includes("must never mention AI"));
  assert(SHARED_RULES.includes("fat-pad biopsy with Congo red"));
  assert(SHARED_RULES.includes("Tc-PYP scan once serum free light chains are negative"));
  assert(SHARED_RULES.includes('Never write a generic gap such as "boards test the diagnosis, wards stabilize first"'));
  assert(SHARED_RULES.includes("RPR or VDRL"));
  assert(SHARED_RULES.includes("Do not drop either one"));
  assert(SHARED_RULES.includes("TSH, CBC, CMP, UDS, RPR, HIV"));
  assert(REVIEW_TASK.includes("does not name both answers"));
  assert(REVIEW_TASK.includes("RPR (or VDRL) and HIV"));
  const schemaText = JSON.stringify(SCRIPT_SCHEMA);
  assert(schemaText.includes("both concrete answers"));
  assert(schemaText.includes("keep RPR (or VDRL) and HIV"));
});

Deno.test("fast profile stays capped and full profile thinks on both passes", () => {
  const fast = generationProfile("fast");
  assertEquals(fast.writer, { type: "disabled" });
  assertEquals(fast.reviewer, { type: "enabled", budget_tokens: 1024 });
  assertEquals(fast.maxTokens, 8_000);
  assertEquals(fast.effort, undefined);

  const full = generationProfile("full");
  assertEquals(full.writer, { type: "adaptive" });
  assertEquals(full.reviewer, { type: "adaptive" });
  assertEquals(full.effort, "high");
  assertEquals(full.effort, FULL_EFFORT);
  assertEquals(full.maxTokens, FULL_MAX_TOKENS);
  assertEquals(full.maxTokens, 10_000);
});

Deno.test("row update keeps identity columns out of the payload", () => {
  const script: IllnessScript = {
    condition: "Pulmonary embolism",
    system: "Pulmonology",
    definition: "A clot in the pulmonary arteries that obstructs flow.",
    predisposing: ["Recent surgery, because stasis and endothelial injury raise clot risk."],
    pathophysiology: ["Embolus blocks pulmonary flow, which raises dead space and can drop oxygenation."],
    presentation: ["Sudden dyspnea and pleuritic pain as infarcted pleura becomes inflamed."],
    diagnostics: ["CT pulmonary angiography: looks for filling defects and a positive study confirms PE."],
    management: ["Anticoagulation: stops further clot while endogenous lysis clears what is already there."],
    pivots: [{ condition: "Pneumonia", distinguisher: "Fever and a focal infiltrate point to pneumonia rather than a clot." }],
  };
  const row = scriptRowUpdate(script, "2026-01-01T00:00:00.000Z");
  assertEquals(row.one_liner, script.definition);
  assertEquals(row.schema_version, 2);
  assertEquals(row.model, MODEL);
  assert(!("condition_key" in row));
  assert(!("miss_count" in row));
  assert(!("review_count" in row));
  assertEquals(normalizeKey("Guillain-Barré syndrome"), "guillain barre syndrome");
});
