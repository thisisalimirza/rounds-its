// Rounds — RevenueCat webhook
//
// RevenueCat stays the source of truth. This function does not trust the
// event payload for subscription_*. On every production event it re-fetches
// each affected customer (app user id, aliases, transferred_from / transferred_to)
// and rewrites that profile's subscription mirror from the live API.
//
// SANDBOX events are acknowledged and not written. A TestFlight receipt must
// not mark a production profile as Pro.
//
// A refunded or expired entitlement is no longer active, so the mirror becomes
// `expired` with an expiry. A lifetime row whose expires_at was null does not
// stay Pro after a refund.
//
// Deploy:  supabase functions deploy revenuecat-webhook --no-verify-jwt
//
// Secrets:
//   RC_WEBHOOK_SECRET     Authorization header configured in RevenueCat
//   RC_SECRET_KEY         RevenueCat v2 secret (sk_...). Never ship in the app
//   RC_PROJECT_ID         RevenueCat project id (proj...)
//   RC_ENTITLEMENT_ID     lookup key, default "Rounds Pro"
//   RC_RECONCILE_SECRET   admin header for the reconcile-all mode below
//   FOUNDER_EMAIL_SECRET  existing founder-email trigger
//
// ---------------------------------------------------------------------------
// Reconcile all (written, not run)
//
// Walks RevenueCat customers and repairs any profile whose live "Rounds Pro"
// entitlement does not match the mirror. One page per call so it can be
// resumed. Do not run this until you intend to rewrite production rows.
//
//   curl -X POST \
//     'https://gvbycponexvxsbrlaejw.supabase.co/functions/v1/revenuecat-webhook' \
//     -H 'Content-Type: application/json' \
//     -H "x-rounds-reconcile-secret: $RC_RECONCILE_SECRET" \
//     -d '{"mode":"reconcile_all"}'
//
// The response includes `next`. Repeat with that value until next is null:
//
//   -d '{"mode":"reconcile_all","cursor":"<next from the previous response>"}'
//
// Customers who are not a Supabase uuid, or who have no profile, are skipped.
// This does not grant or revoke anything in RevenueCat. It only rewrites
// profiles.subscription_* for customers who currently have Rounds Pro active,
// and expires the mirror when the page's customer no longer does — only for
// ids that already have a profile. It does not target individual accounts.
//
// ---------------------------------------------------------------------------
// Read check (not a write, and not run from this repo)
//
// Confirms RC_SECRET_KEY can read /customers/{id}/active_entitlements and
// /customers/{id}/subscriptions. The response is HTTP status and item counts.
// It does not update profiles.
//
//   curl -X POST \
//     'https://gvbycponexvxsbrlaejw.supabase.co/functions/v1/revenuecat-webhook' \
//     -H 'Content-Type: application/json' \
//     -H "x-rounds-reconcile-secret: $RC_RECONCILE_SECRET" \
//     -d '{"mode":"check_reads","app_user_id":"<supabase user uuid>"}'
// ---------------------------------------------------------------------------

import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  isUuid,
  listCustomers,
  rcConfig,
  probeSecretReads,
  recomputeCustomer,
  type RCConfig,
  type SubscriptionMirror,
} from "../_shared/revenuecat.ts";

