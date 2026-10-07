import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/finance.dart';
import '../domain/notification_preferences.dart';
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
  Future<NotificationPreferences> loadNotificationPreferences() async {
    final row = await client
        .from('notification_preferences')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return row == null
        ? const NotificationPreferences()
        : NotificationPreferences.fromJson(row);
  }

  @override
  Future<NotificationPreferences> saveNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    final row = await client
        .from('notification_preferences')
        .upsert({'user_id': userId, ...preferences.toJson()})
        .select()
        .single();
    return NotificationPreferences.fromJson(row);
  }

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
  Future<IncomeSource> saveSource(IncomeSource source) async {
    final row = await client
        .from('sources')
        .upsert({
          'id': source.id,
          'user_id': userId,
          'name': source.name.trim(),
        }, onConflict: 'id')
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
    final now = DateTime.now().toUtc();
    return _syncTransaction(
      _withTimestamps(
        transaction,
        createdAt: transaction.createdAt ?? now,
        updatedAt: transaction.updatedAt ?? now,
      ),
    );
  }

  @override
  Future<LedgerTransaction> deleteTransaction(
    LedgerTransaction transaction,
  ) async {
    final now = DateTime.now().toUtc();
    return _syncTransaction(
      _withTimestamps(
        transaction,
        createdAt: transaction.createdAt ?? now,
        updatedAt: now,
        deletedAt: now,
      ),
    );
  }

  Future<LedgerTransaction> _syncTransaction(
    LedgerTransaction transaction,
  ) async {
    final result = await client.rpc(
      'sync_transaction',
      params: {
        'p_id': transaction.id,
        'p_amount_minor': transaction.amountMinor,
        'p_type': transaction.type.name,
        'p_date': dateKey(transaction.date),
        'p_category_id': transaction.categoryId,
        'p_source_id': transaction.sourceId,
        'p_payment_method': transaction.paymentMethod.name,
        'p_note': transaction.note,
        'p_entry_mode': transaction.entryMode,
        'p_counts_toward_performance': transaction.countsTowardPerformance,
        'p_created_at': transaction.createdAt!.toIso8601String(),
        'p_updated_at': transaction.updatedAt!.toIso8601String(),
        'p_deleted_at': transaction.deletedAt?.toIso8601String(),
      },
    );
    final rows = result as List<dynamic>;
    return LedgerTransaction.fromJson(rows.single as Map<String, dynamic>);
  }
}

LedgerTransaction _withTimestamps(
  LedgerTransaction transaction, {
  required DateTime createdAt,
  required DateTime updatedAt,
  DateTime? deletedAt,
}) => LedgerTransaction(
  id: transaction.id,
  userId: transaction.userId,
  amountMinor: transaction.amountMinor,
  type: transaction.type,
  date: transaction.date,
  categoryId: transaction.categoryId,
  countsTowardPerformance: transaction.countsTowardPerformance,
  sourceId: transaction.sourceId,
  paymentMethod: transaction.paymentMethod,
  note: transaction.note,
  entryMode: transaction.entryMode,
  createdAt: createdAt,
  updatedAt: updatedAt,
  deletedAt: deletedAt ?? transaction.deletedAt,
);
