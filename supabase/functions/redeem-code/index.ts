// Rounds — redeem-code edge function
//
// Validates a code for the signed-in user, records the redemption, and grants
// the "Rounds Pro" entitlement via RevenueCat's REST API. RevenueCat then
// propagates Pro to every device + the web for that App User ID.
//
// Handles three kinds of code, resolved in this order by public.claim_code():
//   1. campaign / promo codes  (public.promo_codes — influencer codes, master)
//   2. per-user referral codes (public.profiles.referral_code)
//
// All validation, quota enforcement and the redemption insert happen inside
// public.claim_code(), which locks the promo_codes row FOR UPDATE. This is
// deliberate: the previous implementation did check-then-insert across separate
// round trips, so two concurrent redemptions of a code with one slot left could
// both pass the quota check before either inserted. Do not reintroduce quota
// checks here.
//
// Deploy:  supabase functions deploy redeem-code
// Secrets (supabase secrets set ...):
//   RC_SECRET_KEY        RevenueCat SECRET (v2) key — sk_...  NEVER ship in the app
//   RC_PROJECT_ID        RevenueCat project id (proj...)
//   RC_ENTITLEMENT_ID    entitlement lookup_key (default "Rounds Pro")
//   MASTER_CODE          legacy everyone-gets-it code (optional; prefer a
//                        kind='master' row in promo_codes instead)
//   MAX_REFERRALS        invites allowed per user (default "3")
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically.

import { createClient } from "jsr:@supabase/supabase-js@2";

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

