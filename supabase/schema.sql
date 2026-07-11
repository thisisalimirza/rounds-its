-- Rounds — referral loop schema (Phase 1)
-- Run this in Supabase: SQL Editor → paste → Run.
-- Safe to re-run: uses IF NOT EXISTS / OR REPLACE throughout.

-- =========================================================================
-- profiles: one row per Supabase auth user (anonymous OR linked to Apple/email).
-- The row id IS the auth user id, and is ALSO the RevenueCat App User ID we
-- pass to Purchases.logIn(...). That single shared id is what makes Pro follow
-- a person across devices and (later) the web.
-- =========================================================================
create table if not exists public.profiles (
    id              uuid primary key references auth.users(id) on delete cascade,
    referral_code   text unique not null,
    referred_by     uuid references public.profiles(id),
    -- how this user got Pro: none | master | referral | purchase
    pro_source      text not null default 'none'
                        check (pro_source in ('none', 'master', 'referral', 'purchase')),
    pro_granted_at  timestamptz,
    created_at      timestamptz not null default now()
);

-- =========================================================================
-- redemptions: one row each time a code is successfully redeemed.
-- redeemer_id is UNIQUE => a given user can only claim one free Pro, ever.
-- code_owner_id is null for the master code; for a referral it's the inviter.
-- A user's remaining invites = 3 - count(rows where code_owner_id = them).
-- =========================================================================
create table if not exists public.redemptions (
    id            uuid primary key default gen_random_uuid(),
    code_used     text not null,
    redeemer_id   uuid not null unique references public.profiles(id) on delete cascade,
    code_owner_id uuid references public.profiles(id) on delete set null,
    created_at    timestamptz not null default now()
);

create index if not exists redemptions_owner_idx on public.redemptions(code_owner_id);

-- =========================================================================
-- Referral code generation: short, unambiguous (no 0/O/1/I), collision-safe.
-- =========================================================================
create or replace function public.generate_referral_code()
returns text
language plpgsql
as $$
declare
    alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    code text;
    i int;
begin
    loop
        code := '';
        for i in 1..6 loop
            code := code || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
        end loop;
        exit when not exists (select 1 from public.profiles where referral_code = code);
    end loop;
    return code;
end;
$$;

-- Auto-create a profile (with a referral code) the moment an auth user is
-- created — including anonymous sign-ins. No client involvement needed.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.profiles (id, referral_code)
    values (new.id, public.generate_referral_code())
    on conflict (id) do nothing;
    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- =========================================================================
-- Row Level Security: users may read/update ONLY their own profile.
-- All cross-user logic (looking up an inviter by code, counting their invites,
-- writing redemptions, granting Pro) happens in the edge function using the
-- service-role key, which bypasses RLS. Clients never see other users' rows.
-- =========================================================================
alter table public.profiles    enable row level security;
alter table public.redemptions enable row level security;

drop policy if exists "read own profile"   on public.profiles;
drop policy if exists "update own profile" on public.profiles;
create policy "read own profile"   on public.profiles for select using (auth.uid() = id);
create policy "update own profile" on public.profiles for update using (auth.uid() = id);

drop policy if exists "read own redemptions" on public.redemptions;
create policy "read own redemptions" on public.redemptions for select using (auth.uid() = redeemer_id);
-- (No client insert policy: only the edge function writes redemptions.)
