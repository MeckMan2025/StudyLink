alter table public.sl_group_members add column if not exists status text not null default 'member';
drop policy if exists sl_group_members_update on public.sl_group_members;
create policy sl_group_members_update on public.sl_group_members for update using (sl_is_admin()
  or exists (select 1 from public.sl_groups g where g.id = group_id and (g.tutor_id = auth.uid() or g.created_by = auth.uid())));
