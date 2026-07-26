// Rounds — RevenueCat webhook
//
// Mirrors subscription state from RevenueCat onto public.profiles so the web
// (and the admin console) can see what someone actually bought.
//
// Before this existed, `pro_source` was only ever written by redeem-code, so a
// real App Store purchase never touched the database at all: RevenueCat knew,
// the iOS SDK knew, and getrounds.app told a paying subscriber they were on the
// free plan indefinitely.
//
// RevenueCat stays the source of truth for entitlements. This is a mirror, kept
// current by events, and read through public.profile_has_pro() which also
// accounts for code-redeemed Pro.
//
// Deploy:  supabase functions deploy revenuecat-webhook --no-verify-jwt
//   (--no-verify-jwt is required: RevenueCat is not a Supabase user and sends
//    its own Authorization header, which we check below.)
//
// Secrets (supabase secrets set ...):
//   RC_WEBHOOK_SECRET   the exact string configured as the Authorization
//                       header value in RevenueCat → Integrations → Webhooks
//   RC_ENTITLEMENT_ID   entitlement lookup_key (default "Rounds Pro")
//
// RevenueCat → Integrations → Webhooks:
//   URL     https://gvbycponexvxsbrlaejw.supabase.co/functions/v1/revenuecat-webhook
//   Header  Authorization: <the same value as RC_WEBHOOK_SECRET>

import { createClient } from "jsr:@supabase/supabase-js@2";

type RCEvent = {
  id?: string;
  type?: string;
  app_user_id?: string;
  original_app_user_id?: string;
  product_id?: string;
  period_type?: string;
  store?: string;
  environment?: string;
  expiration_at_ms?: number | null;
  entitlement_ids?: string[] | null;
  transferred_to?: string[] | null;
  transferred_from?: string[] | null;
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
  const candidates = [event.app_user_id, event.original_app_user_id]
    .filter((v): v is string => typeof v === "string" && UUID_RE.test(v));

  if (candidates.length === 0) {
    // A customer who never signed in through AccountManager. Nothing to mirror
    // onto, and not an error worth retrying.
    return json({ status: "no_mappable_user", app_user_id: event.app_user_id ?? null });
  }
  const userId = candidates[0];

  const mapped = statusFor(event);
  if (!mapped) {
    return json({ status: "acknowledged", type: event.type });
  }

  const { data: profile } = await admin
    .from("profiles")
    .select("id, rc_last_event_id")
    .eq("id", userId)
    .maybeSingle();

  if (!profile) {
    return json({ status: "unknown_profile", user_id: userId });
  }

  // RevenueCat retries on non-2xx and may deliver the same event more than
  // once. Replaying an EXPIRATION after a RENEWAL would wrongly downgrade a
  // paying user, so drop exact repeats.
  if (event.id && profile.rc_last_event_id === event.id) {
    return json({ status: "duplicate", event_id: event.id });
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
      subscription_store: event.store?.toLowerCase() ?? null,
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

  return json({
    status: "ok",
    user_id: userId,
    type: event.type,
    subscription_status: mapped.status,
  });
});
