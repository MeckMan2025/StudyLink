-- SilverCircle: private chat between the two people on a tutoring request.
-- Run once in the Supabase SQL editor (project ejmiqtizvuuilsztbafk).
create table if not exists public.sl_messages (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.sl_requests(id) on delete cascade,
  sender_id uuid not null default auth.uid(),
  body text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now()
);
create index if not exists sl_messages_request on public.sl_messages(request_id, created_at);
alter table public.sl_messages enable row level security;

-- Only the student and the tutor on that request can read or write its chat;
-- administrators can read it for safety.
create policy sl_messages_read on public.sl_messages for select using (
  sl_is_admin() or exists (select 1 from public.sl_requests r
    where r.id = request_id and auth.uid() in (r.student_id, r.tutor_id)));
create policy sl_messages_insert on public.sl_messages for insert with check (
  sender_id = auth.uid() and exists (select 1 from public.sl_requests r
    where r.id = request_id and auth.uid() in (r.student_id, r.tutor_id)));
