// Shared illness-script prompt, schema, and generation.
//
// Both the on-demand `illness-script` function and the `seed-illness-scripts`
// seeder import this module so the teaching rules cannot drift. The on-demand
// writer adds the typo/synonym paragraph; the seeder does not.
//
// Generation is two calls on claude-sonnet-4-6. The shared rules are the cached
// prefix of both calls. Only the corrected script is returned — callers must
// not persist the draft.
//
// Two quality profiles share this prompt:
//   fast — sync callers (the shipped app, the seeder). Writer thinking is off
//     and the reviewer gets a 1,024-token budget (~60-66s). Must stay inside
//     client timeouts.
//   full — background builds only. Adaptive thinking at effort "high" on both
//     passes, which previously measured 285-305s. See generationProfile.

import Anthropic from "npm:@anthropic-ai/sdk@0.68.0";

export const MODEL = "claude-sonnet-4-6";
export const SCHEMA_VERSION = 2;

// Paid-plan edge workers live 400s, and EdgeRuntime.waitUntil counts against
// that same clock (https://supabase.com/docs/guides/functions/limits). Full
// adaptive on both passes measured 285-305s when max_tokens was 8,000.
// Thinking tokens share that ceiling with the script, so the background
// profile raises it to 10,000: room for a longer concrete "Boards vs wards"
// bullet plus reasoning, while a pass that filled the whole ceiling would
// still land near 305s * (10/8) ≈ 380s, inside 400s. Effort stays "high"
// (Sonnet 4.6's default, the setting behind that measurement). "max" and
// "xhigh" drop the thinking cap and can miss the wall clock.
export const FAST_MAX_TOKENS = 8_000;
export const FULL_MAX_TOKENS = 10_000;
export const FULL_EFFORT = "high" as const;

export type ScriptQuality = "fast" | "full";

type Thinking =
  | { type: "disabled" }
  | { type: "enabled"; budget_tokens: number }
  | { type: "adaptive" };

const FAST_WRITER_THINKING: Thinking = { type: "disabled" };
const FAST_REVIEWER_THINKING: Thinking = { type: "enabled", budget_tokens: 1024 };
const FULL_THINKING: Thinking = { type: "adaptive" };

export type GenerationProfile = {
  maxTokens: number;
  /** Omitted on the fast path so that request stays shaped as it is today. */
  effort?: typeof FULL_EFFORT;
  writer: Thinking;
  reviewer: Thinking;
};

export function generationProfile(quality: ScriptQuality): GenerationProfile {
  if (quality === "full") {
    return {
      maxTokens: FULL_MAX_TOKENS,
      effort: FULL_EFFORT,
      writer: FULL_THINKING,
      reviewer: FULL_THINKING,
    };
  }
  return {
    maxTokens: FAST_MAX_TOKENS,
    writer: FAST_WRITER_THINKING,
    reviewer: FAST_REVIEWER_THINKING,
  };
}

export const TYPO_RESOLUTION_PARAGRAPH =
  `The user's input may be misspelled, abbreviated, or a synonym (e.g. "heart attack", "MI", "ovarian torsion"). Always resolve it to the correct CANONICAL condition and put the standard name in \`condition\`.`;

