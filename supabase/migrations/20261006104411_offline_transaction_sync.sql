alter table public.transactions
  add column synced_at timestamptz not null default clock_timestamp();

create or replace function public.guard_ledger_write() returns trigger
language plpgsql security invoker set search_path = '' as $$
declare
  is_sync_write boolean := coalesce(current_setting('gainly.sync_write', true), '') = 'on';
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
  elsif not is_sync_write then
    new.created_at := clock_timestamp();
  end if;

  if not is_sync_write then
    new.updated_at := clock_timestamp();
  end if;
  if TG_TABLE_NAME = 'transactions' then
    new.synced_at := clock_timestamp();
  end if;
  return new;
end;
$$;

create function public.sync_transaction(
  p_id uuid,
  p_amount_minor bigint,
  p_type text,
  p_date date,
  p_category_id uuid,
  p_source_id uuid,
  p_payment_method text,
  p_note text,
  p_entry_mode text,
  p_counts_toward_performance boolean,
  p_created_at timestamptz,
  p_updated_at timestamptz,
  p_deleted_at timestamptz
) returns setof public.transactions
language plpgsql security invoker set search_path = '' as $$
declare
  owner_id uuid := auth.uid();
  existing public.transactions%rowtype;
  saved public.transactions%rowtype;
begin
  if owner_id is null then raise exception 'Authentication required'; end if;
  if p_updated_at is null then raise exception 'Modification timestamp required'; end if;

  select * into existing
  from public.transactions
  where id = p_id
  for update;

  if found and existing.updated_at >= p_updated_at then
    return next existing;
    return;
  end if;

  perform set_config('gainly.sync_write', 'on', true);
  if existing.id is null then
    insert into public.transactions(
      id, user_id, amount_minor, type, date, category_id, source_id,
      payment_method, note, entry_mode, counts_toward_performance,
      created_at, updated_at, deleted_at
    ) values (
      p_id, owner_id, p_amount_minor, p_type, p_date, p_category_id, p_source_id,
      p_payment_method, p_note, p_entry_mode, p_counts_toward_performance,
      coalesce(p_created_at, p_updated_at), p_updated_at, p_deleted_at
    ) returning * into saved;
  else
    update public.transactions set
      amount_minor = p_amount_minor,
      type = p_type,
      date = p_date,
      category_id = p_category_id,
      source_id = p_source_id,
      payment_method = p_payment_method,
      note = p_note,
      entry_mode = p_entry_mode,
      counts_toward_performance = p_counts_toward_performance,
      updated_at = p_updated_at,
      deleted_at = p_deleted_at
    where id = p_id
    returning * into saved;
  end if;

  return next saved;
end;
$$;

revoke all on function public.sync_transaction(
  uuid,bigint,text,date,uuid,uuid,text,text,text,boolean,timestamptz,timestamptz,timestamptz
) from public, anon;
grant execute on function public.sync_transaction(
  uuid,bigint,text,date,uuid,uuid,text,text,text,boolean,timestamptz,timestamptz,timestamptz
) to authenticated;
