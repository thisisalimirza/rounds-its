// Rounds — RevenueCat webhook
//
// Mirrors subscription state from RevenueCat onto public.profiles so the web
// (and the admin console) can see what someone actually bought.
//
// RevenueCat stays the source of truth for entitlements. With RC_V2_SECRET_KEY
// set, every event triggers a fresh lookup of each affected user's *current*
// state (state.ts), so out-of-order events, transfers, aliases (anonymous
// purchase later logged in) and promotional grants all converge. Without the
// key it falls back to mapping the event itself, refusing stale events.
//
// On the first real payment, this also triggers the founder email via the
// founder-email edge function. "First real payment" means money changed hands:
//   * INITIAL_PURCHASE that is not a free trial (period_type != TRIAL)
//   * RENEWAL with is_trial_conversion: true (the trial just converted)
//   * NON_RENEWING_PURCHASE (lifetime / one-off)
// Trial starts and RevenueCat-granted promotional entitlements are skipped.
//
// Deploy:  supabase functions deploy revenuecat-webhook --no-verify-jwt
//
// Secrets:
//   RC_WEBHOOK_SECRET   the exact Authorization header value set in RevenueCat
//   RC_V2_SECRET_KEY    RevenueCat v2 secret key (customer information: read)
//   RC_ENTITLEMENT_ID   entitlement lookup_key (default "Rounds Pro")

import { createClient } from "jsr:@supabase/supabase-js@2";
import { currentState, type MirrorPatch } from "./state.ts";

type RCEvent = {
  id?: string;
  type?: string;
  app_user_id?: string;
  original_app_user_id?: string;
  product_id?: string;
  period_type?: string;
  is_trial_conversion?: boolean | null;
  store?: string;
  environment?: string;
  expiration_at_ms?: number | null;
  entitlement_ids?: string[] | null;
  transferred_to?: string[] | null;
  transferred_from?: string[] | null;
  aliases?: string[] | null;
  event_timestamp_ms?: number | null;
};

/** Our subscription_status values, mirroring the profiles CHECK constraint. */
type Status =
  | "free" | "active" | "trialing" | "grace_period"
  | "billing_issue" | "expired" | "paused";

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/**
 * True when this event is the customer's first real payment (see header).
 * Repeats are harmless: founder-email records each send and never re-sends.
 */
function isFirstPaidEvent(event: RCEvent): boolean {
  const type = (event.type ?? "").toUpperCase();
  const periodType = (event.period_type ?? "").toUpperCase();
  const store = (event.store ?? "").toUpperCase();

  // Granted by RevenueCat (support comps, etc.), not paid for.
  if (store === "PROMOTIONAL" || periodType === "PROMOTIONAL") return false;

  switch (type) {
    case "INITIAL_PURCHASE":
      // A free trial starting is not a payment; the conversion RENEWAL is.
      return periodType !== "TRIAL";
    case "RENEWAL":
      return event.is_trial_conversion === true;
    case "NON_RENEWING_PURCHASE":
      return true;
    default:
      return false;
  }
}

/** Supabase user ids are UUIDs. RevenueCat sends `$RCAnonymousID:...` for a
 *  customer that never called logIn, which we cannot map to a profile. */
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * Maps an event to the state it implies.
 *
 * Note CANCELLATION does **not** mean "no longer subscribed" — it means
 * auto-renew was turned off. Access continues until expiration, and RevenueCat
 * sends a separate EXPIRATION event then. Treating cancellation as an
 * immediate downgrade would cut off people who have already paid for the rest
 * of their term.
 */