type RCEvent = {
  id?: string;
  type?: string;
  app_user_id?: string;
  original_app_user_id?: string;
  aliases?: string[] | null;
  product_id?: string;
  period_type?: string;
  is_trial_conversion?: boolean | null;
  store?: string;
  environment?: string;
  expiration_at_ms?: number | null;
  entitlement_ids?: string[] | null;
  transferred_to?: string[] | null;
  transferred_from?: string[] | null;
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function isFirstPaidEvent(event: RCEvent): boolean {
  const type = (event.type ?? "").toUpperCase();
  const periodType = (event.period_type ?? "").toUpperCase();
  const store = (event.store ?? "").toUpperCase();
  if (store === "PROMOTIONAL" || periodType === "PROMOTIONAL") return false;
  switch (type) {
    case "INITIAL_PURCHASE":
      return periodType !== "TRIAL";
    case "RENEWAL":
      return event.is_trial_conversion === true;
    case "NON_RENEWING_PURCHASE":
      return true;
    default:
      return false;
  }
}

function affectedIds(event: RCEvent): string[] {
  const raw = [
    event.app_user_id,
    event.original_app_user_id,
    ...(event.aliases ?? []),
    ...(event.transferred_from ?? []),
    ...(event.transferred_to ?? []),
  ];
  const seen = new Set<string>();
  const ids: string[] = [];
  for (const value of raw) {
    if (typeof value !== "string" || !isUuid(value)) continue;
    const id = value.toLowerCase();
    if (seen.has(id)) continue;
    seen.add(id);
    ids.push(id);
  }
  return ids;
}

async function writeMirror(
  admin: ReturnType<typeof createClient>,
  userId: string,
  mirror: SubscriptionMirror,
  eventId: string | null,
): Promise<"updated" | "missing" | "error"> {
  const { data: profile, error: readError } = await admin
    .from("profiles")
    .select("id")
    .eq("id", userId)
    .maybeSingle();
  if (readError) return "error";
  if (!profile) return "missing";

  const { error } = await admin.from("profiles").update({
    subscription_status: mirror.subscription_status,
    subscription_will_renew: mirror.subscription_will_renew,
    subscription_product_id: mirror.subscription_product_id,
    subscription_store: mirror.subscription_store,
    ...(mirror.subscription_period_type
      ? { subscription_period_type: mirror.subscription_period_type }
      : {}),
    subscription_expires_at: mirror.subscription_expires_at,
    subscription_updated_at: new Date().toISOString(),
    rc_last_event_id: eventId,
  }).eq("id", userId);
  return error ? "error" : "updated";
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  let body: { event?: RCEvent; mode?: string; cursor?: string | null; app_user_id?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }

  const reconcileSecret = Deno.env.get("RC_RECONCILE_SECRET");
  if (body?.mode === "reconcile_all" || body?.mode === "check_reads") {
    if (!reconcileSecret || req.headers.get("x-rounds-reconcile-secret") !== reconcileSecret) {
      return json({ error: "unauthorized" }, 401);
    }
    if (body.mode === "check_reads") return await checkReads(body.app_user_id ?? null);
    return await reconcilePage(body.cursor ?? null);
  }

  const secret = Deno.env.get("RC_WEBHOOK_SECRET");
  if (!secret) {
    console.error("RC_WEBHOOK_SECRET is not set — refusing all webhooks");
    return json({ error: "not_configured" }, 500);
  }
  if (req.headers.get("Authorization") !== secret) {
    return json({ error: "unauthorized" }, 401);
  }

  const event = body?.event;
  if (!event?.type) return json({ error: "missing_event" }, 400);

  if ((event.environment ?? "").toUpperCase() === "SANDBOX") {
    return json({ status: "ignored_sandbox", type: event.type });
  }

  const entitlementId = Deno.env.get("RC_ENTITLEMENT_ID") ?? "Rounds Pro";
  if (event.entitlement_ids?.length && !event.entitlement_ids.includes(entitlementId)) {
    return json({ status: "ignored_entitlement" });
  }

  let config: RCConfig;
  try {
    config = rcConfig();
  } catch (error) {
    console.error(error);
    return json({ error: "not_configured" }, 500);
  }

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const ids = affectedIds(event);
  if (ids.length === 0) {
    return json({ status: "no_mappable_user", app_user_id: event.app_user_id ?? null });
  }

  const results: Record<string, string> = {};
  let wrote = false;
  let failed = false;
  for (const userId of ids) {
    try {
      const mirror = await recomputeCustomer(config, userId, event.period_type ?? null);
      const outcome = await writeMirror(admin, userId, mirror, event.id ?? null);
      results[userId] = outcome;
      if (outcome === "updated") wrote = true;
      if (outcome === "error") failed = true;
    } catch (error) {
      failed = true;
      results[userId] = "rc_error";
      console.error("recompute failed", userId, error);
    }
  }

  if (failed && !wrote) {
    return json({ error: "update_failed", results }, 500);
  }

  let founderEmailStatus: string | null = null;
  const primary = ids[0];
  if (isFirstPaidEvent(event) && results[primary] === "updated") {
    founderEmailStatus = await sendFounderEmail(admin, primary);
  }

  return json({
    status: "ok",
    type: event.type,
    results,
    founder_email: founderEmailStatus,
  });
});

