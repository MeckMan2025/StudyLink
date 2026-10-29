create table if not exists public.sl_reports (
  id          uuid primary key default gen_random_uuid(),
  post_id     uuid references public.sl_posts(id) on delete cascade,
  message_id  uuid references public.sl_messages(id) on delete cascade,
  reporter_id uuid not null,
  reason      text,
  snapshot    text,
  status      text not null default 'open',
  created_at  timestamptz not null default now()
);
alter table public.sl_reports enable row level security;
drop policy if exists sl_reports_read on public.sl_reports;
create policy sl_reports_read on public.sl_reports for select using (reporter_id = auth.uid() or sl_is_admin());
drop policy if exists sl_reports_insert on public.sl_reports;
create policy sl_reports_insert on public.sl_reports for insert with check (reporter_id = auth.uid());
drop policy if exists sl_reports_update on public.sl_reports;
create policy sl_reports_update on public.sl_reports for update using (sl_is_admin());
drop policy if exists sl_posts_delete on public.sl_posts;
create policy sl_posts_delete on public.sl_posts for delete using (sl_is_admin());
