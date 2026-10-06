import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/finance.dart';
import 'ledger_repository.dart';

class SupabaseLedgerRepository implements LedgerRepository {
  SupabaseLedgerRepository(this.client);
  final SupabaseClient client;
  String get userId => client.auth.currentUser!.id;
  @override
  Future<Profile?> loadProfile() async {
    final row = await client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return row == null ? null : Profile.fromJson(row);
  }

  @override
  Future<void> saveProfile(Profile profile) => client.rpc(
    'save_profile',
    params: {
      'p_first_name': profile.firstName,
      'p_language': profile.language,
      'p_currency': profile.currency,
      'p_starting_balance': profile.startingBalance,
      'p_starting_performance_balance': profile.startingPerformanceBalance,
      'p_monthly_target': profile.monthlyTarget,
      'p_daily_minimum': profile.dailyMinimum,
    },
  );
  @override
  Future<List<Category>> loadCategories() async =>
      (await client
              .from('categories')
              .select()
              .eq('user_id', userId)
              .isFilter('deleted_at', null)
              .order('name'))
          .map(Category.fromJson)
          .toList();
  @override
  Future<Category> saveCategory(Category category) async {
    final row = await client
        .from('categories')
        .upsert({
          'id': category.id,
          'user_id': userId,
          'name': category.name.trim(),
          'type': category.type.name,
          'translation_key': category.translationKey,
          'counts_toward_performance': category.countsTowardPerformance,
        }, onConflict: 'id')
        .select()
        .single();
    return Category.fromJson(row);
  }

  @override
  Future<List<IncomeSource>> loadSources() async =>
      (await client
              .from('sources')
              .select()
              .eq('user_id', userId)
              .isFilter('deleted_at', null)
              .order('name'))
          .map((j) => IncomeSource(j['id'] as String, j['name'] as String))
          .toList();
  @override
  Future<String> saveSource(String name) async {
    final row = await client
        .from('sources')
        .upsert({
          'user_id': userId,
          'name': name.trim(),
        }, onConflict: 'user_id,name')
        .select('id')
        .single();
    return row['id'] as String;
  }

  @override
  Future<IncomeSource> updateSource(IncomeSource source) async {
    final row = await client
        .from('sources')
        .update({'name': source.name.trim()})
        .eq('id', source.id)
        .eq('user_id', userId)
        .select()
        .single();
    return IncomeSource(row['id'] as String, row['name'] as String);
  }

  @override
  Future<List<LedgerTransaction>> loadTransactions() async {
    final result = <LedgerTransaction>[];
    const pageSize = 500;
    for (var offset = 0; ; offset += pageSize) {
      final rows = await client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .order('date', ascending: false)
          .order('created_at', ascending: false)
          .order('id')
          .range(offset, offset + pageSize - 1);
      result.addAll(rows.map(LedgerTransaction.fromJson));
      if (rows.length < pageSize) break;
    }
    return result;
  }

  @override
  Future<LedgerTransaction> saveTransaction(
    LedgerTransaction transaction,
  ) async {
    final row = await client
        .from('transactions')
        .upsert(transaction.toJson(), onConflict: 'id')
        .select()
        .single();
    return LedgerTransaction.fromJson(row);
  }

  @override
  Future<LedgerTransaction> deleteTransaction(
    LedgerTransaction transaction,
  ) async {
    final row = await client
        .from('transactions')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', transaction.id)
        .eq('user_id', userId)
        .select()
        .single();
    return LedgerTransaction.fromJson(row);
  }
}