async function checkReads(appUserId: string | null): Promise<Response> {
  if (!appUserId || !isUuid(appUserId)) return json({ error: "app_user_id_required" }, 400);
  let config: RCConfig;
  try {
    config = rcConfig();
  } catch (error) {
    console.error(error);
    return json({ error: "not_configured" }, 500);
  }
  try {
    const reads = await probeSecretReads(config, appUserId);
    return json({ status: "read_only", ...reads });
  } catch (error) {
    console.error(error);
    return json({ error: "rc_read_failed" }, 502);
  }
}

async function reconcilePage(cursor: string | null): Promise<Response> {
  let config: RCConfig;
  try {
    config = rcConfig();
  } catch (error) {
    console.error(error);
    return json({ error: "not_configured" }, 500);
  }
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  let page: { ids: string[]; next: string | null };
  try {
    page = await listCustomers(config, cursor);
  } catch (error) {
    console.error(error);
    return json({ error: "rc_list_failed" }, 502);
  }

  const repaired: string[] = [];
  const skipped: string[] = [];
  for (const customerId of page.ids) {
    if (!isUuid(customerId)) {
      skipped.push(customerId);
      continue;
    }
    try {
      const userId = customerId.toLowerCase();
      const mirror = await recomputeCustomer(config, userId);
      if (!mirror.has_pro) {
        const { data: existing } = await admin
          .from("profiles")
          .select("subscription_status")
          .eq("id", userId)
          .maybeSingle();
        const current = existing?.subscription_status ?? "free";
        const looksPaid = current === "active" || current === "trialing" || current === "grace_period";
        if (!looksPaid) {
          skipped.push(customerId);
          continue;
        }
      }
      const outcome = await writeMirror(admin, userId, mirror, "reconcile");
      if (outcome === "updated") repaired.push(customerId);
      else skipped.push(customerId);
    } catch (error) {
      console.error("reconcile customer failed", customerId, error);
      skipped.push(customerId);
    }
  }

  return json({
    status: "reconcile_page",
    examined: page.ids.length,
    repaired: repaired.length,
    next: page.next,
  });
}

async function sendFounderEmail(
  admin: ReturnType<typeof createClient>,
  userId: string,
): Promise<string> {
  try {
    const { data: authUser } = await admin.auth.admin.getUserById(userId);
    const userEmail = authUser?.user?.email;
    const firstName = authUser?.user?.user_metadata?.full_name?.split(" ")[0] ?? null;
    if (!userEmail) return "no_email";
    const founderEmailSecret = Deno.env.get("FOUNDER_EMAIL_SECRET");
    if (!founderEmailSecret) return "no_secret";
    const emailRes = await fetch(`${Deno.env.get("SUPABASE_URL")}/functions/v1/founder-email`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${founderEmailSecret}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        user_id: userId,
        email_type: "paid",
        email: userEmail,
        first_name: firstName,
        is_sandbox: false,
      }),
      signal: AbortSignal.timeout(10_000),
    });
    const emailResult = await emailRes.json();
    return emailResult.status ?? "unknown";
  } catch (error) {
    console.error("founder-email trigger failed (non-fatal):", error);
    return "error";
  }
}
