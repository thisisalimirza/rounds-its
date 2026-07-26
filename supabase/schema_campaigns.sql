-- Rounds — campaigns & promo codes (Phase 1: influencer marketing)
-- Run this in Supabase: SQL Editor → paste → Run.
-- Safe to re-run: uses IF NOT EXISTS / OR REPLACE throughout.
--
-- Extends the Phase 1 referral loop (schema.sql) with first-class marketing
-- campaigns. The existing per-user `profiles.referral_code` flow is untouched;
-- this adds a separate namespace of codes that belong to a campaign rather than
-- to a user, so an influencer can hand out "SARAH" to their whole audience.
--
-- Reporting model:
--   campaigns      — one row per influencer / channel / partnership
--   promo_codes    — redeemable codes, optionally owned by a campaign
--   redemptions    — extended with promo_code_id + campaign_id for attribution
--   profiles       — extended with attributed_campaign_id, so users who arrive
--                    via a campaign link are attributable even if they never
--                    redeem a code and simply subscribe at full price.

-- =========================================================================
-- campaigns
-- =========================================================================
create table if not exists public.campaigns (
    id                  uuid primary key default gen_random_uuid(),
    -- URL-safe identifier used by the website smart link: getrounds.app/r/<slug>
    slug                text unique not null,
    name                text not null,
    kind                text not null default 'influencer'
                            check (kind in ('influencer', 'partnership', 'paid', 'organic', 'internal')),

    -- Creator contact / display info (all optional)
    creator_name        text,
    creator_handle      text,
    creator_email       text,
    creator_platform    text,

    -- App Store Connect Campaign Link token, so ASC install numbers can be
    -- reconciled against in-app redemptions for the same campaign.
    asc_campaign_token  text,

    -- Deal terms, for the admin console. Purely informational.
    revenue_share_pct   numeric(5,2) check (revenue_share_pct is null
                                            or (revenue_share_pct >= 0 and revenue_share_pct <= 100)),
    flat_fee_cents      integer check (flat_fee_cents is null or flat_fee_cents >= 0),

    notes               text,
    is_active           boolean not null default true,
    starts_at           timestamptz,
    ends_at             timestamptz,
    created_at          timestamptz not null default now(),
    archived_at         timestamptz
);

create index if not exists campaigns_active_idx on public.campaigns(is_active) where archived_at is null;

-- =========================================================================
-- promo_codes
--
-- A code is valid when: is_active, now() within [starts_at, expires_at], and
-- redemption_count < max_redemptions (null max = unlimited).
--
-- `redemption_count` is denormalized and maintained inside claim_code() under a
-- row lock — never write it from application code.
-- =========================================================================
create table if not exists public.promo_codes (
    id                uuid primary key default gen_random_uuid(),
    -- Always stored uppercase; claim_code() uppercases input before lookup.
    code              text unique not null check (code = upper(code) and length(code) between 3 and 32),
    campaign_id       uuid references public.campaigns(id) on delete set null,

    kind              text not null default 'campaign'
                          check (kind in ('campaign', 'master', 'manual', 'press')),

    -- How much Pro a successful redemption grants.
    grant_duration    text not null default 'lifetime'
                          check (grant_duration in ('lifetime', 'year', 'six_month',
                                                    'three_month', 'month', 'week')),

    max_redemptions   integer check (max_redemptions is null or max_redemptions > 0),
    redemption_count  integer not null default 0,

    starts_at         timestamptz,
    expires_at        timestamptz,
    is_active         boolean not null default true,

    notes             text,
    created_by        uuid references public.profiles(id) on delete set null,
    created_at        timestamptz not null default now()
);

create index if not exists promo_codes_campaign_idx on public.promo_codes(campaign_id);

-- =========================================================================
-- Extend existing tables. All additive + idempotent.
-- =========================================================================

-- redemptions: record which promo code / campaign produced this redemption.
alter table public.redemptions add column if not exists promo_code_id  uuid references public.promo_codes(id) on delete set null;
alter table public.redemptions add column if not exists campaign_id    uuid references public.campaigns(id) on delete set null;
alter table public.redemptions add column if not exists source         text;
alter table public.redemptions add column if not exists grant_duration text;
alter table public.redemptions add column if not exists grant_expires_at timestamptz;

create index if not exists redemptions_campaign_idx on public.redemptions(campaign_id);
create index if not exists redemptions_promo_code_idx on public.redemptions(promo_code_id);

-- profiles: campaign attribution for users who arrive via a link but never
-- redeem a code (they just subscribe). Set from the smart-link handoff.
alter table public.profiles add column if not exists attributed_campaign_id uuid references public.campaigns(id) on delete set null;
alter table public.profiles add column if not exists attribution_source     text;
alter table public.profiles add column if not exists attribution_set_at     timestamptz;