/** Statuses claim_code() can return that are user-facing refusals, not errors. */
const REFUSALS = new Set([
  "invalid_code",
  "already_pro",
  "own_code",
  "code_exhausted",
  "code_inactive",
  "code_expired",
  "code_not_started",
]);

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const RC_SECRET_KEY = Deno.env.get("RC_SECRET_KEY")!;
  const RC_PROJECT_ID = Deno.env.get("RC_PROJECT_ID")!;
  const RC_ENTITLEMENT_ID = Deno.env.get("RC_ENTITLEMENT_ID") ?? "Rounds Pro";
  const MASTER_CODE = (Deno.env.get("MASTER_CODE") ?? "").toUpperCase();
  const MAX_REFERRALS = parseInt(Deno.env.get("MAX_REFERRALS") ?? "3", 10);

  // Identify the caller from their JWT.
  const authHeader = req.headers.get("Authorization") ?? "";
  const anon = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user }, error: userErr } = await anon.auth.getUser();
  if (userErr || !user) return json({ error: "not_authenticated" }, 401);

  let code = "";
  try {
    code = ((await req.json())?.code ?? "").toString().trim().toUpperCase();
  } catch { /* empty body */ }
  if (!code) return json({ status: "missing_code" });

  // Service-role client bypasses RLS; claim_code is SECURITY DEFINER and is not
  // callable by anon/authenticated roles.
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Legacy fallback: if MASTER_CODE is still only an env var and hasn't been
  // migrated into promo_codes yet, materialize it on first use so claim_code
  // can resolve it like any other code. Safe to run repeatedly.
  if (MASTER_CODE && code === MASTER_CODE) {
    await admin.from("promo_codes").upsert(
      {
        code: MASTER_CODE,
        kind: "master",
        grant_duration: "lifetime",
        max_redemptions: null,
        notes: "Auto-migrated from MASTER_CODE env var",
      },
      { onConflict: "code", ignoreDuplicates: true },
    );
  }

  // ---------------------------------------------------------------------
  // Claim. One atomic call: validates, enforces quota, inserts redemption.
  // ---------------------------------------------------------------------
  const { data: claim, error: claimErr } = await admin.rpc("claim_code", {
    p_code: code,
    p_user: user.id,
    p_max_referrals: MAX_REFERRALS,
  });

  if (claimErr) {
    return json({ error: "redeem_failed", detail: claimErr.message }, 500);
  }

  const status = claim?.status as string | undefined;
  if (!status) return json({ error: "redeem_failed", detail: "no status" }, 500);
  if (REFUSALS.has(status)) return json({ status });
  if (status !== "claimed") {
    return json({ error: "redeem_failed", detail: status }, 500);
  }

  const source: string = claim.source;
  const campaignId: string | null = claim.campaign_id ?? null;
  const ownerId: string | null = claim.owner_id ?? null;
  const expiresAtMs = new Date(claim.expires_at).getTime();

  // ---------------------------------------------------------------------
  // Grant the entitlement in RevenueCat (source of truth for Pro), API v2.
  // ---------------------------------------------------------------------
  const rcBase = `https://api.revenuecat.com/v2/projects/${RC_PROJECT_ID}`;
  const rcHeaders = {
    "Authorization": `Bearer ${RC_SECRET_KEY}`,
    "Content-Type": "application/json",
  };

  // Roll the claim back so the code isn't burned and the user can retry.
  const rollback = async (detail: string) => {
    await admin.rpc("release_code", { p_user: user.id });
    return json({ error: "grant_failed", detail }, 502);
  };

  // Ensure the customer exists first — a user who hasn't opened the app since
  // logIn won't be a RevenueCat customer yet, and v2 grant does not auto-create.
  // 201 (created) and 409/422 (already exists) are all fine; only a network
  // failure matters, which the grant call below will surface anyway.
  await fetch(`${rcBase}/customers`, {
    method: "POST",
    headers: rcHeaders,
    body: JSON.stringify({ id: user.id }),
  });

  // v2 grants by the entitlement's internal id (entl...), not its lookup_key.
  // Resolve the id from the lookup_key so nothing is hard-coded.
  const listRes = await fetch(`${rcBase}/entitlements`, { headers: rcHeaders });
  if (!listRes.ok) return await rollback("list_entitlements: " + await listRes.text());
  const list = await listRes.json();
  const entitlement = (list.items ?? []).find(
    (e: { lookup_key?: string }) => e.lookup_key === RC_ENTITLEMENT_ID,
  );
  if (!entitlement) {
    const available = (list.items ?? []).map((e: { lookup_key?: string }) => e.lookup_key);
    return await rollback(
      `no entitlement with lookup_key "${RC_ENTITLEMENT_ID}". available: ${JSON.stringify(available)}`,
    );
  }

  // expires_at (ms epoch) is required and non-nullable — v2 has no true
  // "lifetime", so claim_code resolves lifetime to a far-future date.
  const grantRes = await fetch(
    `${rcBase}/customers/${encodeURIComponent(user.id)}/actions/grant_entitlement`,
    {
      method: "POST",
      headers: rcHeaders,
      body: JSON.stringify({ entitlement_id: entitlement.id, expires_at: expiresAtMs }),
    },
  );
  if (!grantRes.ok) return await rollback(await grantRes.text());

  // ---------------------------------------------------------------------
  // Campaign attribution. Best-effort: the entitlement is already granted, so
  // an attribution failure must never fail the redemption or roll it back.
  // The authoritative attribution record is the redemptions row written by
  // claim_code; this mirrors it into RevenueCat so campaign shows up in RC's
  // own revenue reporting alongside the subscription data.
  // ---------------------------------------------------------------------
  let campaignSlug: string | null = null;

  if (campaignId) {
    try {
      const { data: campaign } = await admin
        .from("campaigns")
        .select("slug, kind, creator_handle")
        .eq("id", campaignId)
        .maybeSingle();

      if (campaign) {
        campaignSlug = campaign.slug;
        await fetch(
          `${rcBase}/customers/${encodeURIComponent(user.id)}/attributes`,
          {
            method: "POST",
            headers: rcHeaders,
            body: JSON.stringify({
              attributes: [
                { name: "$campaign", value: campaign.slug },
                { name: "$mediaSource", value: campaign.kind },
                ...(campaign.creator_handle
                  ? [{ name: "$creative", value: campaign.creator_handle }]
                  : []),
              ],
            }),
          },
        );
      }

      // Attribute the profile too, so a user who redeems a campaign code is
      // counted in campaign_performance even before any purchase.
      await admin.from("profiles").update({
        attributed_campaign_id: campaignId,
        attribution_source: "promo_code",
        attribution_set_at: new Date().toISOString(),
      }).eq("id", user.id);
    } catch (e) {
      console.error("attribution failed (non-fatal):", e);
    }
  }

  await admin.from("profiles").update({
    pro_source: source,
    pro_granted_at: new Date().toISOString(),
    referred_by: ownerId,
  }).eq("id", user.id);

  return json({
    status: "granted",
    source,
    campaign_id: campaignId,
    // Human-readable campaign identifier. The client mirrors this into the
    // RevenueCat SDK and PostHog so all three systems agree on one label.
    campaign_slug: campaignSlug,
    grant_duration: claim.grant_duration,
    expires_at: claim.expires_at,
  });
});
