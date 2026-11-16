// Rounds — refresh-pro
//
// Called by the signed-in app after logIn and after a restore.
//
// 1. If the previous (anonymous) id holds a promotional Rounds Pro grant,
//    re-grant it on this id and revoke it on the old one. Restore and
//    syncPurchases cannot move a promotional entitlement.
// 2. Re-read this id from the RevenueCat v2 API and write profiles.subscription_*.
//
// Store purchases are left to the client. The dashboard transfers those when
// syncPurchases runs; this function does not transfer receipts.
//
// Deploy: supabase functions deploy refresh-pro
// Secrets: RC_SECRET_KEY, RC_PROJECT_ID, RC_ENTITLEMENT_ID (same as redeem-code)

import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  customerAccess,
  grantPromotional,
  isUuid,
  rcConfig,
  recomputeCustomer,
  revokePromotional,
} from "../_shared/revenuecat.ts";

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

const FAR_FUTURE_MS = Date.UTC(2099, 0, 1);

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const authHeader = req.headers.get("Authorization") ?? "";
  const anon = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user }, error: userErr } = await anon.auth.getUser();
  if (userErr || !user) return json({ error: "not_authenticated" }, 401);

  let previous: string | null = null;
  try {
    const body = await req.json();
    if (typeof body?.previous_app_user_id === "string") previous = body.previous_app_user_id;
  } catch {
    previous = null;
  }

  let config;
  try {
    config = rcConfig();
  } catch (error) {
    console.error(error);
    return json({ error: "not_configured" }, 500);
  }

  const userId = user.id.toLowerCase();
  let movedPromotional = false;

  if (previous && isUuid(previous) && previous.toLowerCase() !== userId) {
    const oldId = previous.toLowerCase();
    try {
      const access = await customerAccess(config, oldId);
      if (access.active && access.promotional) {
        const expires = access.active.expires_at ?? FAR_FUTURE_MS;
        await grantPromotional(config, userId, expires);
        await revokePromotional(config, oldId);
        movedPromotional = true;
      }
    } catch (error) {
      console.error("promotional move failed", error);
      return json({ error: "promo_move_failed" }, 502);
    }
  }

  let mirror;
  try {
    mirror = await recomputeCustomer(config, userId);
  } catch (error) {
    console.error("recompute failed", error);
    return json({ error: "rc_read_failed" }, 502);
  }

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { error } = await admin.from("profiles").update({
    subscription_status: mirror.subscription_status,
    subscription_will_renew: mirror.subscription_will_renew,
    subscription_product_id: mirror.subscription_product_id,
    subscription_store: mirror.subscription_store,
    subscription_period_type: mirror.subscription_period_type,
    subscription_expires_at: mirror.subscription_expires_at,
    subscription_updated_at: new Date().toISOString(),
  }).eq("id", userId);

  if (error) return json({ error: "update_failed" }, 500);

  const { data: profile } = await admin
    .from("profiles")
    .select("pro_source")
    .eq("id", userId)
    .maybeSingle();
  const codeGrant = (profile?.pro_source ?? "none") !== "none";

  return json({
    status: "ok",
    has_pro: mirror.has_pro || codeGrant,
    moved_promotional: movedPromotional,
  });
});