create index if not exists profiles_attributed_campaign_idx on public.profiles(attributed_campaign_id);

-- profiles: role, used by the web admin console to gate /admin.
alter table public.profiles add column if not exists role text not null default 'user';

do $$
begin
    if not exists (
        select 1 from pg_constraint where conname = 'profiles_role_check'
    ) then
        alter table public.profiles
            add constraint profiles_role_check check (role in ('user', 'admin', 'owner'));
    end if;
end
$$;

-- pro_source needs a 'campaign' value now. Recreate the check constraint.
do $$
declare
    conname_found text;
begin
    select conname into conname_found
      from pg_constraint
     where conrelid = 'public.profiles'::regclass
       and contype = 'c'
       and pg_get_constraintdef(oid) ilike '%pro_source%';

    if conname_found is not null then
        execute format('alter table public.profiles drop constraint %I', conname_found);
    end if;

    alter table public.profiles
        add constraint profiles_pro_source_check
        check (pro_source in ('none', 'master', 'referral', 'purchase', 'campaign'));
end
$$;

-- =========================================================================
-- Maps a grant_duration to a concrete timestamp. RevenueCat v2 has no true
-- "lifetime", so lifetime resolves to a far-future date.
-- Defined before claim_code(), which calls it.
-- =========================================================================
create or replace function public.grant_expiry(p_duration text)
returns timestamptz
language sql
stable
as $$
    select case p_duration
        when 'week'        then now() + interval '7 days'
        when 'month'       then now() + interval '1 month'
        when 'three_month' then now() + interval '3 months'
        when 'six_month'   then now() + interval '6 months'
        when 'year'        then now() + interval '1 year'
        else timestamptz '2100-01-01 00:00:00+00'
    end;
$$;

-- =========================================================================
-- claim_code(): the single race-safe entry point for redeeming ANY code.
--
-- Replaces the previous check-then-insert sequence in the edge function, which
-- could let two concurrent requests both pass a quota check before either
-- inserted. Here the promo_codes row is locked FOR UPDATE, so the quota check
-- and the counter increment happen in one atomic step.
--
-- Resolution order: promo/campaign code → per-user referral code.
-- The caller (edge function) is responsible for the RevenueCat grant, and calls
-- release_code() to roll back if that grant fails.
--
-- Returns jsonb: { status, source?, campaign_id?, grant_duration?, expires_at? }
--   status ∈ invalid_code | already_pro | own_code | code_exhausted
--          | code_inactive | code_not_started | code_expired | claimed
-- =========================================================================
create or replace function public.claim_code(
    p_code          text,
    p_user          uuid,
    p_max_referrals integer default 3
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
    v_code      text := upper(trim(p_code));
    v_promo     public.promo_codes%rowtype;
    v_owner_id  uuid;
    v_source    text;
    v_campaign  uuid;
    v_duration  text;
    v_expires   timestamptz;
    v_used      integer;
begin
    if v_code is null or v_code = '' then
        return jsonb_build_object('status', 'invalid_code');
    end if;

    -- A user gets exactly one free Pro, ever.
    if exists (select 1 from public.profiles where id = p_user and pro_source <> 'none') then
        return jsonb_build_object('status', 'already_pro');
    end if;
    if exists (select 1 from public.redemptions where redeemer_id = p_user) then
        return jsonb_build_object('status', 'already_pro');
    end if;

    -- ---------------------------------------------------------------
    -- 1) Campaign / promo code. Locked so quota is enforced atomically.
    -- ---------------------------------------------------------------
    select * into v_promo from public.promo_codes where code = v_code for update;

    if found then
        if not v_promo.is_active then
            return jsonb_build_object('status', 'code_inactive');
        end if;
        if v_promo.starts_at is not null and now() < v_promo.starts_at then
            return jsonb_build_object('status', 'code_not_started');
        end if;
        if v_promo.expires_at is not null and now() > v_promo.expires_at then
            return jsonb_build_object('status', 'code_expired');
        end if;
        if v_promo.max_redemptions is not null
           and v_promo.redemption_count >= v_promo.max_redemptions then
            return jsonb_build_object('status', 'code_exhausted');
        end if;

        v_source   := case when v_promo.kind = 'master' then 'master' else 'campaign' end;
        v_campaign := v_promo.campaign_id;
        v_duration := v_promo.grant_duration;

        update public.promo_codes
           set redemption_count = redemption_count + 1
         where id = v_promo.id;

    else
        -- ---------------------------------------------------------------
        -- 2) Per-user referral code (unchanged legacy behaviour).
        -- ---------------------------------------------------------------
        select id into v_owner_id from public.profiles where referral_code = v_code;
        if v_owner_id is null then
            return jsonb_build_object('status', 'invalid_code');
        end if;
        if v_owner_id = p_user then
            return jsonb_build_object('status', 'own_code');
        end if;

        select count(*) into v_used
          from public.redemptions where code_owner_id = v_owner_id;
        if v_used >= p_max_referrals then
            return jsonb_build_object('status', 'code_exhausted');
        end if;

        v_source   := 'referral';
        v_duration := 'lifetime';
    end if;

    v_expires := public.grant_expiry(v_duration);

    -- UNIQUE(redeemer_id) is the final race-safe gate against double-claims.
    insert into public.redemptions (
        code_used, redeemer_id, code_owner_id,
        promo_code_id, campaign_id, source, grant_duration, grant_expires_at
    ) values (
        v_code, p_user, v_owner_id,
        v_promo.id, v_campaign, v_source, v_duration, v_expires
    );

    return jsonb_build_object(
        'status',         'claimed',
        'source',         v_source,
        'campaign_id',    v_campaign,
        'promo_code_id',  v_promo.id,
        'owner_id',       v_owner_id,
        'grant_duration', v_duration,
        'expires_at',     v_expires
    );
