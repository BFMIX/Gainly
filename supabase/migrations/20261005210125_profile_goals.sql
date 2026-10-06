-- Optional deterministic goal settings stored with the owner's profile.
alter table public.profiles
  add column monthly_target_minor bigint
    check (monthly_target_minor > 0 and monthly_target_minor <= 9000000000000),
  add column daily_minimum_minor bigint
    check (daily_minimum_minor > 0 and daily_minimum_minor <= 9000000000000);

drop function public.save_profile(text, text, text, bigint, bigint);

create function public.save_profile(
  p_first_name text,
  p_language text,
  p_currency text,
  p_starting_balance bigint default null,
  p_starting_performance_balance bigint default null,
  p_monthly_target bigint default null,
  p_daily_minimum bigint default null
)
returns void language plpgsql security invoker set search_path = '' as $$
declare owner_id uuid := auth.uid();
begin
  if owner_id is null then raise exception 'Authentication required'; end if;
  insert into public.profiles(
    user_id, first_name, language, currency,
    starting_balance_minor, starting_performance_balance_minor,
    monthly_target_minor, daily_minimum_minor
  )
  values(
    owner_id, btrim(p_first_name), p_language, p_currency,
    p_starting_balance, p_starting_performance_balance,
    p_monthly_target, p_daily_minimum
  )
  on conflict(user_id) do update set
    first_name = excluded.first_name,
    language = excluded.language,
    currency = excluded.currency,
    starting_balance_minor = excluded.starting_balance_minor,
    starting_performance_balance_minor = excluded.starting_performance_balance_minor,
    monthly_target_minor = excluded.monthly_target_minor,
    daily_minimum_minor = excluded.daily_minimum_minor;

  insert into public.categories(user_id, name, type, translation_key, counts_toward_performance)
  select owner_id, name, type, key, included from (values
    ('Delivery','income','delivery',true),('Rideshare','income','rideshare',true),('Freelance','income','freelance',true),
    ('Sales','income','sales',true),('Salary','income','salary',true),('Benefits','income','benefits',false),
    ('Refund','income','refund',false),('Gift','income','gift',false),('Other','income','other',true),
    ('Food','expense','food',true),('Fuel','expense','fuel',true),('Transport','expense','transport',true),
    ('Housing','expense','housing',true),('Bills','expense','bills',true),('Shopping','expense','shopping',true),
    ('Leisure','expense','leisure',true),('Health','expense','health',true),('Work expenses','expense','workExpenses',true),('Other','expense','other',true)
  ) as defaults(name,type,key,included)
  on conflict(user_id,type,name) do nothing;
end;
$$;

revoke all on function public.save_profile(text,text,text,bigint,bigint,bigint,bigint) from public;
grant execute on function public.save_profile(text,text,text,bigint,bigint,bigint,bigint) to authenticated;