function statusFor(event: RCEvent): { status: Status; willRenew: boolean | null } | null {
  const type = (event.type ?? "").toUpperCase();
  const isTrial = (event.period_type ?? "").toUpperCase() === "TRIAL";

  switch (type) {
    case "INITIAL_PURCHASE":
    case "RENEWAL":
    case "UNCANCELLATION":
    case "PRODUCT_CHANGE":
    case "SUBSCRIPTION_EXTENDED":
      return { status: isTrial ? "trialing" : "active", willRenew: true };

    case "NON_RENEWING_PURCHASE":
      // Lifetime and other one-off purchases: active, nothing to renew.
      return { status: "active", willRenew: false };

    case "CANCELLATION":
      return { status: isTrial ? "trialing" : "active", willRenew: false };

    case "BILLING_ISSUE":
      return { status: "billing_issue", willRenew: null };

    case "SUBSCRIPTION_PAUSED":
      return { status: "paused", willRenew: null };

    case "EXPIRATION":
      return { status: "expired", willRenew: false };

    // Acknowledged but carry no state we mirror.
    case "TRANSFER":
    case "SUBSCRIBER_ALIAS":
    case "TEST":
      return null;

    default:
      return null;
  }
}



Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const secret = Deno.env.get("RC_WEBHOOK_SECRET");
  if (!secret) {
    console.error("RC_WEBHOOK_SECRET is not set — refusing all webhooks");
    return json({ error: "not_configured" }, 500);
  }

  // RevenueCat sends the configured value verbatim in Authorization. Reject
  // anything else: this endpoint runs without JWT verification, so this header
  // is the only thing standing between the internet and a customer's
  // subscription state.
  if (req.headers.get("Authorization") !== secret) {
    return json({ error: "unauthorized" }, 401);
  }

  let body: { event?: RCEvent };
  try {
    body = await req.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }

  const event = body?.event;
  if (!event?.type) return json({ error: "missing_event" }, 400);

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const entitlementId = Deno.env.get("RC_ENTITLEMENT_ID") ?? "Rounds Pro";

  // Ignore events for entitlements we don't gate on. `entitlement_ids` is
  // absent on some event types, which we treat as "applies to us".
  if (event.entitlement_ids?.length && !event.entitlement_ids.includes(entitlementId)) {
    return json({ status: "ignored_entitlement" });
  }

  // Prefer app_user_id (set by Purchases.logIn to the Supabase user id) and
  // fall back to the original id, which is what transfers report.
  // Every Supabase user this event touches: the buyer, every alias (an
  // anonymous purchase later logged in to a real id), and both sides of a
  // transfer (the purchase moved from one account to the other).
  const candidates = [...new Set(
    [
      event.app_user_id,
      event.original_app_user_id,
      ...(event.aliases ?? []),
      ...(event.transferred_to ?? []),
      ...(event.transferred_from ?? []),
    ].filter((v): v is string => typeof v === "string" && UUID_RE.test(v))
      .map((v) => v.toLowerCase()),
  )];

  if (candidates.length === 0) {
    // A customer who never signed in through AccountManager. Nothing to mirror
    // onto, and not an error worth retrying.
    return json({ status: "no_mappable_user", app_user_id: event.app_user_id ?? null });
  }
  // TRANSFER: the purchase moved between accounts (restore on another device,
  // or the email account created by "link email"). Move the mirror with it and
  // mark an anonymous account it left as merged into the new one, so the
  // console shows one person. Works without the v2 key.
  if ((event.type ?? "").toUpperCase() === "TRANSFER") {
    const uuids = (xs?: string[] | null) =>
      (xs ?? []).filter((v) => UUID_RE.test(v)).map((v) => v.toLowerCase());
    const from = uuids(event.transferred_from);
    const to = uuids(event.transferred_to);
    if (from.length && to.length) {
      const { error: tErr } = await admin.rpc("rc_apply_transfer", { p_from: from, p_to: to });
      if (tErr) {
        console.error("rc_apply_transfer failed:", tErr.message);
        return json({ error: "transfer_failed", detail: tErr.message }, 500);
      }
    }
  }

  const rcKey = Deno.env.get("RC_V2_SECRET_KEY");
  if (rcKey && (event.type ?? "").toUpperCase() !== "TEST") {
    const results: Record<string, string> = {};
    for (const uid of candidates) {
      let state: MirrorPatch | null;
      try {
        state = await currentState(uid, rcKey);
      } catch (e) {
        // 500 so RevenueCat retries: a dropped event leaves the mirror stale.
        console.error("RevenueCat lookup failed:", e);
        return json({ error: "revenuecat_lookup_failed" }, 500);
      }
      if (!state) { results[uid] = "not_in_revenuecat"; continue; }
      const { data: updated, error: upErr } = await admin
        .from("profiles")
        .update({ ...state, subscription_updated_at: new Date().toISOString(), rc_last_event_id: event.id ?? null })
        .eq("id", uid)
        .select("id");
      if (upErr) {
        console.error("profile update failed:", upErr.message);
        return json({ error: "update_failed", detail: upErr.message }, 500);
      }
      results[uid] = updated?.length ? state.subscription_status : "unknown_profile";
    }
    const primary = candidates[0];
    const founder = isFirstPaidEvent(event) && results[primary] && results[primary] !== "unknown_profile"
      ? await sendFounderEmail(admin, primary, (event.environment ?? "").toUpperCase() === "SANDBOX")
      : null;
    return json({ status: "ok", mode: "state", type: event.type, results, founder_email: founder });
  }

  const userId = candidates[0];

  const mapped = statusFor(event);
  if (!mapped) {
    return json({ status: (event.type ?? "").toUpperCase() === "TRANSFER" ? "transferred" : "acknowledged", type: event.type });
  }

  const { data: profile } = await admin
    .from("profiles")
    .select("id, rc_last_event_id, subscription_updated_at")
    .eq("id", userId)
    .maybeSingle();

  if (!profile) {
    return json({ status: "unknown_profile", user_id: userId });
  }

  // First real payment (not a trial start) triggers the founder email
  const isFirstPurchase = isFirstPaidEvent(event);
  const isSandbox = (event.environment ?? "").toUpperCase() === "SANDBOX";

  // RevenueCat retries on non-2xx and may deliver the same event more than
  // once. Replaying an EXPIRATION after a RENEWAL would wrongly downgrade a
  // paying user, so drop exact repeats.
  if (event.id && profile.rc_last_event_id === event.id) {
    return json({ status: "duplicate", event_id: event.id });
  }

  // Without a key, at least refuse an event older than the last one applied.
  if (event.event_timestamp_ms && profile.subscription_updated_at &&
      event.event_timestamp_ms < new Date(profile.subscription_updated_at).getTime()) {
    return json({ status: "stale", event_id: event.id ?? null });
  }

  const expiresAt = event.expiration_at_ms
    ? new Date(event.expiration_at_ms).toISOString()
    : null;

  const { error } = await admin
    .from("profiles")
    .update({
      subscription_status: mapped.status,
      subscription_will_renew: mapped.willRenew,
      subscription_product_id: event.product_id ?? null,
      subscription_store: isSandbox ? "sandbox" : event.store?.toLowerCase() ?? null,
      subscription_period_type: event.period_type?.toLowerCase() ?? null,
      subscription_expires_at: expiresAt,
      subscription_updated_at: new Date().toISOString(),
      rc_last_event_id: event.id ?? null,
    })
    .eq("id", userId);

  if (error) {
    // 500 so RevenueCat retries — a dropped event leaves the mirror stale.
    console.error("profile update failed:", error.message);
    return json({ error: "update_failed", detail: error.message }, 500);
  }

  // -------------------------------------------------------------------------
  // Founder email: send once on first real payment (trial starts excluded)
  //
  // Triggers asynchronously and never fails the webhook — the subscription
  // state update above is the critical path; the email is a nice-to-have.
  // -------------------------------------------------------------------------
  const founderEmailStatus = isFirstPurchase
    ? await sendFounderEmail(admin, userId, isSandbox)
    : null;

  return json({
    status: "ok",
    user_id: userId,
    type: event.type,
    subscription_status: mapped.status,
    founder_email: founderEmailStatus,
  });
});

