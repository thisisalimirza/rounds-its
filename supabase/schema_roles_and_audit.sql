-- Rounds — team roles, permissions and an audit trail
--
-- NOT YET APPLIED. Run in the Supabase SQL editor.
--
-- Rounds is moving from "one person edits Swift and ships a build" to "a team
-- edits a live database that every device reads within six hours". App Review
-- was an accidental safety net: it made bad content slow. That net is gone, so
-- the replacements have to be deliberate.
--
-- Three things go in here, and they go in *before* the team arrives because
-- none of them can be backfilled: you cannot reconstruct who changed what
-- last month, and you cannot un-see the user data a contractor already had.
--
--   1. Roles you can create and edit from the console.
--   2. Permissions those roles grant.
--   3. A log of every privileged action.
--
-- The division of labour is the important part:
--
--   PERMISSIONS ARE DEFINED IN CODE. Each one corresponds to an actual guard
--   in the application, so inventing "cases.delete" in a GUI would produce a
--   permission that grants nothing. lib/permissions.ts is the registry; this
--   table only records which of those a role holds.
--
--   ROLES ARE DATA. Adding "ENT content reviewer" should not need a deploy.
--
--   OWNER IS NEITHER. See below.

-- =========================================================================
-- Roles
-- =========================================================================
create table if not exists public.roles (
    slug        text primary key,
    name        text not null,
    description text not null default '',
    -- System roles cannot be deleted or renamed. Without this, someone
    -- removes the role they are standing on and the console becomes
    -- unreachable for everyone.
    is_system   boolean not null default false,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now()
);

create table if not exists public.role_permissions (
    role_slug  text not null references public.roles(slug) on delete cascade,
    permission text not null,
    primary key (role_slug, permission)
);

insert into public.roles (slug, name, description, is_system) values
    ('owner',   'Owner',   'Full access, including team and roles. Cannot be restricted.', true),
    ('admin',   'Admin',   'Everything except managing the team.', true),
    ('content', 'Content', 'Write and publish cases and the daily schedule. No access to user data.', false),
    ('support', 'Support', 'Look up users and grant Pro. No access to content.', false)
on conflict (slug) do nothing;

insert into public.role_permissions (role_slug, permission) values
    ('admin', 'content.read'), ('admin', 'content.write'), ('admin', 'content.publish'),
    ('admin', 'schedule.write'), ('admin', 'users.read'), ('admin', 'users.grant_pro'),
    ('admin', 'campaigns.write'), ('admin', 'audit.read'),

    -- Deliberately no users.read. A content contractor has no business
    -- reading medical students' case histories or email addresses.
    ('content', 'content.read'), ('content', 'content.write'), ('content', 'content.publish'),
    ('content', 'schedule.write'),

    ('support', 'users.read'), ('support', 'users.grant_pro'), ('support', 'content.read')
on conflict do nothing;

-- =========================================================================
-- Team membership, by email.
--
-- Generalises the existing admin_emails table: instead of a fixed role
-- string it points at a role, so a teammate can be added — and their access
-- changed — without a deploy. Keyed on email so someone can be added before
-- they have ever signed in.
-- =========================================================================
create table if not exists public.team_members (
    email      text primary key,
    role_slug  text not null references public.roles(slug),
    note       text not null default '',
    invited_by uuid references public.profiles(id) on delete set null,
    user_id    uuid references public.profiles(id) on delete set null,
    created_at timestamptz not null default now()
);

alter table public.profiles add column if not exists role_slug text references public.roles(slug);

-- Carry the existing admin_emails rows across, then keep profiles.role in
-- step so nothing reading the old column breaks mid-migration.
insert into public.team_members (email, role_slug, note)
select lower(a.email), a.role, coalesce(a.note, '')
  from public.admin_emails a
 where exists (select 1 from public.roles r where r.slug = a.role)
on conflict (email) do nothing;

update public.profiles p
   set role_slug = t.role_slug,
       role      = case when t.role_slug in ('owner', 'admin') then t.role_slug else p.role end
  from public.team_members t, auth.users u
 where u.id = p.id and lower(u.email) = t.email;

update public.team_members t
   set user_id = u.id
  from auth.users u
 where lower(u.email) = t.email;

-- =========================================================================
-- Assign the role on sign-up or email change.
--
-- Replaces sync_admin_role. Same idea, one indirection deeper.
-- =========================================================================
create or replace function public.sync_team_role()
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

    select role_slug into v_role
      from public.team_members
     where email = lower(new.email);

    if v_role is null then
        return new;
    end if;

    -- handle_new_user() creates the profile on the same INSERT, but trigger
    -- ordering is not guaranteed, so upsert rather than assume it exists.
    insert into public.profiles (id, referral_code, role, role_slug)
    values (new.id, public.generate_referral_code(), 
            case when v_role in ('owner', 'admin') then v_role else 'user' end,
            v_role)
    on conflict (id) do update
        set role_slug = excluded.role_slug,
            role      = excluded.role;

    update public.team_members set user_id = new.id where email = lower(new.email);
    return new;
end;
$$;

drop trigger if exists on_auth_user_admin_sync on auth.users;
drop trigger if exists on_auth_user_team_sync on auth.users;
create trigger on_auth_user_team_sync
    after insert or update of email on auth.users
    for each row execute function public.sync_team_role();

revoke all on function public.sync_team_role() from public, anon, authenticated;

-- =========================================================================
-- Audit log.
--
-- `before` and `after` are not decoration. Together they are the version
-- history: restoring a case is writing `before` back, and diffing two rows
-- shows exactly what a teammate changed. That is why an edit records the
-- whole row rather than just the fields that moved.
--
-- actor_email is denormalised on purpose — the log has to stay readable
-- after someone leaves and their account is deleted.
-- =========================================================================
create table if not exists public.admin_audit_log (
    id          bigserial primary key,
    actor_id    uuid references public.profiles(id) on delete set null,
    actor_email text not null default '',
    action      text not null,
    entity_type text not null default '',
    entity_id   text,
    summary     text not null default '',
    before      jsonb,
    after       jsonb,
    created_at  timestamptz not null default now()
);

create index if not exists audit_log_created_idx on public.admin_audit_log(created_at desc);
create index if not exists audit_log_entity_idx  on public.admin_audit_log(entity_type, entity_id, created_at desc);
create index if not exists audit_log_actor_idx   on public.admin_audit_log(actor_id, created_at desc);

-- =========================================================================
-- Access.
--
-- All four tables are service-role only: everything that reads or writes
-- them goes through requirePermission() first, which is where the actual
-- authorisation lives. No policies means no direct client access, which is
-- the correct default for a table that decides who can do what.
-- =========================================================================
alter table public.roles            enable row level security;
alter table public.role_permissions enable row level security;
alter table public.team_members     enable row level security;
alter table public.admin_audit_log  enable row level security;

-- One exception: a signed-in user may read the permission list for their own
-- role, so the console can hide what they cannot use. Reading it grants
-- nothing — every action re-checks server-side.
grant select on public.role_permissions to authenticated;
drop policy if exists "read own role permissions" on public.role_permissions;
create policy "read own role permissions" on public.role_permissions
    for select to authenticated
    using (role_slug = (select p.role_slug from public.profiles p where p.id = auth.uid()));
