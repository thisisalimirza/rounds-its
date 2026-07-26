# Applying the campaigns migration to production

Target project: **rounds-ios** (`gvbycponexvxsbrlaejw`), Postgres 17.

There are live users in this database (27 profiles, 5 redemptions at the time of
writing). Everything below is additive — no table is dropped, no column is
removed, no row is deleted or rewritten. The one non-additive step recreates a
CHECK constraint, covered in step 1.

Run the steps in order, in the Supabase SQL Editor.

---

## Step 1 — Pre-flight (read-only, run this first)

Confirms nothing in the existing data will violate the new constraint. Both
counts must come back `0`.

```sql
-- Any pro_source value the new constraint wouldn't accept?
select count(*) as bad_pro_source
from public.profiles
where pro_source not in ('none','master','referral','purchase','campaign');

-- Any duplicate referral codes that would collide with a promo code?
select count(*) as blank_referral_codes
from public.profiles
where referral_code is null or referral_code = '';
```

If `bad_pro_source` is not 0, stop and fix those rows first — the migration
would fail on `ADD CONSTRAINT` and roll back (safe, but it won't apply).

The constraint change itself is a superset: it adds `'campaign'` to the allowed
values and keeps all four existing ones, so every current row stays valid.

---

## Step 2 — Apply the schema

Paste the entire contents of `supabase/schema_campaigns.sql` and run it.

It is idempotent (`if not exists` / `or replace` throughout), so re-running is
safe if you're unsure whether it completed.

What it creates:

| Object | Purpose |
|---|---|
| `campaigns` | one row per influencer / channel |
| `promo_codes` | redeemable codes owned by a campaign |
| `claim_code()` | race-safe redemption, replaces the edge function's check-then-insert |
| `release_code()` | unwinds a claim when the RevenueCat grant fails |
| `grant_expiry()` | maps a grant duration to a timestamp |
| `campaign_performance` | reporting view for the admin console |

It also adds columns to `profiles` (`attributed_campaign_id`,
`attribution_source`, `attribution_set_at`, `role`) and to `redemptions`
(`promo_code_id`, `campaign_id`, `source`, `grant_duration`,
`grant_expires_at`). All nullable, all `if not exists`.

---

## Step 3 — Verify the privilege lockdown

`claim_code` and `release_code` are `SECURITY DEFINER` and take the target user
as a **parameter**, so they must not be reachable by clients. Postgres grants
`EXECUTE` on new functions to `PUBLIC` by default, so this is worth confirming
rather than assuming.

All three rows must read `f | f | t`:

```sql
select
  p.proname,
  has_function_privilege('authenticated', p.oid, 'EXECUTE') as authed,
  has_function_privilege('anon',          p.oid, 'EXECUTE') as anon,
  has_function_privilege('service_role',  p.oid, 'EXECUTE') as service
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('claim_code','release_code','grant_expiry')
order by p.proname;
```

And the campaign tables must not be client-readable — both columns `f`:

```sql
select c.relname,
  has_table_privilege('authenticated', c.oid, 'SELECT') as authed,
  has_table_privilege('anon',          c.oid, 'SELECT') as anon
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in ('campaigns','promo_codes','campaign_performance');
```

---

## Step 4 — Grant yourself admin

Nothing gates `/admin` until a profile carries an elevated role, and no row has
one yet. This looks the user up by email so there's no id to copy by hand.

```sql
update public.profiles
   set role = 'owner'
 where id = (select id from auth.users where email = 'alimirzar@gmail.com');

-- Confirm exactly one row came back with role = 'owner'
select u.email, p.role
  from public.profiles p
  join auth.users u on u.id = p.id
 where p.role in ('admin','owner');
```

If that returns no rows, the email on the auth user differs — find it with
`select id, email from auth.users order by created_at limit 20;` and rerun.

---

## Step 5 — Migrate the master code

The edge function still honours the `MASTER_CODE` secret and will auto-create a
matching `promo_codes` row the first time someone redeems it. Doing it
explicitly is cleaner. Replace the placeholder with your actual value:

```sql
insert into public.promo_codes (code, kind, grant_duration, max_redemptions, notes)
values ('YOUR_MASTER_CODE_HERE', 'master', 'lifetime', null, 'Migrated from MASTER_CODE env var')
on conflict (code) do nothing;
```

---

## Step 6 — Redeploy the edge function

**Required.** The committed `redeem-code` calls `claim_code`, which did not
exist before step 2. Until this deploy runs, redemptions use the old code path.

```bash
npm install -g supabase          # if you don't have the CLI
supabase login
supabase link --project-ref gvbycponexvxsbrlaejw
supabase functions deploy redeem-code
```

Confirm the secrets it needs are set:

```bash
supabase secrets list
```

It expects `RC_SECRET_KEY`, `RC_PROJECT_ID` (`projcd18207a`),
`RC_ENTITLEMENT_ID` (`Rounds Pro`), and optionally `MASTER_CODE` /
`MAX_REFERRALS`.

---

## Step 7 — Smoke test

In the admin console (`/admin/campaigns`), create a campaign and a code with
`max_redemptions = 1`, then redeem it from a test account in the app. Expect:

- first redemption succeeds and grants Pro
- `promo_codes.redemption_count` becomes 1
- a second account gets "That code has been fully claimed."
- the campaign row in `/admin` shows 1 redemption

---

## Rollback

Nothing here modifies existing data, so rollback is just dropping the new
objects. Only do this if the migration needs to be reverted entirely:

```sql
drop view if exists public.campaign_performance;
drop function if exists public.claim_code(text, uuid, integer);
drop function if exists public.release_code(uuid);
drop function if exists public.grant_expiry(text);
drop table if exists public.promo_codes cascade;
drop table if exists public.campaigns cascade;
-- The added columns on profiles/redemptions are nullable and harmless; leave
-- them unless you have a reason to drop them.
```

Note the edge function must be rolled back to its previous revision at the same
time, since it depends on `claim_code`.