/** Founder email on first real payment. Never fails the webhook. */
async function sendFounderEmail(admin: any, userId: string, isSandbox: boolean): Promise<string> {
  try {
    const { data: authUser } = await admin.auth.admin.getUserById(userId);
    const userEmail = authUser?.user?.email;
    const firstName = authUser?.user?.user_metadata?.full_name?.split(" ")[0] ?? null;
    if (!userEmail) return "no_email";
    const founderEmailSecret = Deno.env.get("FOUNDER_EMAIL_SECRET");
    if (!founderEmailSecret) {
      console.warn("founder-email: FOUNDER_EMAIL_SECRET not set, skipping email");
      return "no_secret";
    }
    const emailRes = await fetch(`${Deno.env.get("SUPABASE_URL")!}/functions/v1/founder-email`, {
      method: "POST",
      headers: { "Authorization": `Bearer ${founderEmailSecret}`, "Content-Type": "application/json" },
      body: JSON.stringify({ user_id: userId, email_type: "paid", email: userEmail, first_name: firstName, is_sandbox: isSandbox }),
      signal: AbortSignal.timeout(10_000),
    });
    const emailResult = await emailRes.json();
    return emailResult.status ?? "unknown";
  } catch (emailErr) {
    console.error("founder-email trigger failed (non-fatal):", emailErr);
    return "error";
  }
}
