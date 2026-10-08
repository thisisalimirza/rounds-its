// Rounds — Founder email edge function
//
// Sends personal emails from Ali to:
//   1. Paid users on their first purchase (email_type: "paid")
//   2. Free users when they link an email (email_type: "free")
//
// Idempotent: checks founder_email_sends table before sending, records after.
// A user who receives the paid email will NOT receive the free email later.
//
// Deploy:  supabase functions deploy founder-email --no-verify-jwt
//   (--no-verify-jwt because this is called from revenuecat-webhook and
//    database triggers/webhooks with service role, not user JWTs)
//
// Secrets (supabase secrets set ...):
//   FOUNDER_EMAIL_SECRET    Shared secret for authenticating callers (required)
//   RESEND_API_KEY          Resend API key (re_...)
//   FOUNDER_EMAIL_FROM      From address (default: "Ali Mirza <ali@getrounds.app>")
//   FOUNDER_EMAIL_REPLY_TO  Reply-to address (Ali's real inbox)
//   FOUNDER_EMAIL_ENABLED   "true" to send, anything else to dry-run (logs only)
//   FOUNDER_EMAIL_SEND_SANDBOX  "true" to send for sandbox/TestFlight (default: skip)

import { createClient } from "jsr:@supabase/supabase-js@2";

// Constant-time string comparison to prevent timing attacks
function constantTimeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) {
    return false;
  }
  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return result === 0;
}

// =========================================================================
// Email templates
// =========================================================================

// Gift card incentive for paid user calls — change amount here
const GIFT_CARD_AMOUNT = "$25";

const PAID_EMAIL_SUBJECT = "thanks for subscribing to rounds";

// Template function for paid users
function paidEmailBody(firstName: string | null): string {
  const greeting = firstName ? `hi ${firstName.toLowerCase()}.` : "hi.";

  return `${greeting}

this is ali, i built rounds.

if you're getting this email, it means you just paid for rounds pro. that's kind of wild to me — i'm a med student at uconn who built this thing between classes and clerkship rotations, and the fact that you actually paid for it means a lot.

but here's my problem:

i have no idea why you subscribed.

rounds started as a way to make step 1 studying less miserable, but people use it for all kinds of things now — daily practice, weak-spot drilling, or just something to do during a boring lecture. i can see the numbers, but numbers don't tell me what actually made you hit "subscribe."

so if you have 30 seconds, just reply and tell me:
- what made you pay for rounds?
- what do you actually use it for?
- what's the one thing that would make it better?

i read every reply myself (there's no team, it's just me).

i'm also happy to hop on a quick call to learn a bit more about how you're using rounds. i'll send you a ${GIFT_CARD_AMOUNT} visa gift card for your time. if you're down, just reply and i'll send my calendar to book a time.

thanks for giving rounds a shot.

ali

---
you're receiving this because you subscribed to rounds pro.
if you'd rather not hear from me, just reply "stop" and i won't email you again.`;
}

const FREE_EMAIL_SUBJECT = "thanks for signing up for rounds";

// Template function for free users who link their email
function freeEmailBody(firstName: string | null): string {
  const greeting = firstName ? `hi ${firstName.toLowerCase()}.` : "hi.";

  return `${greeting}

this is ali — i'm the one who built rounds.

thanks for linking your email. now your progress is actually safe (no more losing your streak to a dead phone).

i'm curious though:

- how did you find rounds?
- what do you mostly use it for — daily cases, random practice, something else?
- what's the one thing that would make it worth paying for?

i'm a med student at uconn building this between rotations, and i genuinely want to know what would make it more useful for you. no sales pitch, i just want to make the thing better.

if you'd rather jump on a quick call instead of typing, just reply and i'll send my calendar.

thanks for trying it out.

ali

---
you're receiving this because you linked your email to your rounds account.
if you'd rather not hear from me, just reply "stop" and i won't email you again.`;
}

