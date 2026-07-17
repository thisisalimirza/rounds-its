-- Rounds — feedback + community feature-request board
--
-- Adds three tables:
--   feedback         : private feedback/bug reports (insert-only for users; you
--                      read them in the dashboard / via service role)
--   feature_requests : public, user-suggested ideas with vote tallies
--   feature_votes    : one up/down vote per user per request
--
-- Everyone already has a silent anonymous Supabase auth session (see
-- AccountManager), so this needs no separate accounts. RLS + explicit GRANTs
-- gate everything; the shipped anon key is safe with these policies.
--
-- Apply:  supabase db push   (or paste into the SQL editor)

-- ---------------------------------------------------------------------------
-- Feedback (private)
-- ---------------------------------------------------------------------------
create table if not exists public.feedback (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid default auth.uid() references auth.users(id) on delete set null,
  category    text not null default 'general',
  message     text not null,
  app_version text,
  created_at  timestamptz not null default now()
);

alter table public.feedback enable row level security;
grant insert on public.feedback to authenticated;

drop policy if exists "feedback_insert_authenticated" on public.feedback;
create policy "feedback_insert_authenticated"
  on public.feedback for insert to authenticated with check (true);
-- No SELECT policy → users cannot read feedback (you read via dashboard).

-- ---------------------------------------------------------------------------
-- Feature requests (public board)
-- ---------------------------------------------------------------------------
create table if not exists public.feature_requests (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid default auth.uid() references auth.users(id) on delete set null,
  title      text not null,
  detail     text,
  status     text not null default 'open',  -- open | planned | in_progress | done | declined
  upvotes    int  not null default 0,
  downvotes  int  not null default 0,
  score      int  generated always as (upvotes - downvotes) stored,
  created_at timestamptz not null default now()
);

alter table public.feature_requests enable row level security;
grant select, insert on public.feature_requests to authenticated;

drop policy if exists "feature_requests_select" on public.feature_requests;
create policy "feature_requests_select"
  on public.feature_requests for select to authenticated using (true);

drop policy if exists "feature_requests_insert" on public.feature_requests;
create policy "feature_requests_insert"
  on public.feature_requests for insert to authenticated with check (true);
-- Users cannot update/delete requests (moderation is yours via service role).

-- ---------------------------------------------------------------------------
-- Votes (one per user per request; +1 or -1)
-- ---------------------------------------------------------------------------
create table if not exists public.feature_votes (
  request_id uuid not null references public.feature_requests(id) on delete cascade,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  value      smallint not null check (value in (-1, 1)),
  created_at timestamptz not null default now(),
  primary key (request_id, user_id)
);

alter table public.feature_votes enable row level security;
grant select, insert, update, delete on public.feature_votes to authenticated;

drop policy if exists "feature_votes_select_own" on public.feature_votes;
create policy "feature_votes_select_own"
  on public.feature_votes for select to authenticated using (user_id = auth.uid());

drop policy if exists "feature_votes_insert_own" on public.feature_votes;
create policy "feature_votes_insert_own"
  on public.feature_votes for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "feature_votes_update_own" on public.feature_votes;
create policy "feature_votes_update_own"
  on public.feature_votes for update to authenticated using (user_id = auth.uid());

drop policy if exists "feature_votes_delete_own" on public.feature_votes;
create policy "feature_votes_delete_own"
  on public.feature_votes for delete to authenticated using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Keep the tallies on feature_requests in sync with the votes table.
-- ---------------------------------------------------------------------------
create or replace function public.sync_feature_vote_counts()
returns trigger language plpgsql security definer as $$
declare rid uuid;
begin
  rid := coalesce(new.request_id, old.request_id);
  update public.feature_requests fr set
    upvotes   = (select count(*) from public.feature_votes v where v.request_id = rid and v.value = 1),
    downvotes = (select count(*) from public.feature_votes v where v.request_id = rid and v.value = -1)
  where fr.id = rid;
  return null;
end $$;

drop trigger if exists trg_feature_vote_counts on public.feature_votes;
create trigger trg_feature_vote_counts
  after insert or update or delete on public.feature_votes
  for each row execute function public.sync_feature_vote_counts();
