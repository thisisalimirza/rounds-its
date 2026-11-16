// Rounds — my-status edge function (Phase 1)
//
// Returns the signed-in user's referral code, Pro source, and how many of their
// invites are left. Uses the service-role key so the client needs no direct DB
// access or extra RLS policies.
//
// Deploy:  supabase functions deploy my-status

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

  const MAX_REFERRALS = parseInt(Deno.env.get("MAX_REFERRALS") ?? "3", 10);

  const authHeader = req.headers.get("Authorization") ?? "";
  const anon = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: { user }, error: userErr } = await anon.auth.getUser();
  if (userErr || !user) return json({ error: "not_authenticated" }, 401);

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const full = await admin
    .from("profiles")
    .select("referral_code, pro_source, subscription_status, subscription_expires_at")
    .eq("id", user.id)
    .single();

  let profile = full.data;
  if (full.error) {
    const fallback = await admin
      .from("profiles")
      .select("referral_code, pro_source")
      .eq("id", user.id)
      .single();
    profile = fallback.data;
  }

  // is_pro stays "a code was redeemed" so the web, which already reads it,
  // does not change meaning. has_pro is the full definition: a code OR a live
  // subscription, matching profile_has_pro.
  const proSource = profile?.pro_source ?? "none";
  const status = profile?.subscription_status ?? "free";
  const expiresAt = profile?.subscription_expires_at
    ? new Date(profile.subscription_expires_at)
    : null;
  const subscriptionLive = ["active", "trialing", "grace_period"].includes(status)
    && (expiresAt == null || expiresAt.getTime() > Date.now());

  const { count } = await admin
    .from("redemptions")
    .select("id", { count: "exact", head: true })
    .eq("code_owner_id", user.id);

  const invitesUsed = count ?? 0;

  return json({
    referral_code: profile?.referral_code ?? null,
    pro_source: proSource,
    is_pro: proSource !== "none",
    has_pro: proSource !== "none" || subscriptionLive,
    invites_used: invitesUsed,
    invites_remaining: Math.max(0, MAX_REFERRALS - invitesUsed),
    max_referrals: MAX_REFERRALS,
  });
});