// =========================================================================
// Response helpers
// =========================================================================

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// =========================================================================
// Main handler
// =========================================================================

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  // -----------------------------------------------------------------------
  // Authentication — require shared secret before doing anything else
  // -----------------------------------------------------------------------
  const FOUNDER_EMAIL_SECRET = Deno.env.get("FOUNDER_EMAIL_SECRET");
  if (!FOUNDER_EMAIL_SECRET) {
    console.error("founder-email: FOUNDER_EMAIL_SECRET not set — refusing all requests");
    return json({ error: "not_configured" }, 500);
  }

  // Accept secret via Authorization header (Bearer token) or X-Founder-Email-Secret header
  const authHeader = req.headers.get("Authorization") ?? "";
  const secretHeader = req.headers.get("X-Founder-Email-Secret") ?? "";
  
  let authenticated = false;
  if (authHeader.startsWith("Bearer ")) {
    const token = authHeader.slice(7);
    authenticated = constantTimeEqual(token, FOUNDER_EMAIL_SECRET);
  }
  if (!authenticated && secretHeader) {
    authenticated = constantTimeEqual(secretHeader, FOUNDER_EMAIL_SECRET);
  }

  if (!authenticated) {
    console.warn("founder-email: unauthorized request rejected");
    return json({ error: "unauthorized" }, 401);
  }

  // -----------------------------------------------------------------------
  // Config
  // -----------------------------------------------------------------------
  const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
  const FOUNDER_EMAIL_FROM = Deno.env.get("FOUNDER_EMAIL_FROM") ?? "Ali Mirza <ali@getrounds.app>";
  const FOUNDER_EMAIL_REPLY_TO = Deno.env.get("FOUNDER_EMAIL_REPLY_TO") ?? "ali@braskgroup.com";
  const FOUNDER_EMAIL_ENABLED = Deno.env.get("FOUNDER_EMAIL_ENABLED") === "true";
  // Sandbox events are SKIPPED by default; only send if explicitly opted in
  const FOUNDER_EMAIL_SEND_SANDBOX = Deno.env.get("FOUNDER_EMAIL_SEND_SANDBOX") === "true";

  if (!RESEND_API_KEY) {
    console.log("founder-email: RESEND_API_KEY not set, skipping send");
    return json({ status: "skipped", reason: "no_api_key" });
  }

  // -----------------------------------------------------------------------
  // Parse request — supports both direct calls and Database Webhook payloads
  // -----------------------------------------------------------------------
  let rawBody: unknown;

  try {
    rawBody = await req.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }

  let user_id: string | undefined;
  let email_type: "paid" | "free" | undefined;
  let email: string | undefined;
  let first_name: string | null = null;
  let is_sandbox: boolean | undefined;

  // Check if this is a Supabase Database Webhook payload (has "type", "table", "record")
  const webhookPayload = rawBody as {
    type?: string;
    table?: string;
    schema?: string;
    record?: { id?: string; email?: string; raw_user_meta_data?: { full_name?: string } };
    old_record?: { email?: string };
  };

  if (webhookPayload.type === "UPDATE" && webhookPayload.table === "users" && webhookPayload.schema === "auth") {
    // This is a Database Webhook from auth.users
    const oldEmail = webhookPayload.old_record?.email?.trim() || null;
    const newEmail = webhookPayload.record?.email?.trim() || null;

    // Only proceed if email changed from null/empty to a real address
    if (!oldEmail && newEmail) {
      user_id = webhookPayload.record?.id;
      email_type = "free";
      email = newEmail;
      const fullName = webhookPayload.record?.raw_user_meta_data?.full_name;
      first_name = fullName ? fullName.split(" ")[0] : null;
      console.log(`founder-email: webhook detected email link for user ${user_id}`);
    } else {
      // Email didn't change from null to real — nothing to do
      return json({ status: "skipped", reason: "not_email_link" });
    }
  } else {
    // Direct call with explicit fields
    const directPayload = rawBody as {
      user_id?: string;
      email_type?: "paid" | "free";
      email?: string;
      first_name?: string | null;
      is_sandbox?: boolean;
    };
    user_id = directPayload.user_id;
    email_type = directPayload.email_type;
    email = directPayload.email;
    first_name = directPayload.first_name ?? null;
    is_sandbox = directPayload.is_sandbox;
  }

  if (!user_id || !email_type || !email) {
    return json({ error: "missing_fields", required: ["user_id", "email_type", "email"] }, 400);
  }

  if (email_type !== "paid" && email_type !== "free") {
    return json({ error: "invalid_email_type", valid: ["paid", "free"] }, 400);
  }

  // Skip sandbox/TestFlight events by default; only send if explicitly opted in
  if (is_sandbox && !FOUNDER_EMAIL_SEND_SANDBOX) {
    console.log(`founder-email: skipping sandbox event for user ${user_id}`);
    return json({ status: "skipped", reason: "sandbox_event" });
  }

  // -----------------------------------------------------------------------
  // Supabase admin client
  // -----------------------------------------------------------------------
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // -----------------------------------------------------------------------
  // Verify email belongs to user (don't trust caller blindly)
  // For direct calls, look up the user and confirm the email matches.
  // For webhook calls (where we extracted from record), this is a no-op.
  // -----------------------------------------------------------------------
  let verifiedEmail = email;
  let verifiedFirstName = first_name;

  try {
    const { data: authUser, error: authErr } = await admin.auth.admin.getUserById(user_id);
    if (authErr || !authUser?.user) {
      console.warn(`founder-email: user ${user_id} not found in auth.users`);
      return json({ status: "skipped", reason: "user_not_found" }, 404);
    }

    // Use the verified email from auth.users, not the caller's claim
    const userEmail = authUser.user.email?.trim();
    if (!userEmail) {
      console.log(`founder-email: user ${user_id} has no email address`);
      return json({ status: "skipped", reason: "no_email" });
    }
    verifiedEmail = userEmail;

    // Also get first name from user metadata if available
    const fullName = authUser.user.user_metadata?.full_name;
    if (fullName && typeof fullName === "string") {
      verifiedFirstName = fullName.split(" ")[0];
    }
  } catch (err) {
    console.error(`founder-email: failed to verify user ${user_id}:`, err);
    return json({ status: "error", reason: "user_lookup_failed" }, 500);
  }

  // -----------------------------------------------------------------------
  // Idempotency check (excludes dry-run sends)
  // -----------------------------------------------------------------------
  // Check if this specific email was already sent (real sends only)
  const { data: alreadySent } = await admin.rpc("has_received_founder_email", {
    p_user_id: user_id,
    p_email_type: email_type,
  });

  if (alreadySent) {
    console.log(`founder-email: already sent ${email_type} email to user ${user_id}`);
    return json({ status: "skipped", reason: "already_sent" });
  }

  // For free emails: skip if user already received paid email
  // (they're already engaged, no need to ask them to upgrade)
  if (email_type === "free") {
    const { data: hasPaidEmail } = await admin.rpc("has_received_founder_email", {
      p_user_id: user_id,
      p_email_type: "paid",
    });

    if (hasPaidEmail) {
      console.log(`founder-email: user ${user_id} already got paid email, skipping free`);
      return json({ status: "skipped", reason: "already_paid_user" });
    }
  }

  // -----------------------------------------------------------------------
  // Build email content (using verified email and name)
  // -----------------------------------------------------------------------
  const subject = email_type === "paid" ? PAID_EMAIL_SUBJECT : FREE_EMAIL_SUBJECT;
  const textBody = email_type === "paid"
    ? paidEmailBody(verifiedFirstName ?? null)
    : freeEmailBody(verifiedFirstName ?? null);

  // -----------------------------------------------------------------------
  // Send via Resend (or dry-run)
  // -----------------------------------------------------------------------
  let resendId: string | null = null;
  const isDryRun = !FOUNDER_EMAIL_ENABLED;

  if (isDryRun) {
    console.log(`founder-email: DRY RUN (FOUNDER_EMAIL_ENABLED != true)`);
    console.log(`  To: ${verifiedEmail}`);
    console.log(`  Subject: ${subject}`);
    console.log(`  Body preview: ${textBody.substring(0, 200)}...`);
    // Don't record dry-run sends — user should still get the real email later
    return json({
      status: "dry_run",
      email_type,
      would_send_to: verifiedEmail,
    });
  }

  try {
    const resendRes = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: FOUNDER_EMAIL_FROM,
        reply_to: FOUNDER_EMAIL_REPLY_TO,
        to: [verifiedEmail],
        subject: subject,
        text: textBody,
      }),
    });

    if (!resendRes.ok) {
      const errText = await resendRes.text();
      console.error(`founder-email: Resend API error: ${errText}`);
      // Don't fail the whole request — log and continue
      // The webhook that called us should succeed even if email fails
      return json({ status: "error", reason: "resend_api_error", detail: errText }, 502);
    }

    const resendData = await resendRes.json();
    resendId = resendData.id ?? null;
    console.log(`founder-email: sent ${email_type} email to ${verifiedEmail}, resend_id=${resendId}`);
  } catch (err) {
    console.error(`founder-email: send failed:`, err);
    return json({ status: "error", reason: "send_exception" }, 502);
  }

  // -----------------------------------------------------------------------
  // Record the send for idempotency (only for real sends, not dry-run)
  // -----------------------------------------------------------------------
  const { error: recordErr } = await admin.rpc("record_founder_email_sent", {
    p_user_id: user_id,
    p_email_type: email_type,
    p_recipient_email: verifiedEmail,
    p_first_name: verifiedFirstName ?? null,
    p_resend_id: resendId,
  });

  if (recordErr) {
    // This is likely a race condition (duplicate) — log but don't fail
    console.warn(`founder-email: failed to record send (may be duplicate):`, recordErr.message);
  }

  return json({
    status: "sent",
    email_type,
    resend_id: resendId,
  });
});
