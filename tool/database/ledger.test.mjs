import { PGlite } from '@electric-sql/pglite';
import { readFileSync, readdirSync } from 'node:fs';
import assert from 'node:assert/strict';

// Real PostgreSQL execution with a minimal Supabase auth schema fixture.
// This validates SQL/RLS, not hosted Auth, PostgREST, or OAuth configuration.
const db = new PGlite();
let checks = 0;
const owner = '11111111-1111-4111-8111-111111111111';
const other = '22222222-2222-4222-8222-222222222222';
await db.exec(`
  create role anon nologin;
  create role authenticated nologin;
  create schema auth;
  create table auth.users(id uuid primary key);
  create function auth.uid() returns uuid language sql stable as
    $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
  grant usage on schema auth, public to authenticated, anon;
  grant execute on function auth.uid() to authenticated, anon;
  insert into auth.users values ('${owner}'), ('${other}');
`);
const migrationDirectory = new URL('../../supabase/migrations/', import.meta.url);
for (const name of readdirSync(migrationDirectory).filter(n => n.endsWith('.sql')).sort()) {
  await db.exec(readFileSync(new URL(name, migrationDirectory), 'utf8'));
}
async function asUser(id) {
  await db.exec('reset role');
  await db.query("select set_config('request.jwt.claim.sub', $1, false)", [id]);
  await db.exec('set role authenticated');
}
async function scalar(sql, params = []) { return Object.values((await db.query(sql, params)).rows[0])[0]; }
async function rejects(sql, params = []) { await assert.rejects(() => db.query(sql, params)); checks++; }
await asUser(owner);
await db.query("select public.save_profile('Alex','en','EUR',100000,25000)");
assert.equal(await scalar('select count(*)::int from public.categories'), 19); checks++;
await db.query("select public.save_profile('Alex','fr','EUR',100000,25000)");
assert.equal(await scalar('select count(*)::int from public.categories'), 19); checks++;
await db.query("select public.save_profile('Alex','fr','EUR',100000,25000,150000,6000)");
assert.equal(await scalar('select monthly_target_minor::int from public.profiles'), 150000); checks++;
assert.equal(await scalar('select daily_minimum_minor::int from public.profiles'), 6000); checks++;
await rejects("update public.profiles set monthly_target_minor=0");
await rejects("update public.profiles set daily_minimum_minor=-1");
const delivery = await scalar("select id from public.categories where translation_key = 'delivery'");
const fuel = await scalar("select id from public.categories where translation_key = 'fuel'");
await db.query("insert into public.sources(user_id,name) values ($1,'Example courier')", [owner]);
const source = await scalar('select id from public.sources');
const insert = `insert into public.transactions(user_id,amount_minor,type,date,category_id,source_id,payment_method,counts_toward_performance)
  values ($1,$2,$3,'2026-10-05',$4,$5,'bankTransfer',$6) returning id`;
const income = await scalar(insert, [owner, 5029, 'income', delivery, source, true]);
await db.query(insert, [owner, 1000, 'expense', fuel, null, true]);
await db.query(insert, [owner, 20000, 'income', delivery, null, false]);
assert.equal(await scalar(`select sum(case when type='income' then amount_minor else -amount_minor end)::int from public.transactions`), 24029); checks++;
assert.equal(await scalar(`select sum(case when type='income' then amount_minor else -amount_minor end)::int from public.transactions where counts_toward_performance`), 4029); checks++;
await rejects(insert, [owner, 0, 'income', delivery, null, true]);
await rejects(insert, [owner, 9000000000001, 'income', delivery, null, true]);
await rejects(insert, [owner, 100, 'expense', delivery, null, true]);
await rejects("update public.profiles set currency='USD'");
await rejects('delete from public.transactions');
await db.query('update public.transactions set deleted_at=now() where id=$1', [income]);
assert.equal(await scalar('select count(*)::int from public.transactions where deleted_at is null'), 2); checks++;
await asUser(other);
assert.equal(await scalar('select count(*)::int from public.profiles'), 0); checks++;
assert.equal(await scalar('select count(*)::int from public.transactions'), 0); checks++;
assert.equal(await scalar('select count(*)::int from public.categories'), 0); checks++;
await db.query("select public.save_profile('Sam','es','EUR',null,null)");
const otherCategory = await scalar("select id from public.categories where translation_key='delivery'");
await rejects(insert, [other, 100, 'income', delivery, null, true]);
await rejects(insert, [other, 100, 'income', otherCategory, source, true]);
await rejects(insert, [owner, 100, 'income', delivery, null, true]);
await rejects('update public.profiles set user_id=$1', [owner]);
const update = await db.query('update public.transactions set amount_minor=1 where id=$1 returning id', [income]);
assert.equal(update.rows.length, 0); checks++;
assert.equal(await scalar('select starting_balance_minor from public.profiles'), null); checks++;
await db.exec('reset role; set role anon');
await rejects('select * from public.transactions');
await rejects("select public.save_profile('Guest','en','EUR',0,0)");
await db.close();
console.log(`${checks} database checks passed: migration, onboarding, ownership, RLS, foreign keys, currency guard, tombstones, and anonymous access.`);
