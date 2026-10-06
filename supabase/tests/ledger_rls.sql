-- Run on the Gainly development database. All synthetic fixtures roll back.
begin;
select set_config('gainly.test_owner', gen_random_uuid()::text, true);
select set_config('gainly.test_other', gen_random_uuid()::text, true);
insert into auth.users(id) values (current_setting('gainly.test_owner')::uuid), (current_setting('gainly.test_other')::uuid);
set local role authenticated;
select set_config('request.jwt.claim.sub', current_setting('gainly.test_owner'), true);
select public.save_profile('Synthetic test owner','en','EUR',100000,25000,150000,6000);
select set_config('gainly.test_category', (select id::text from public.categories where translation_key='delivery'), true);
insert into public.transactions(user_id,amount_minor,type,date,category_id,payment_method,counts_toward_performance)
values (auth.uid(),5029,'income',current_date,current_setting('gainly.test_category')::uuid,'cash',true);
do $$ begin
  if (select count(*) from public.categories) <> 19 then raise exception 'Category seed failed'; end if;
  if (select sum(amount_minor) from public.transactions where user_id=auth.uid()) <> 5029 then raise exception 'Owner read failed'; end if;
  if (select monthly_target_minor from public.profiles where user_id=auth.uid()) <> 150000 then raise exception 'Monthly target persistence failed'; end if;
  if (select daily_minimum_minor from public.profiles where user_id=auth.uid()) <> 6000 then raise exception 'Daily minimum persistence failed'; end if;
end $$;
select set_config('request.jwt.claim.sub', current_setting('gainly.test_other'), true);
do $$ begin
  if exists(select 1 from public.profiles) or exists(select 1 from public.transactions) or exists(select 1 from public.categories) then
    raise exception 'Cross-owner read leak';
  end if;
end $$;
select public.save_profile('Synthetic second owner','es','EUR',null,null);
do $$ begin
  begin
    insert into public.transactions(user_id,amount_minor,type,date,category_id,payment_method,counts_toward_performance)
    values(auth.uid(),100,'income',current_date,current_setting('gainly.test_category')::uuid,'cash',true);
  exception when foreign_key_violation then return;
  end;
  raise exception 'Cross-owner category reference accepted';
end $$;
do $$ begin
  begin
    insert into public.transactions(user_id,amount_minor,type,date,category_id,payment_method,counts_toward_performance)
    values(current_setting('gainly.test_owner')::uuid,100,'income',current_date,current_setting('gainly.test_category')::uuid,'cash',true);
  exception when insufficient_privilege then return;
  end;
  raise exception 'Cross-owner write accepted';
end $$;
select set_config('request.jwt.claim.sub', current_setting('gainly.test_owner'), true);
do $$ begin
  begin
    update public.profiles set currency='USD' where user_id=auth.uid();
  exception when raise_exception then
    if sqlerrm = 'Currency cannot change after ledger activity' then return; else raise; end if;
  end;
  raise exception 'Currency change accepted';
end $$;
update public.transactions set deleted_at=now() where user_id=auth.uid();
do $$ begin
  if exists(select 1 from public.transactions where deleted_at is null) then raise exception 'Soft deletion failed'; end if;
  begin delete from public.transactions where user_id=auth.uid();
  exception when insufficient_privilege then return;
  end;
  raise exception 'Physical deletion accepted';
end $$;
set local role anon;
do $$ begin
  begin perform 1 from public.transactions;
  exception when insufficient_privilege then return;
  end;
  raise exception 'Anonymous ledger access accepted';
end $$;
rollback;
select 'Hosted ledger/RLS checks passed; all fixtures rolled back' as result;