export const SHARED_RULES = `You write an illness script for a medical student who knows the "what" but not the "why". Students memorize facts and forget to ask why. Hand them the why.

Governing principle: every bullet states the fact and the reason it matters, unless that reason is already obvious to a clerkship student. Say what is being looked for, what it rules in or out, and what the result changes. Tie each mechanism to the finding it produces. Plain language. If a term may be unfamiliar, gloss it in a few words in the same bullet.

Correctness: follow current US guidelines and what NBME shelf and Step 2 CK answer keys expect. Do not list a test as routine when guidelines reserve it for specific indications; state the indication instead. Example: neuroimaging or EEG in first-episode psychosis is not a default panel — order it for focal neurologic signs, atypical features, or another guideline indication. The opposite mistake matters too: for a psychotic disorder (schizophrenia, schizoaffective disorder, brief psychotic disorder, first-episode psychosis), syphilis serology (RPR or VDRL) and HIV stay in the medical rule-out whenever those guidelines or answer keys include them. Do not drop either one. This is an educational study reference, not individualized medical advice and not a substitute for supervision. The script a student reads must never mention AI, a model, a generator, or that the text was written or reviewed.

Form: tight, scannable bullets, never paragraphs. Diagnostics bullets, and any bullet that starts with "Boards vs wards:", may run up to about 35 words. Every other bullet stays under about 25 words.

- definition: one-line snapshot of what the condition is and the mechanism or consequence that defines it. Under about 25 words.
- predisposing: who gets it and why that factor matters. 3-6 bullets.
- pathophysiology: the core mechanism, linked to a finding the student will see — why the sign, symptom, or lab appears. 2-4 bullets.
- presentation: classic triad, timeline, pathognomonic signs, and key exam findings, each with why it shows up. 3-6 bullets.
- diagnostics: 3-6 strings. Each string is one bullet in this exact shape: "Test: why it's ordered (what it looks for or rules out, and what a positive/negative result means for this patient)." Include the first-line test, the gold-standard or confirmatory test, and one pearl or pitfall, each with the why. Group routine rule-out labs that share a purpose into one bullet, for example: "TSH, CBC, CMP, UDS, RPR, HIV: rule out medical, infectious, and substance causes of psychosis such as hyperthyroidism, anemia, metabolic derangement, syphilis, HIV, and intoxication." Aim at this kind of reasoning: for suspected cardiac amyloidosis, "SPEP/UPEP with serum free light chains: look for a monoclonal light chain, which separates AL amyloid (needs hematology and chemo, urgent) from ATTR amyloid (then confirm with a Tc-PYP scan)."
- management: first-line treatment, definitive treatment, key contraindications, and disposition. 3-5 bullets. Where the reason is not obvious, add one short reason for the first-line drug or step: why this choice, and what it changes.
- pivots: the 2-4 closest lookalikes. Each distinguisher is the single sharpest separating feature and why that feature works. Highest-yield section — write it as a vignette fork.

Boards vs wards: whenever the board or NBME answer differs from real clerkship or hospital practice — which test comes first, the classic triad versus how it actually presents, a test boards drill that wards rarely order — add one bullet in the section it belongs to (presentation, diagnostics, or management). Begin that bullet with exactly "Boards vs wards:". Name a concrete, well-known difference: the specific board answer and the specific practice answer (the test, drug, sequence, or finding — not a vague strategy), and why each choice is made. Both answers must be specific enough that a student could select them on a question. Example: "Boards vs wards: boards want head CT first to rule out bleed fast; wards often go straight to MRI because it shows posterior fossa and white matter lesions CT misses." Example: "Boards vs wards: boards want fat-pad biopsy with Congo red; practice uses a Tc-PYP scan once serum free light chains are negative, because a negative clone makes ATTR likely and biopsy unnecessary." Never write a generic gap such as "boards test the diagnosis, wards stabilize first" or "boards want the classic test, wards treat empirically" — a bullet that does not name both concrete answers is wrong. Only when the difference is real, well-known, and you are confident of it; if unsure, leave it out. Never invent one. At most one such bullet per section, and never state the same gap in two sections.`;

export const WRITE_TASK = `Write the illness script for the single condition in the user message. Put the canonical condition name in \`condition\`. Put the primary specialty in \`system\`, Title Case (for example "Cardiology" or "Obstetrics & Gynecology"). Fill every required field. Do not add fields.`;

export const REVIEW_TASK = `Review the draft illness script in the user message as a clinical educator. Check it against current US guidelines and against NBME shelf and Step 2 CK answer keys. Return only the corrected script in the same schema. Only the corrected script is saved.

Fix factual errors. Remove any test listed as routine when guidelines reserve it for a specific indication, and state that indication instead. Do not invent tests, doses, or distinctions.

Apply the rules above. Reject any bullet that states a what without its why where the why is not obvious, and rewrite it so the reason is explicit. That covers diagnostics (why it is ordered, what it looks for or rules out, and what a positive or negative result means), management (why this drug or step), pathophysiology and presentation (why the sign appears), and pivots (why the distinguisher works). Keep each diagnostics bullet in the form "Test: why it's ordered (what it looks for or rules out, and what a positive/negative result means for this patient)."

If a real, well-known board-versus-wards difference is missing, add one "Boards vs wards:" bullet in the matching section that names both concrete answers (the specific test, drug, sequence, or finding) and why each choice is made. If the draft invented a difference, or wrote a generic line that does not name both answers (for example "boards test the diagnosis, wards stabilize first"), delete or rewrite that bullet. Never invent one to fill the slot.

If the condition is a psychotic disorder and US guidelines or NBME/Step keys include syphilis serology and HIV in the medical rule-out, the diagnostics must still contain RPR (or VDRL) and HIV. Put them back if the draft dropped them.

Keep the canonical condition name already on the draft. Do not change it back to a typo or a synonym from the request. The script a student reads must never mention AI, a model, a generator, or that the text was written or reviewed.`;

