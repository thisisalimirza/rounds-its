// Rounds — redeem-code edge function (Phase 1)
//
// Validates a code for the signed-in user, records the redemption, and grants
// the "Rounds Pro" entitlement via RevenueCat's REST API. RevenueCat then
// propagates Pro to every device + the web for that App User ID.
//
// Deploy:  supabase functions deploy redeem-code
// Secrets (supabase secrets set ...):
//   RC_SECRET_KEY        RevenueCat SECRET (v1) key — sk_...  NEVER ship in the app
//   RC_ENTITLEMENT_ID    entitlement identifier (default "Rounds Pro")
//   RC_GRANT_DURATION    promotional duration (default "lifetime")
//   MASTER_CODE          the everyone-gets-it code
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

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const RC_SECRET_KEY = Deno.env.get("RC_SECRET_KEY")!;          // V2 secret key (sk_...)
  const RC_PROJECT_ID = Deno.env.get("RC_PROJECT_ID")!;         // RevenueCat project id (proj...)
  const RC_ENTITLEMENT_ID = Deno.env.get("RC_ENTITLEMENT_ID") ?? "Rounds Pro"; // entitlement lookup_key
  const RC_GRANT_DURATION = Deno.env.get("RC_GRANT_DURATION") ?? "lifetime";
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

  // Service-role client bypasses RLS for the cross-user checks below.
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Already has Pro? Nothing to do.
  const { data: me } = await admin
    .from("profiles").select("id, pro_source").eq("id", user.id).single();
  if (me && me.pro_source !== "none") return json({ status: "already_pro" });

  // Resolve the code -> owner (null for the master code).
  let ownerId: string | null = null;
  let source: "master" | "referral";

  if (MASTER_CODE && code === MASTER_CODE) {
    source = "master";
  } else {
    const { data: owner } = await admin
      .from("profiles").select("id").eq("referral_code", code).maybeSingle();
    if (!owner) return json({ status: "invalid_code" });
    if (owner.id === user.id) return json({ status: "own_code" });

    const { count } = await admin
      .from("redemptions")
      .select("id", { count: "exact", head: true })
      .eq("code_owner_id", owner.id);
    if ((count ?? 0) >= MAX_REFERRALS) return json({ status: "code_exhausted" });

    ownerId = owner.id;
    source = "referral";
  }

  // Record the redemption. The UNIQUE(redeemer_id) constraint makes this the
  // race-safe gate against double-claims.
  const { error: insErr } = await admin.from("redemptions").insert({
    code_used: code,
    redeemer_id: user.id,
    code_owner_id: ownerId,
  });
  if (insErr) {
    if (insErr.code === "23505") return json({ status: "already_pro" }); // already redeemed
    return json({ error: "redeem_failed", detail: insErr.message }, 500);
  }

  // Grant the entitlement in RevenueCat (source of truth for Pro) via API v2.
  const rcBase = `https://api.revenuecat.com/v2/projects/${RC_PROJECT_ID}`;
  const rcHeaders = {
    "Authorization": `Bearer ${RC_SECRET_KEY}`,
    "Content-Type": "application/json",
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

  const rollback = async (detail: string) => {
    await admin.from("redemptions").delete().eq("redeemer_id", user.id);
    return json({ error: "grant_failed", detail }, 502);
  };

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
  // "lifetime", so we use a far-future date to mean effectively permanent.
  const LIFETIME_MS = 4102444800000; // 2100-01-01, effectively permanent
  const expiresAt = LIFETIME_MS; // RC_GRANT_DURATION is "lifetime"; v2 needs a concrete date
  const grantRes = await fetch(
    `${rcBase}/customers/${encodeURIComponent(user.id)}/actions/grant_entitlement`,
    {
      method: "POST",
      headers: rcHeaders,
      body: JSON.stringify({ entitlement_id: entitlement.id, expires_at: expiresAt }),
    },
  );
  if (!grantRes.ok) return await rollback(await grantRes.text());

  await admin.from("profiles").update({
    pro_source: source,
    pro_granted_at: new Date().toISOString(),
    referred_by: ownerId,
  }).eq("id", user.id);

  return json({ status: "granted", source });
});
