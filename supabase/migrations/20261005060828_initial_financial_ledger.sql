-- Initial owner-scoped financial ledger. All amounts are integer minor units.
create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  first_name text not null check (char_length(btrim(first_name)) between 1 and 60),
  language text not null check (language in ('en', 'fr', 'es')),
  currency text not null check (currency in ('EUR', 'USD', 'GBP')),
  starting_balance_minor bigint check (abs(starting_balance_minor) <= 9000000000000),
  starting_performance_balance_minor bigint check (abs(starting_performance_balance_minor) <= 9000000000000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 100),
  type text not null check (type in ('income', 'expense')),
  translation_key text,
  counts_toward_performance boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (user_id, type, name),
  unique (user_id, id, type)
);
create table public.sources (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (user_id, name),
  unique (user_id, id)
);
create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  amount_minor bigint not null check (amount_minor > 0 and amount_minor <= 9000000000000),
  type text not null check (type in ('income', 'expense')),
  date date not null,
  category_id uuid not null,
  source_id uuid,
  payment_method text not null check (payment_method in ('cash', 'bankCard', 'bankTransfer', 'other')),
  note text check (char_length(note) <= 500),
  entry_mode text not null default 'detailed' check (entry_mode in ('detailed', 'quick')),
  counts_toward_performance boolean not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  foreign key (user_id, category_id, type) references public.categories(user_id, id, type),
  foreign key (user_id, source_id) references public.sources(user_id, id),
  check (entry_mode <> 'quick' or source_id is null)
);
create index transactions_owner_date_idx on public.transactions(user_id, date desc, id);
create index transactions_category_idx on public.transactions(user_id, category_id, type);
create index transactions_source_idx on public.transactions(user_id, source_id);

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.sources enable row level security;
alter table public.transactions enable row level security;

create policy profiles_read on public.profiles for select to authenticated using ((select auth.uid()) = user_id);
create policy profiles_insert on public.profiles for insert to authenticated with check ((select auth.uid()) = user_id);
create policy profiles_update on public.profiles for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy categories_read on public.categories for select to authenticated using ((select auth.uid()) = user_id);
create policy categories_insert on public.categories for insert to authenticated with check ((select auth.uid()) = user_id);
create policy categories_update on public.categories for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy sources_read on public.sources for select to authenticated using ((select auth.uid()) = user_id);
create policy sources_insert on public.sources for insert to authenticated with check ((select auth.uid()) = user_id);
create policy sources_update on public.sources for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy transactions_read on public.transactions for select to authenticated using ((select auth.uid()) = user_id);
create policy transactions_insert on public.transactions for insert to authenticated with check ((select auth.uid()) = user_id);
create policy transactions_update on public.transactions for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

revoke all on public.profiles, public.categories, public.sources, public.transactions from anon, authenticated;
grant select, insert, update on public.profiles, public.categories, public.sources, public.transactions to authenticated;
-- No DELETE grant or policy: user-initiated deletion uses tombstones.

create function public.guard_ledger_write() returns trigger language plpgsql security invoker set search_path = '' as $$
begin
  if TG_OP = 'UPDATE' then
    if new.user_id <> old.user_id then raise exception 'Owner is immutable'; end if;
    new.created_at := old.created_at;
    if TG_TABLE_NAME = 'profiles' then
      if new.currency <> old.currency and exists(select 1 from public.transactions where user_id = old.user_id) then
        raise exception 'Currency cannot change after ledger activity';
      end if;
    else
      if new.id <> old.id then raise exception 'Identity is immutable'; end if;
    end if;
  else
    new.created_at := now();
    if TG_TABLE_NAME = 'transactions' then
      -- Serialize inserts against currency changes on this account.
      perform 1 from public.profiles where user_id = new.user_id for update;
    end if;
  end if;
  new.updated_at := clock_timestamp();
  return new;
end;
$$;
revoke all on function public.guard_ledger_write() from public;
create trigger profiles_guard before insert or update on public.profiles for each row execute function public.guard_ledger_write();
create trigger categories_guard before insert or update on public.categories for each row execute function public.guard_ledger_write();
create trigger sources_guard before insert or update on public.sources for each row execute function public.guard_ledger_write();
create trigger transactions_guard before insert or update on public.transactions for each row execute function public.guard_ledger_write();

create function public.save_profile(p_first_name text, p_language text, p_currency text, p_starting_balance bigint default null, p_starting_performance_balance bigint default null)
returns void language plpgsql security invoker set search_path = '' as $$
declare owner_id uuid := auth.uid();
begin
  if owner_id is null then raise exception 'Authentication required'; end if;
  insert into public.profiles(user_id, first_name, language, currency, starting_balance_minor, starting_performance_balance_minor)
  values(owner_id, btrim(p_first_name), p_language, p_currency, p_starting_balance, p_starting_performance_balance)
  on conflict(user_id) do update set first_name = excluded.first_name, language = excluded.language, currency = excluded.currency,
    starting_balance_minor = excluded.starting_balance_minor, starting_performance_balance_minor = excluded.starting_performance_balance_minor;
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
revoke all on function public.save_profile(text,text,text,bigint,bigint) from public;
grant execute on function public.save_profile(text,text,text,bigint,bigint) to authenticated;