export const SCRIPT_SCHEMA = {
  type: "object",
  additionalProperties: false,
  properties: {
    condition: {
      type: "string",
      description: "The canonical condition name.",
    },
    system: {
      type: "string",
      description: "Primary specialty/system, Title Case (e.g. 'Obstetrics & Gynecology', 'Cardiology', 'Neurology').",
    },
    definition: {
      type: "string",
      description: "One-line snapshot of the condition and the mechanism or consequence that defines it. Under about 25 words.",
    },
    predisposing: {
      type: "array",
      description: "Who gets it and why that factor matters. 3-6 bullets, each under about 25 words.",
      items: { type: "string" },
    },
    pathophysiology: {
      type: "array",
      description: "Core mechanism tied to a finding: why the sign, symptom, or lab appears. 2-4 bullets, each under about 25 words.",
      items: { type: "string" },
    },
    presentation: {
      type: "array",
      description: "Classic triad, timeline, pathognomonic signs, and key exam findings, each with why it shows up. 3-6 bullets under about 25 words. A real, well-known board-versus-wards presentation gap may be one bullet starting 'Boards vs wards:' (up to about 35 words) that names both concrete answers and why each is used. Never a generic 'boards test X, wards stabilize first'. Never invent that gap.",
      items: { type: "string" },
    },
    diagnostics: {
      type: "array",
      description: "3-6 strings. Each is 'Test: why it's ordered (what it looks for or rules out, and what a positive/negative result means for this patient).' Up to about 35 words. Include the first-line test, the gold-standard or confirmatory test, and one pearl or pitfall, each with the why. Group routine rule-out labs that share a purpose. For a psychotic disorder, keep RPR (or VDRL) and HIV in that rule-out bullet when guidelines or board keys include them. Do not list a test as routine when guidelines reserve it for a specific indication; state the indication. A real, well-known board-versus-wards testing gap may be one bullet starting 'Boards vs wards:' that names both concrete answers and why each is chosen. Never a generic gap. Never invent that gap.",
      items: { type: "string" },
    },
    management: {
      type: "array",
      description: "First-line and definitive treatment, key contraindications, and disposition. 3-5 bullets under about 25 words, with one short reason for each first-line drug or step when the reason is not obvious. A real, well-known board-versus-wards treatment gap may be one bullet starting 'Boards vs wards:' (up to about 35 words) that names both concrete answers and why each is chosen. Never a generic 'boards test X, wards stabilize first'. Never invent that gap.",
      items: { type: "string" },
    },
    pivots: {
      type: "array",
      description: "2-4 closest lookalikes. The distinguisher is the single sharpest separating feature and why that feature works.",
      items: {
        type: "object",
        additionalProperties: false,
        properties: {
          condition: { type: "string", description: "The competing/lookalike diagnosis." },
          distinguisher: {
            type: "string",
            description: "The sharpest feature that separates this condition from the lookalike, and why that feature works. Under about 25 words.",
          },
        },
        required: ["condition", "distinguisher"],
      },
    },
  },
  required: [
    "condition",
    "system",
    "definition",
    "predisposing",
    "pathophysiology",
    "presentation",
    "diagnostics",
    "management",
    "pivots",
  ],
};

export type IllnessPivot = { condition: string; distinguisher: string };

export type IllnessScript = {
  condition: string;
  system: string;
  definition: string;
  predisposing: string[];
  pathophysiology: string[];
  presentation: string[];
  diagnostics: string[];
  management: string[];
  pivots: IllnessPivot[];
};

type SystemBlock = {
  type: "text";
  text: string;
  cache_control: { type: "ephemeral" };
};

/** Stable system blocks. Block 1 is the shared cached prefix of every call. */
export function systemBlocks(purpose: "write" | "review", resolveTypos: boolean): SystemBlock[] {
  const task = purpose === "review"
    ? REVIEW_TASK
    : (resolveTypos ? `${TYPO_RESOLUTION_PARAGRAPH}\n\n${WRITE_TASK}` : WRITE_TASK);
  return [
    { type: "text", text: SHARED_RULES, cache_control: { type: "ephemeral" } },
    { type: "text", text: task, cache_control: { type: "ephemeral" } },
  ];
}

export function normalizeKey(s: string): string {
  return s
    .normalize("NFKD").replace(/\p{Diacritic}/gu, "")
    .toLowerCase().replace(/[^a-z0-9 ]/g, " ").replace(/\s+/g, " ").trim();
}

/** Columns both writers update. Omits condition_key and the counters so an
 * in-place upsert/update keeps the row's identity, aliases, and counts. */
export function scriptRowUpdate(script: IllnessScript, now = new Date().toISOString()) {
  return {
    condition: script.condition,
    system: script.system,
    one_liner: script.definition,
    predisposing: script.predisposing,
    pathophysiology: script.pathophysiology,
    presentation: script.presentation,
    diagnostics: script.diagnostics,
    management: script.management,
    pivots: script.pivots,
    schema_version: SCHEMA_VERSION,
    model: MODEL,
    updated_at: now,
  };
}

