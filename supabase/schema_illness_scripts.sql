-- Rounds — global Illness Scripts library
--
-- An illness script for a condition is the same for everyone, so it's generated
-- ONCE (by the first user who needs it) and then served from this shared table
-- to every future user — no repeat Claude calls. Over time this fills in
-- organically into a reference library, and the counters below become an
-- aggregate signal of what trips med students up most (a data moat).
--
-- Writes happen only in the `illness-script` edge function (service role);
-- users get read-only access via RLS.
--
-- Apply:  supabase db push   (or paste into the SQL editor)

create table if not exists public.illness_scripts (
  id              uuid primary key default gen_random_uuid(),
  condition_key   text unique not null,          -- normalized lookup key
  condition       text not null,                 -- canonical display name
  system          text,                          -- specialty/system, for organizing the library
  one_liner       text,                          -- classic 1-line presentation
  demographics    text[] not null default '{}',  -- who gets it, where
  diagnostics     text[] not null default '{}',  -- how to diagnose
  pathophysiology text[] not null default '{}',  -- what's going on
  treatment       text[] not null default '{}',  -- how to treat / what to order
  miss_count      int  not null default 0,       -- times requested because a user missed it
  review_count    int  not null default 0,       -- times opened/viewed
  model           text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

-- Safe to re-run on an already-created table (adds columns if missing).
alter table public.illness_scripts add column if not exists system text;

-- Richer, shelf-ready script framework (v1). Existing rows have schema_version 0
-- and auto-regenerate into the new shape the next time they're opened.
alter table public.illness_scripts add column if not exists predisposing    text[] not null default '{}';
alter table public.illness_scripts add column if not exists presentation    text[] not null default '{}';
alter table public.illness_scripts add column if not exists management       text[] not null default '{}';
alter table public.illness_scripts add column if not exists pivots          jsonb  not null default '[]';
alter table public.illness_scripts add column if not exists schema_version   int    not null default 0;

create index if not exists illness_scripts_miss_idx on public.illness_scripts (miss_count desc);

alter table public.illness_scripts enable row level security;
grant select on public.illness_scripts to authenticated;

drop policy if exists "illness_scripts_read" on public.illness_scripts;
create policy "illness_scripts_read"
  on public.illness_scripts for select to authenticated using (true);
-- No insert/update policy → only the edge function (service role) writes.

-- Atomic counter bump (avoids read-modify-write races across users).
create or replace function public.bump_illness_counters(p_key text, p_miss boolean)
returns void language sql security definer as $$
  update public.illness_scripts
  set review_count = review_count + 1,
      miss_count   = miss_count + (case when p_miss then 1 else 0 end),
      updated_at   = now()
  where condition_key = p_key;
$$;

grant execute on function public.bump_illness_counters(text, boolean) to service_role;

-- ---------------------------------------------------------------------------
-- Aliases + fuzzy resolution — so typos ("myocardial infraction") and synonyms
-- ("heart attack" → "Myocardial infarction") map to ONE stored script and cost
-- no repeat API call. The edge function learns aliases as it resolves them.
-- ---------------------------------------------------------------------------
create extension if not exists pg_trgm;

create table if not exists public.illness_aliases (
  alias_key     text primary key,                        -- normalized typed input
  condition_key text not null references public.illness_scripts(condition_key) on delete cascade,
  created_at    timestamptz not null default now()
);

alter table public.illness_aliases enable row level security;
grant select on public.illness_aliases to authenticated;

drop policy if exists "illness_aliases_read" on public.illness_aliases;
create policy "illness_aliases_read"
  on public.illness_aliases for select to authenticated using (true);

create index if not exists illness_scripts_key_trgm
  on public.illness_scripts using gin (condition_key gin_trgm_ops);
create index if not exists illness_aliases_key_trgm
  on public.illness_aliases using gin (alias_key gin_trgm_ops);

-- Best fuzzy match (typo tolerance) against known keys + aliases, above a
-- similarity threshold. Returns the canonical condition_key, or null.
create or replace function public.resolve_illness_fuzzy(q text, min_sim real)
returns text language sql stable security definer as $$
  with candidates as (
    select condition_key as ckey, similarity(condition_key, q) as sim
      from public.illness_scripts
    union all
    select condition_key as ckey, similarity(alias_key, q) as sim
      from public.illness_aliases
  )
  select ckey from candidates
  where sim >= min_sim
  order by sim desc
  limit 1;
$$;

grant execute on function public.resolve_illness_fuzzy(text, real) to service_role;
