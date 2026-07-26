-- Rounds — admin allowlist + security hardening
-- Applied to production as migrations `admin_email_allowlist` and
-- `harden_security_definer_functions`. Kept here so the repo matches the
-- database. Safe to re-run.

-- =========================================================================
-- Admin bootstrap by email allowlist.
--
-- Every auth user was anonymous when this was written (0 of 28 had linked an
-- email), so there was no row to grant a role to. Rather than hand-granting
-- after each sign-in, an allowlist assigns the role automatically the moment a
-- matching email appears on an auth user.
--
-- Two paths have to be covered, and they differ:
--   * web magic-link sign-in INSERTs a new auth.users row that already has the
--     email set;
--   * the iOS app's AccountManager.linkEmail() UPDATEs an existing anonymous
--     row to add an email.
-- Hence the trigger fires on INSERT OR UPDATE OF email.
-- =========================================================================
create table if not exists public.admin_emails (
    email      text primary key check (email = lower(email)),
    role       text not null default 'admin' check (role in ('admin', 'owner')),
    note       text,
    created_at timestamptz not null default now()
);

alter table public.admin_emails enable row level security;
revoke all on public.admin_emails from public, anon, authenticated;

create or replace function public.sync_admin_role()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    v_role text;
begin
    if new.email is null then
        return new;
    end if;

    select role into v_role
      from public.admin_emails
     where email = lower(new.email);

    if v_role is not null then
        -- The profile row is created by handle_new_user() on the same INSERT.
        -- On the insert path this UPDATE may find nothing if trigger order puts
        -- us first, so upsert defensively rather than relying on ordering.
        insert into public.profiles (id, referral_code, role)
        values (new.id, public.generate_referral_code(), v_role)
        on conflict (id) do update set role = excluded.role;
    end if;

    return new;
end;
$$;

drop trigger if exists on_auth_user_admin_sync on auth.users;
create trigger on_auth_user_admin_sync
    after insert or update of email on auth.users
    for each row execute function public.sync_admin_role();

revoke all on function public.sync_admin_role() from public, anon, authenticated;

-- Seed. Add teammates here; they get the role on their next sign-in.
insert into public.admin_emails (email, role, note)
values ('alimirzar@gmail.com', 'owner', 'Founder — bootstrap owner')
on conflict (email) do update set role = excluded.role;

-- =========================================================================
-- Security hardening (flagged by the Supabase database linter).
--
-- 1) Pin search_path. For a SECURITY DEFINER function a mutable search_path is
--    an injection vector: a caller can prepend a schema and shadow the tables
--    the function references, running their own code with the definer's
--    privileges. grant_expiry is only STABLE, but it is called from inside
--    claim_code (SECURITY DEFINER), so it gets pinned too.
--
-- 2) Revoke client EXECUTE on SECURITY DEFINER functions no client should
--    reach. Supabase exposes every public function at /rest/v1/rpc/<name> and
--    Postgres grants EXECUTE to PUBLIC by default, so these were reachable by
--    anon over HTTP.
--
--    Safe because:
--      * handle_new_user and sync_feature_vote_counts are trigger functions.
--        Triggers are invoked by the executor as the table owner and do not
--        consult the caller's EXECUTE privilege — verified in production that
--        profile creation and referral-code generation still work after the
--        revoke.
--      * resolve_illness_fuzzy and bump_illness_counters are only ever called
--        as admin.rpc(...) from the illness-script edge function under the
--        service-role key. No app client calls them directly.
-- =========================================================================
alter function public.grant_expiry(text)                           set search_path = public;
alter function public.generate_referral_code()                     set search_path = public;
alter function public.sync_feature_vote_counts()                   set search_path = public;
alter function public.bump_illness_counters(text, boolean)         set search_path = public;
alter function public.resolve_illness_fuzzy(text, real)            set search_path = public;

revoke all on function public.handle_new_user()                    from public, anon, authenticated;
revoke all on function public.sync_feature_vote_counts()           from public, anon, authenticated;
revoke all on function public.bump_illness_counters(text, boolean) from public, anon, authenticated;
revoke all on function public.resolve_illness_fuzzy(text, real)    from public, anon, authenticated;
revoke all on function public.generate_referral_code()             from public, anon, authenticated;

grant execute on function public.bump_illness_counters(text, boolean) to service_role;
grant execute on function public.resolve_illness_fuzzy(text, real)    to service_role;