function parseScript(text: string): IllnessScript {
  let raw: unknown;
  try {
    raw = JSON.parse(text);
  } catch {
    throw new Error("invalid_json");
  }
  if (!raw || typeof raw !== "object") throw new Error("invalid_script");
  const row = raw as Record<string, unknown>;

  const str = (field: string): string => {
    if (typeof row[field] !== "string") throw new Error(`invalid_${field}`);
    return row[field] as string;
  };
  const strings = (field: string): string[] => {
    const value = row[field];
    if (!Array.isArray(value) || value.some((item) => typeof item !== "string")) {
      throw new Error(`invalid_${field}`);
    }
    return value as string[];
  };
  if (!Array.isArray(row.pivots)) throw new Error("invalid_pivots");
  const pivots = row.pivots.map((item) => {
    if (!item || typeof item !== "object") throw new Error("invalid_pivots");
    const pivot = item as Record<string, unknown>;
    if (typeof pivot.condition !== "string" || typeof pivot.distinguisher !== "string") {
      throw new Error("invalid_pivots");
    }
    return { condition: pivot.condition, distinguisher: pivot.distinguisher };
  });

  return {
    condition: str("condition"),
    system: str("system"),
    definition: str("definition"),
    predisposing: strings("predisposing"),
    pathophysiology: strings("pathophysiology"),
    presentation: strings("presentation"),
    diagnostics: strings("diagnostics"),
    management: strings("management"),
    pivots,
  };
}

function assertComplete(script: IllnessScript): void {
  if (!script.condition.trim()) throw new Error("invalid_condition");
  if (!script.system.trim()) throw new Error("invalid_system");
  if (!script.definition.trim()) throw new Error("invalid_definition");
  const sections = {
    predisposing: script.predisposing,
    pathophysiology: script.pathophysiology,
    presentation: script.presentation,
    diagnostics: script.diagnostics,
    management: script.management,
  };
  for (const [field, items] of Object.entries(sections)) {
    if (items.length === 0 || items.some((item) => !item.trim())) {
      throw new Error(`invalid_${field}`);
    }
  }
  if (
    script.pivots.length === 0 ||
    script.pivots.some((pivot) => !pivot.condition.trim() || !pivot.distinguisher.trim())
  ) {
    throw new Error("invalid_pivots");
  }
}

async function complete(
  client: Anthropic,
  blocks: SystemBlock[],
  userText: string,
  thinking: Thinking,
  maxTokens: number,
  effort?: typeof FULL_EFFORT,
): Promise<IllnessScript> {
  const outputConfig: {
    format: { type: "json_schema"; schema: typeof SCRIPT_SCHEMA };
    effort?: typeof FULL_EFFORT;
  } = { format: { type: "json_schema", schema: SCRIPT_SCHEMA } };
  // Fast calls omit effort so the request matches the shipped sync shape.
  if (effort) outputConfig.effort = effort;

  const stream = client.messages.stream({
    model: MODEL,
    max_tokens: maxTokens,
    thinking,
    system: blocks,
    output_config: outputConfig,
    messages: [{ role: "user", content: userText }],
  } as unknown as Anthropic.MessageStreamParams);
  const message = await stream.finalMessage();
  if (message.stop_reason === "refusal") throw new Error("refused");
  if (message.stop_reason === "max_tokens") throw new Error("truncated");
  const block = message.content.find((b) => b.type === "text");
  if (!block || block.type !== "text") throw new Error("no_output");
  return parseScript(block.text);
}

/**
 * Draft, then one review pass. Returns the corrected script only.
 * `resolveTypos` adds synonym/typo resolution for the on-demand writer.
 * `quality` defaults to "fast" (sync callers and the seeder). Background
 * builds pass "full".
 */
export async function generateIllnessScript(
  client: Anthropic,
  conditionText: string,
  options: { resolveTypos: boolean; quality?: ScriptQuality },
): Promise<IllnessScript> {
  const profile = generationProfile(options.quality ?? "fast");
  const draft = await complete(
    client,
    systemBlocks("write", options.resolveTypos),
    `Write the illness script for: ${conditionText}`,
    profile.writer,
    profile.maxTokens,
    profile.effort,
  );
  const corrected = await complete(
    client,
    systemBlocks("review", false),
    `Requested condition: ${conditionText}\n\nDraft JSON:\n${JSON.stringify(draft)}`,
    profile.reviewer,
    profile.maxTokens,
    profile.effort,
  );
  assertComplete(corrected);
  return corrected;
}