exception
    when unique_violation then
        return jsonb_build_object('status', 'already_pro');
end;
$$;

-- Undo a claim when the downstream RevenueCat grant fails, so the code isn't
-- silently burned and the user can retry.
create or replace function public.release_code(p_user uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_promo uuid;
begin
    select promo_code_id into v_promo
      from public.redemptions where redeemer_id = p_user;

    delete from public.redemptions where redeemer_id = p_user;

    if v_promo is not null then
        update public.promo_codes
           set redemption_count = greatest(redemption_count - 1, 0)
         where id = v_promo;
    end if;
end;
$$;

-- =========================================================================
-- Reporting view for the admin console.
-- =========================================================================
-- Scalar subqueries rather than joins: joining promo_codes, redemptions and
-- profiles to campaigns simultaneously produces a cartesian fan-out that would
-- multiply the sum() columns by the row counts of the other branches.
create or replace view public.campaign_performance as
select
    c.id,
    c.slug,
    c.name,
    c.kind,
    c.creator_handle,
    c.is_active,
    c.created_at,

    (select count(*) from public.promo_codes pc
      where pc.campaign_id = c.id)                       as code_count,

    (select coalesce(sum(pc.redemption_count), 0) from public.promo_codes pc
      where pc.campaign_id = c.id)                       as codes_used,

    -- null max_redemptions means unlimited; reported as null rather than 0 so
    -- the console can distinguish "unlimited" from "quota of zero".
    (select case when bool_or(pc.max_redemptions is null) then null
                 else sum(pc.max_redemptions) end
       from public.promo_codes pc
      where pc.campaign_id = c.id)                       as total_quota,

    (select count(*) from public.redemptions r
      where r.campaign_id = c.id)                        as redemptions,

    (select count(*) from public.profiles p
      where p.attributed_campaign_id = c.id)             as attributed_users,

    (select count(*) from public.profiles p
      where p.attributed_campaign_id = c.id
        and p.pro_source = 'purchase')                   as paid_conversions

from public.campaigns c;

-- =========================================================================
-- Row Level Security
--
-- campaigns / promo_codes hold business data (deal terms, quotas) and are NOT
-- readable by app users. All access goes through the service role: the edge
-- function for redemption, the admin console for management.
-- =========================================================================
alter table public.campaigns   enable row level security;
alter table public.promo_codes enable row level security;

-- No policies == no client access under RLS. Service role bypasses RLS.
-- Declared explicitly so a future "enable read for all" is a deliberate act.

revoke all on public.campaigns   from anon, authenticated;
revoke all on public.promo_codes from anon, authenticated;
revoke all on public.campaign_performance from anon, authenticated;

-- claim_code / release_code are SECURITY DEFINER and must only ever be invoked
-- by the edge function under the service role, never directly by a client.
revoke all on function public.claim_code(text, uuid, integer)  from anon, authenticated;
revoke all on function public.release_code(uuid)               from anon, authenticated;

-- =========================================================================
-- Seed: migrate the env-var MASTER_CODE into promo_codes.
-- Replace 'ROUNDSVIP' with the value currently in the MASTER_CODE secret.
-- Kept commented so running this file never silently creates a live code.
-- =========================================================================
-- insert into public.promo_codes (code, kind, grant_duration, max_redemptions, notes)
-- values ('ROUNDSVIP', 'master', 'lifetime', null, 'Migrated from MASTER_CODE env var')
-- on conflict (code) do nothing;
