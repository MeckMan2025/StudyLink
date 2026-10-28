-- SilverCircle: how long a session is planned for. Sessions over 45 minutes
-- may not be held inside the school: the app only offers off-campus places
-- for them, and this check backs that up.
alter table public.sl_requests add column if not exists minutes integer not null default 45;
alter table public.sl_requests drop constraint if exists sl_requests_long_sessions_off_campus;
alter table public.sl_requests add constraint sl_requests_long_sessions_off_campus check (
  minutes <= 45 or format <> 'In person' or location is null
  or location not similar to '(Library|Learning commons|Cafeteria|Classroom|Front office / counseling)%'
);
