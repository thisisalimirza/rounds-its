-- Rounds — the case library, server-side
--
-- NOT YET APPLIED.
--
-- Moves the 514 cases and 366 diagnosis definitions out of CaseLibrary.swift
-- and DiagnosisRegistry.swift so content can ship without shipping a build.
-- Populated by tools/export_case_library.py, which parses the Swift literals
-- directly.
--
-- This is public reference data, not user data: everyone reads the same rows.
-- RLS is on with a read-only public policy, and writes are service-role only,
-- so the admin console is the single path for editing.

-- =========================================================================
-- Diagnoses: the answer-matching vocabulary.
--
-- Separate from cases because several cases can share one diagnosis (the same
-- condition presenting differently), and because this is what decides whether
-- a student's guess is right. Getting a case live without its diagnosis entry
-- means the case is unanswerable.
-- =========================================================================
create table if not exists public.diagnoses (
    slug              text primary key,
    canonical_name    text not null,
    alternative_names text[] not null default '{}',
    category          text not null default '',
    created_at        timestamptz not null default now(),
    updated_at        timestamptz not null default now()
);

create index if not exists diagnoses_category_idx on public.diagnoses(category);

-- =========================================================================
-- Cases.
--
-- `id` is NOT generated here. It is sha256('rounds.case.' || lower(trim(
-- diagnosis))) truncated to 16 bytes, exactly as MedicalCase.deterministicID
-- computes it on device. Every CaseHistoryEntry ever written points at one of
-- those ids, in SwiftData, in CloudKit and in public.case_history — so the ids
-- must be imported, never re-minted.
--
-- The consequence is that a case's *diagnosis name* is its permanent identity.
-- Renaming one in the admin console would orphan every play of it. The unique
-- index below enforces the other half of that invariant: two cases can never
-- share a normalized name, because they would be the same row.
-- =========================================================================
create table if not exists public.cases (
    id                uuid primary key,
    diagnosis         text not null,
    diagnosis_slug    text references public.diagnoses(slug) on delete set null,
    alternative_names text[] not null default '{}',
    hints             text[] not null,
    category          text not null default '',
    difficulty        integer not null default 3 check (difficulty between 1 and 5),
    is_published      boolean not null default true,
    sort_order        integer,
    created_at        timestamptz not null default now(),
    updated_at        timestamptz not null default now(),
    constraint cases_hint_count check (array_length(hints, 1) = 5)
);

create unique index if not exists cases_diagnosis_key
    on public.cases (lower(btrim(diagnosis)));

create index if not exists cases_category_idx  on public.cases(category) where is_published;
create index if not exists cases_updated_idx   on public.cases(updated_at);

-- =========================================================================
-- Daily schedule.
--
-- Today the daily case is a seeded random pick over the library array, so its
-- index depends on the array's length and order: adding a single case changes
-- the daily case for every date, past and future. That is survivable only
-- because the library changes just once per release. The moment content is
-- editable from a console it becomes unacceptable — an edit at 2pm would
-- reshuffle today's case for everyone who hadn't played yet.
--
-- An explicit schedule also buys curation: a cardiology week, a case timed to
-- a campaign, nothing repeating for a year.
--
-- Keyed on the LOCAL date, matching current behaviour — the app builds its seed
-- from the device's calendar. Note this means the existing comment claiming the
-- daily case is "the same for all users worldwide on the same calendar day" is
-- not true and never has been: it is the same for everyone in the same
-- timezone, and rolls over at each user's local midnight. That is the normal
-- daily-puzzle convention, so it is preserved rather than fixed.
-- =========================================================================
create table if not exists public.daily_cases (
    day        date primary key,
    case_id    uuid not null references public.cases(id),
    note       text,
    created_at timestamptz not null default now()
);

-- =========================================================================
-- Keep updated_at honest, so the client can sync deltas with a `since` cursor
-- rather than re-downloading the library.
-- =========================================================================
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

drop trigger if exists cases_touch_updated_at on public.cases;
create trigger cases_touch_updated_at before update on public.cases
    for each row execute function public.touch_updated_at();

drop trigger if exists diagnoses_touch_updated_at on public.diagnoses;
create trigger diagnoses_touch_updated_at before update on public.diagnoses
    for each row execute function public.touch_updated_at();

-- =========================================================================
-- Access. Read-only for everyone, including signed-out visitors browsing the
-- web library. Writes have no policy at all, so only the service role — the
-- admin console, after requireAdmin() — can change content.
-- =========================================================================
alter table public.diagnoses   enable row level security;
alter table public.cases       enable row level security;
alter table public.daily_cases enable row level security;

grant select on public.diagnoses   to anon, authenticated;
grant select on public.cases       to anon, authenticated;
grant select on public.daily_cases to anon, authenticated;

drop policy if exists "diagnoses are public"   on public.diagnoses;
drop policy if exists "published cases are public" on public.cases;
drop policy if exists "daily schedule is public"  on public.daily_cases;

create policy "diagnoses are public" on public.diagnoses
    for select using (true);
create policy "published cases are public" on public.cases
    for select using (is_published);
create policy "daily schedule is public" on public.daily_cases
    for select using (true);
