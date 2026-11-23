-- Background illness-script builds.
--
-- The shipped app calls `illness-script` synchronously and never reads this
-- table. Async callers insert one row per condition_key, return 202, and
-- finish the generation in EdgeRuntime.waitUntil. Players can read status.
-- Only the edge function (service role) writes.
--
-- Apply manually (supabase db push, or paste into the SQL editor).
-- Not applied by the change that added this file.

create table if not exists public.illness_script_builds (
  condition_key text primary key,
  condition     text not null,
  status        text not null check (status in ('building', 'done', 'failed')),
  started_at    timestamptz not null default now(),
  finished_at   timestamptz,
  error         text,
  -- Where the saved script lives when that key differs from condition_key.
  script_key    text,
  is_miss       boolean not null default false,
  -- Changes on every claim so a stale worker cannot mark a newer attempt.
  build_token   uuid,
  updated_at    timestamptz not null default now()
);

comment on table public.illness_script_builds is
  'In-flight and recent illness-script generations. Players may read status; only the illness-script edge function writes.';

alter table public.illness_script_builds enable row level security;

grant select on public.illness_script_builds to authenticated;
grant select, insert, update, delete on public.illness_script_builds to service_role;

drop policy if exists "illness_script_builds_read" on public.illness_script_builds;
create policy "illness_script_builds_read"
  on public.illness_script_builds for select to authenticated using (true);
-- No insert/update/delete policy: authenticated players cannot write.

-- Atomically claim a build. Returns the new build_token when this caller
-- should start work, or null when a build for the key is still in flight
-- (status = building and started less than p_stale_seconds ago — default
-- 8 minutes). A failed, finished, or stale row is reclaimed.
--
-- language sql, not plpgsql: a declined ON CONFLICT WHERE returns zero rows,
-- and a scalar SQL function turns that into null. plpgsql RETURNING INTO
-- can raise NO_DATA_FOUND instead, which would surface a deduped claim as
-- an error.
create or replace function public.claim_illness_script_build(
  p_key text,
  p_condition text,
  p_miss boolean,
  p_stale_seconds int default 480
) returns uuid
language sql
security definer
set search_path = public
as $$
  insert into public.illness_script_builds (
    condition_key, condition, status, started_at, finished_at, error,
    script_key, is_miss, build_token, updated_at
  ) values (
    p_key, p_condition, 'building', clock_timestamp(), null, null,
    null, coalesce(p_miss, false), gen_random_uuid(), clock_timestamp()
  )
  on conflict (condition_key) do update
    set condition = excluded.condition,
        status = 'building',
        started_at = clock_timestamp(),
        finished_at = null,
        error = null,
        script_key = null,
        is_miss = excluded.is_miss,
        build_token = gen_random_uuid(),
        updated_at = clock_timestamp()
    where public.illness_script_builds.status is distinct from 'building'
       or public.illness_script_builds.started_at <
            clock_timestamp() - make_interval(secs => p_stale_seconds)
  returning build_token;
$$;

revoke all on function public.claim_illness_script_build(text, text, boolean, int)
  from public, anon, authenticated;
grant execute on function public.claim_illness_script_build(text, text, boolean, int)
  to service_role;
