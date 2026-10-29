drop policy if exists sl_groups_insert on public.sl_groups;
create policy sl_groups_insert on public.sl_groups for insert with check (
  created_by = auth.uid() and (
    (tutor_id <> auth.uid() and status = 'pending') or
    (tutor_id = auth.uid() and status = 'active')
  )
);
