# Rounds — Referral Loop Backend (Phase 1)

This folder is the backend for the viral referral loop: a **master code** everyone
can redeem for free Pro, plus **3 invites per user**. It's built on Supabase and
grants Pro through **RevenueCat**, so Pro follows a person across devices and (later)
the web automatically.

**Phase 1 does NOT touch anyone's local progress.** It only adds identity + entitlements.
Cross-device *progress* sync is a separate Phase 2.

```
supabase/
  schema.sql                    # tables, referral-code generation, RLS
  functions/redeem-code/        # edge function: validate code + grant Pro
  README.md                     # you are here
```

---

## How the whole thing fits together

```
 iOS app  ──(1) silent anonymous sign-in──▶  Supabase Auth  ──trigger──▶  profiles row + referral code
    │                                                                            
    └──(2) Purchases.logIn(supabaseUserId)──▶  RevenueCat  ◀──(4) grant "Rounds Pro"──┐
                                                                                       │
   (3) user enters a code ─────────────────▶  redeem-code edge function ──────────────┘
                                              (checks master / referral, caps at 3,
                                               holds the RevenueCat SECRET key)
```

The Supabase user id is used as **both** the RevenueCat App User ID and the referral
identity. One id, everywhere — that's what makes sync work.

---

## Step 0 — Get RevenueCat sane first (this is the real blocker)

Everything downstream grants the **`Rounds Pro` entitlement**, so that entitlement,
the products, and the offering must exist and be correct. Your app already expects:

| Thing | Expected value (from the app code) |
|---|---|
| Entitlement identifier | `Rounds Pro` (`SubscriptionManager.proEntitlementID`) |
| Product ids | `monthly`, `yearly`, `lifetime` |
| Offering | `default` (its packages are what the paywall shows) |
| Public SDK key (in app) | `appl_…` (already in `SubscriptionManager.swift:37`) |

**"Which paywall is displayed?"** — the app calls `RevenueCatUI.PaywallView()`, which
renders the paywall **attached to the current offering** in the RevenueCat dashboard.
There is no paywall choice in code. To change the paywall: RevenueCat → Paywalls →
edit the one attached to the `default` offering (or change which offering is "current").

Checklist in the RevenueCat dashboard (app.revenuecat.com):

- [ ] Project → your iOS app exists with the **public** key matching the app.
- [ ] **Products**: `monthly`, `yearly`, `lifetime` exist and map to App Store Connect IAPs.
- [ ] **Entitlement** `Rounds Pro` exists and has all three products attached.
- [ ] **Offering** `default` is marked **Current** and contains the packages.
- [ ] **Paywall**: exactly one paywall attached to the `default` offering (this is what shows).
- [ ] Confirm the entitlement **identifier** is literally `Rounds Pro` (not just the display
      name). If it's actually something else (e.g. `pro`), set `RC_ENTITLEMENT_ID` to match
      in Step 3 **and** update `proEntitlementID` in the app.

> Tip: in RevenueCat → Customers you can open any customer and manually **grant a
> promotional entitlement** by hand — no code. That's your zero-code fallback for
> comping an individual while the referral flow is being built.

### Finding a specific person among anonymous customers (the manual-grant problem)

Right now every customer is an anonymous id, so when someone asks you to comp them,
you can't tell which customer they are. The fix is the same identity work as the
referral loop:

- When the app calls `Purchases.logIn(supabaseUserId)`, it also sets the RevenueCat
  **subscriber attributes** `$email` and `$displayName`.
- Then RevenueCat → Customers lets you **search by email** and grant Pro by hand.

So once identity is in, both paths work: self-serve codes *and* manual grant-by-email.

---

## Step 1 — Create the Supabase project

- [ ] Create a project at app.supabase.com. Note the **Project URL** and the **anon**
      public key (Project Settings → API) — the app needs these two (both are safe to ship).
- [ ] Enable **Anonymous sign-ins**: Authentication → Providers → Anonymous → ON.
- [ ] Enable **Apple** provider (for Sign in with Apple linking).
- [ ] Email: Authentication → Providers → Email → enable **magic link**.

## Step 2 — Create the database

- [ ] SQL Editor → paste all of [`schema.sql`](./schema.sql) → Run.

## Step 3 — Deploy the function + set secrets

Install the CLI (`brew install supabase/tap/supabase`), then from the repo root:

```bash
supabase login
supabase link --project-ref <your-project-ref>

# Secrets — the RevenueCat SECRET key lives ONLY here, never in the app.
supabase secrets set RC_SECRET_KEY=sk_XXXXXXXXXXXXXXXX   # V2 secret key
supabase secrets set RC_PROJECT_ID=projXXXXXXXX          # RevenueCat project id
supabase secrets set MASTER_CODE=ROUNDSVIP
supabase secrets set RC_ENTITLEMENT_ID="Rounds Pro"   # the entitlement lookup_key
supabase secrets set RC_GRANT_DURATION=lifetime       # or yearly / monthly / etc.
supabase secrets set MAX_REFERRALS=3

supabase functions deploy redeem-code
```

The function uses **RevenueCat API v2**. You need two values from RevenueCat:
- `RC_SECRET_KEY` — Project Settings → API Keys → a **Secret** key (`sk_…`). This can
  grant entitlements to anyone, so treat it like a password (server-only, never in the app).
- `RC_PROJECT_ID` — your project id (`proj…`); it's in the dashboard URL and in
  Project Settings. This goes in the v2 URL path.

`RC_ENTITLEMENT_ID` must be the entitlement's **lookup_key** (the identifier, e.g.
`Rounds Pro`) — not its internal `entl…` id, or the grant returns 404.

## Step 4 — Smoke test (no app needed)

```bash
# Get a throwaway anonymous JWT, then redeem the master code:
curl -X POST "<PROJECT_URL>/auth/v1/signup" \
  -H "apikey: <ANON_KEY>" -H "Content-Type: application/json" -d '{}'
# (or use the Supabase dashboard to create a user and copy its access token)

curl -X POST "<PROJECT_URL>/functions/v1/redeem-code" \
  -H "Authorization: Bearer <USER_ACCESS_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"code":"ROUNDSVIP"}'
# → {"status":"granted","source":"master"}
```

Then confirm in RevenueCat → Customers that the user now has an active `Rounds Pro`
promotional entitlement.

---

## What the iOS app will do (next, once the above works)

Not built yet — this is the contract the app will target:

1. **Silent anonymous auth** at launch (`supabase.auth.signInAnonymously()`), then
   `Purchases.logIn(session.user.id)`. Everyone gets a durable id with zero friction.
2. **Redeem / Invite UI** (in About/Settings): call `redeem-code`, show "X of 3 invites
   left", share `rounds://invite/{referralCode}`.
3. **Subtle upgrade to a real account** (Sign in with Apple / email magic link) via
   `supabase.auth.linkIdentity(...)` / `updateUser(email:)`. The user id is **unchanged**,
   so RevenueCat, referrals, and (later) progress all carry over — this is the
   non-obstructive anonymous→real conversion.
4. `hasProAccess()` is unchanged — it already reads the `Rounds Pro` entitlement that this
   backend grants. After a redeem, call `refreshCustomerInfo()`.

### Durability note
A user who stays *anonymous only* can lose their account on reinstall (the session lives
on-device). So Pro granted to an anon-only user isn't permanent until they link a real
identity. Recommendation: allow browsing anonymously, but prompt "Sign in to keep your
Pro on all your devices" **at the moment they redeem/invite** — that's where durability
matters and the value exchange justifies the tap.
