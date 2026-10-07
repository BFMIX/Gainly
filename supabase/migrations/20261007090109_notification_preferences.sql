create table public.notification_preferences (
  user_id uuid primary key references public.profiles(user_id) on delete cascade,
  daily_reminder boolean not null default true,
  reminder_minutes smallint not null default 1200 check (reminder_minutes between 0 and 1439),
  negative_days_warning boolean not null default true,
  performance_balance_warning boolean not null default true,
  streak_encouragement boolean not null default false,
  badge_achievements boolean not null default false,
  goal_progress boolean not null default false,
  created_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default clock_timestamp()
);

alter table public.notification_preferences enable row level security;
create policy notification_preferences_read on public.notification_preferences
  for select to authenticated using ((select auth.uid()) = user_id);
create policy notification_preferences_insert on public.notification_preferences
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy notification_preferences_update on public.notification_preferences
  for update to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

revoke all on public.notification_preferences from anon, authenticated;
grant select, insert, update on public.notification_preferences to authenticated;

create function public.guard_notification_preferences() returns trigger
language plpgsql security invoker set search_path = '' as $$
begin
  if TG_OP = 'UPDATE' then
    if new.user_id <> old.user_id then raise exception 'Owner is immutable'; end if;
    new.created_at := old.created_at;
  else
    new.created_at := clock_timestamp();
  end if;
  new.updated_at := clock_timestamp();
  return new;
end;
$$;
revoke all on function public.guard_notification_preferences() from public, anon, authenticated;
create trigger notification_preferences_guard
before insert or update on public.notification_preferences
for each row execute function public.guard_notification_preferences();
