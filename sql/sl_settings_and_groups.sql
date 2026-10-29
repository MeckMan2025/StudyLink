-- SilverCircle: editable session times (sl_settings) and study groups.
-- Run once in the Supabase SQL editor.

-- 1. Settings an administrator can change in the app (session times, places).
create table if not exists public.sl_settings (
  key        text primary key,
  value      jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid
);
alter table public.sl_settings enable row level security;
drop policy if exists sl_settings_read on public.sl_settings;
create policy sl_settings_read on public.sl_settings for select using (sl_is_member());
drop policy if exists sl_settings_write on public.sl_settings;
create policy sl_settings_write on public.sl_settings for all using (sl_is_admin()) with check (sl_is_admin());

-- 2. Study groups: one per class is implicit (everyone in the class); these
--    are the extra ones people start, each supervised by a tutor who accepts.
create table if not exists public.sl_groups (
  id            uuid primary key default gen_random_uuid(),
  course        text not null,
  name          text not null,
  created_by    uuid not null,
  creator_alias text,
  tutor_id      uuid not null,
  tutor_alias   text,
  status        text not null default 'pending',   -- pending (tutor hasn't accepted) / active / closed
  created_at    timestamptz not null default now()
);
create table if not exists public.sl_group_members (
  group_id  uuid not null references public.sl_groups(id) on delete cascade,
  user_id   uuid not null,
  alias     text,
  joined_at timestamptz not null default now(),
  primary key (group_id, user_id)
);
alter table public.sl_posts add column if not exists group_id uuid references public.sl_groups(id) on delete cascade;

alter table public.sl_groups enable row level security;
alter table public.sl_group_members enable row level security;
drop policy if exists sl_groups_read on public.sl_groups;
create policy sl_groups_read on public.sl_groups for select using (sl_is_member());
drop policy if exists sl_groups_insert on public.sl_groups;
create policy sl_groups_insert on public.sl_groups for insert with check (created_by = auth.uid() and tutor_id <> auth.uid() and status = 'pending');
drop policy if exists sl_groups_update on public.sl_groups;
create policy sl_groups_update on public.sl_groups for update using (tutor_id = auth.uid() or created_by = auth.uid() or sl_is_admin());
drop policy if exists sl_groups_delete on public.sl_groups;
create policy sl_groups_delete on public.sl_groups for delete using (created_by = auth.uid() or tutor_id = auth.uid() or sl_is_admin());
drop policy if exists sl_group_members_read on public.sl_group_members;
create policy sl_group_members_read on public.sl_group_members for select using (sl_is_member());
drop policy if exists sl_group_members_insert on public.sl_group_members;
create policy sl_group_members_insert on public.sl_group_members for insert with check (user_id = auth.uid() or sl_is_admin()
  or exists (select 1 from public.sl_groups g where g.id = group_id and g.created_by = auth.uid()));
drop policy if exists sl_group_members_delete on public.sl_group_members;
create policy sl_group_members_delete on public.sl_group_members for delete using (user_id = auth.uid() or sl_is_admin()
  or exists (select 1 from public.sl_groups g where g.id = group_id and (g.tutor_id = auth.uid() or g.created_by = auth.uid())));

-- 3. Ratings a tutee leaves after a session. Seen by the rater and staff only;
--    the tutor never sees them.
create table if not exists public.sl_ratings (
  id          uuid primary key default gen_random_uuid(),
  request_id  uuid not null unique references public.sl_requests(id) on delete cascade,
  rater_id    uuid not null,
  tutor_id    uuid not null,
  course      text,
  stars       integer not null check (stars between 1 and 5),
  on_time     boolean,
  prepared    boolean,
  understood  integer check (understood between 1 and 5),   -- "I understand it better now"
  again       boolean,
  comment     text,
  created_at  timestamptz not null default now()
);
alter table public.sl_ratings enable row level security;
drop policy if exists sl_ratings_read on public.sl_ratings;
create policy sl_ratings_read on public.sl_ratings for select using (rater_id = auth.uid() or sl_is_admin());
drop policy if exists sl_ratings_insert on public.sl_ratings;
create policy sl_ratings_insert on public.sl_ratings for insert with check (rater_id = auth.uid()
  and exists (select 1 from public.sl_requests r where r.id = request_id and r.student_id = auth.uid() and r.tutor_id = tutor_id and r.status = 'done'));

-- 4. What a session will cover, agreed in the chat.
alter table public.sl_requests add column if not exists plan text;
