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

---

## Founder Emails

Personal emails from Ali sent automatically to:
1. **Paid users** — on first *real* payment from RevenueCat (INITIAL_PURCHASE that is not a free trial, RENEWAL with `is_trial_conversion: true`, or NON_RENEWING_PURCHASE). Trial starts and sandbox events are skipped.
2. **Free users** — when they link an email address to their account

**Email logic:**
- Each user receives at most one email of each type, ever. Skips (no_email, sandbox, dry-run) are not recorded, so they never block a later real send.
- If a user already got the **paid** email, they will NOT receive the free email.
- If a user already got the **free** email and later upgrades, they get a shorter
  "thanks for upgrading" variant of the paid email (same gift card offer).
- If a paying Pro user (subscription_status `active`/`grace_period`, not trial/promotional) links an email for the first time, they get the standard **paid** email instead of the free one. Anonymous buyers who subscribed before linking an email land here.

### Setup Checklist

Follow these steps in order:

#### Step 1: Resend domain verification

1. Sign up at [resend.com](https://resend.com)
2. Go to **Domains** → **Add Domain** → add `getrounds.app`
3. Add the DNS records Resend provides (SPF, DKIM, DMARC)
4. Wait for verification (usually a few minutes)
5. Go to **API Keys** → **Create API Key** → copy the key (`re_...`)

#### Step 2: Set Supabase edge function secrets

Generate a random secret for `FOUNDER_EMAIL_SECRET` (e.g., `openssl rand -hex 32`).

```bash
supabase secrets set RESEND_API_KEY=re_XXXXXXXXXXXXXXXX
supabase secrets set FOUNDER_EMAIL_SECRET=<your-random-secret>
supabase secrets set FOUNDER_EMAIL_FROM="Ali Mirza <ali@getrounds.app>"
supabase secrets set FOUNDER_EMAIL_REPLY_TO="ali@braskgroup.com"
```

**Leave `FOUNDER_EMAIL_ENABLED` unset for dry-run mode.** The function will log
what it would send but won't actually send or record the send. Users will still
receive the real email after you set `FOUNDER_EMAIL_ENABLED=true`.

#### Step 3: Insert Vault secrets for the database trigger

The free-user email trigger runs via a database trigger that calls the edge function
using pg_net. It reads secrets from Supabase Vault.

Run this in the **SQL Editor** (replace `<project-ref>` and `<secret>`):

```sql
-- Insert the edge function URL
INSERT INTO vault.secrets (name, secret)
VALUES ('founder_email_url', 'https://<project-ref>.supabase.co/functions/v1/founder-email')
ON CONFLICT (name) DO UPDATE SET secret = EXCLUDED.secret;

-- Insert the shared auth secret (same value as FOUNDER_EMAIL_SECRET)
INSERT INTO vault.secrets (name, secret)
VALUES ('founder_email_secret', '<your-random-secret>')
ON CONFLICT (name) DO UPDATE SET secret = EXCLUDED.secret;
```

#### Step 4: Apply the database migration

Run the migration in the **SQL Editor**:

```sql
-- Paste contents of: supabase/schema_founder_emails.sql
```

This creates:
- `founder_email_sends` table (idempotency tracking)
- `request_founder_email()` function (reads Vault secrets, calls pg_net)
- `on_founder_email_link` trigger on `auth.users` (fires when email is linked)

#### Step 5: Deploy edge functions

```bash
supabase functions deploy founder-email --no-verify-jwt
supabase functions deploy revenuecat-webhook --no-verify-jwt
```

#### Step 6: Smoke test (dry-run)

Test the founder-email function directly. It will log but not send (dry-run mode):

```bash
curl -X POST "https://<project>.supabase.co/functions/v1/founder-email" \
  -H "Authorization: Bearer <FOUNDER_EMAIL_SECRET>" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"<real-user-uuid>","email_type":"paid"}'
```

**Note:** The function looks up the user's email from `auth.users`, so you must
use a real user_id. The `email` field in the request is ignored.

Check the function logs in Supabase Dashboard → Edge Functions → founder-email → Logs.

#### Step 7: Enable real sends (when ready)

```bash
supabase secrets set FOUNDER_EMAIL_ENABLED=true
```

### Secrets Reference

#### Edge Function Secrets (via `supabase secrets set`)

| Secret | Required | Default | Description |
|--------|----------|---------|-------------|
| `RESEND_API_KEY` | Yes | — | Resend API key (`re_...`) |
| `FOUNDER_EMAIL_SECRET` | Yes | — | Shared secret for authenticating callers |
| `FOUNDER_EMAIL_FROM` | No | `Ali Mirza <ali@getrounds.app>` | From address |
| `FOUNDER_EMAIL_REPLY_TO` | No | `ali@braskgroup.com` | Reply-to (Ali's inbox) |
| `FOUNDER_EMAIL_ENABLED` | No | `false` | Set to `"true"` to send |
| `FOUNDER_EMAIL_SEND_SANDBOX` | No | `false` | Set to `"true"` to send for sandbox/TestFlight |

#### Vault Secrets (via SQL `INSERT INTO vault.secrets`)

| Name | Description |
|------|-------------|
| `founder_email_url` | Full URL to founder-email edge function |
| `founder_email_secret` | Same value as `FOUNDER_EMAIL_SECRET` |

### Alternative: Database Webhook (not recommended)

Instead of the pg_net trigger, you can use a Supabase Database Webhook. However,
this requires manual dashboard configuration and the trigger approach is preferred
since it's fully version-controlled in SQL.

If you do use a Database Webhook:
1. **Disable the trigger first** to avoid double-sends: `DROP TRIGGER on_founder_email_link ON auth.users;`
2. Configure the webhook in Dashboard → Database → Webhooks with the same auth header.

### Monitoring

```sql
-- See all sends (including variant)
SELECT user_id, email_type, variant, recipient_email, sent_at
FROM founder_email_sends ORDER BY sent_at DESC;

-- Stats by type
SELECT * FROM founder_email_stats;

-- Recent sends
SELECT * FROM founder_email_sends 
WHERE sent_at > now() - interval '7 days'
ORDER BY sent_at DESC;
```
