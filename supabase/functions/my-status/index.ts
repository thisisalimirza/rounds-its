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

  const { data: profile } = await admin
    .from("profiles").select("referral_code, pro_source").eq("id", user.id).single();

  const { count } = await admin
    .from("redemptions")
    .select("id", { count: "exact", head: true })
    .eq("code_owner_id", user.id);

  const invitesUsed = count ?? 0;

  return json({
    referral_code: profile?.referral_code ?? null,
    pro_source: profile?.pro_source ?? "none",
    is_pro: (profile?.pro_source ?? "none") !== "none",
    invites_used: invitesUsed,
    invites_remaining: Math.max(0, MAX_REFERRALS - invitesUsed),
    max_referrals: MAX_REFERRALS,
  });
});
