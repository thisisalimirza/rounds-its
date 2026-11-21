// Editable founder-email copy.
//
// The admin (getrounds.app → Announcements & Comms → Automatic emails) edits
// public.email_templates. This file reads a row and renders it; index.ts falls
// back to its built-in text when the row is missing or cannot be read.
//
// renderMergeTags is a copy of lib/comms/merge.ts in roundsapp-landing. Keep
// the two in step.

export type TemplateKey = "founder_paid" | "founder_paid_upgrade" | "founder_free";

export type TemplateRow = {
  subject: string;
  body: string;
  from_name: string | null;
  reply_to: string | null;
  enabled: boolean;
};

export type MergeContext = { firstName?: string | null; school?: string | null };

const TAG = /\{(first_name|school|greeting)(?:\|([^{}\n]*))?\}/gi;

function clean(value: string | null | undefined): string {
  return (value ?? "").replace(/\s+/g, " ").trim();
}

/**
 *   {greeting}          "hi sam." or "hi." (the original opening line)
 *   {first_name}        their first name, or "there"
 *   {first_name|word}   their first name, or the word after the bar
 *   {school}            their school, or "your school"
 */
export function renderMergeTags(text: string, ctx: MergeContext): string {
  const first = clean(ctx.firstName);
  const school = clean(ctx.school);
  return text.replace(TAG, (_m, raw: string, fallback: string | undefined) => {
    const tag = raw.toLowerCase();
    if (tag === "greeting") return first ? `hi ${first.toLowerCase()}.` : "hi.";
    if (tag === "first_name") return first || (fallback ?? "there");
    return school || (fallback ?? "your school");
  });
}

export function usesSchool(text: string): boolean {
  return /\{school(\|[^{}\n]*)?\}/i.test(text);
}

export function templateKey(emailType: "paid" | "free", upgrade: boolean): TemplateKey {
  if (emailType === "free") return "founder_free";
  return upgrade ? "founder_paid_upgrade" : "founder_paid";
}

/** The bare address from "Name <addr>" or "addr". */
export function addressOf(from: string): string {
  const m = /<([^>]+)>/.exec(from);
  return (m ? m[1] : from).trim();
}

/** The From header with the template's name, keeping the configured address. */
export function fromWithName(configuredFrom: string, name: string | null | undefined): string {
  const clean = (name ?? "").replace(/["<>\r\n]/g, "").trim();
  if (!clean) return configuredFrom;
  return `${clean} <${addressOf(configuredFrom)}>`;
}

const EMAIL = /^[^\s@<>",;]+@[^\s@<>",;]+\.[^\s@<>",;]+$/;

/** A usable row, or null. A row with an empty subject or body is treated as missing. */
export function usableRow(row: unknown): TemplateRow | null {
  if (!row || typeof row !== "object") return null;
  const r = row as Record<string, unknown>;
  const subject = typeof r.subject === "string" ? r.subject.trim() : "";
  const body = typeof r.body === "string" ? r.body : "";
  if (!subject || !body.trim()) return null;
  const replyTo = typeof r.reply_to === "string" && EMAIL.test(r.reply_to.trim()) ? r.reply_to.trim() : null;
  return {
    subject,
    body,
    from_name: typeof r.from_name === "string" ? r.from_name : null,
    reply_to: replyTo,
    enabled: r.enabled !== false,
  };
}

// deno-lint-ignore no-explicit-any
type Admin = any;

/** The saved template, or null when there is none or it cannot be read (the caller falls back). */
export async function loadTemplate(admin: Admin, key: TemplateKey): Promise<TemplateRow | null> {
  try {
    const { data, error } = await admin
      .from("email_templates")
      .select("subject, body, from_name, reply_to, enabled")
      .eq("key", key)
      .maybeSingle();
    if (error) {
      console.warn(`founder-email: template ${key} could not be read, using built-in copy: ${error.message}`);
      return null;
    }
    return usableRow(data);
  } catch (err) {
    console.warn(`founder-email: template ${key} read threw, using built-in copy:`, err);
    return null;
  }
}
