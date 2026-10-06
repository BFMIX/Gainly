import 'dart:convert';

import '../domain/finance.dart';
import 'ledger_repository.dart';

abstract interface class LedgerLocalStore {
  Future<String?> read(String userId);
  Future<void> write(String userId, String value);
}

class CachedLedgerRepository implements LedgerRepository {
  CachedLedgerRepository({
    required this.userId,
    required this.remote,
    required this.store,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final String userId;
  final LedgerRepository remote;
  final LedgerLocalStore store;
  final DateTime Function() _clock;

  Profile? _profile;
  List<Category> _categories = [];
  List<IncomeSource> _sources = [];
  List<LedgerTransaction> _transactions = [];
  bool _pendingProfile = false;
  final Set<String> _pendingCategoryIds = {};
  final Set<String> _pendingSourceIds = {};
  final Set<String> _pendingTransactionIds = {};
  bool _initialized = false;
  bool _hasLocalState = false;
  bool isOffline = false;

  int get pendingChanges =>
      (_pendingProfile ? 1 : 0) +
      _pendingCategoryIds.length +
      _pendingSourceIds.length +
      _pendingTransactionIds.length;

  Future<void> _ensureLocal() async {
    if (_initialized) return;
    _initialized = true;
    final encoded = await store.read(userId);
    if (encoded == null) return;
    final json = jsonDecode(encoded) as Map<String, dynamic>;
    _hasLocalState = true;
    final profileJson = json['profile'] as Map<String, dynamic>?;
    _profile = profileJson == null ? null : Profile.fromJson(profileJson);
    _categories = (json['categories'] as List<dynamic>? ?? const [])
        .map((value) => _categoryFromJson(value as Map<String, dynamic>))
        .toList();
    _sources = (json['sources'] as List<dynamic>? ?? const [])
        .map((value) => _sourceFromJson(value as Map<String, dynamic>))
        .toList();
    _transactions = (json['transactions'] as List<dynamic>? ?? const [])
        .map(
          (value) => LedgerTransaction.fromJson(value as Map<String, dynamic>),
        )
        .toList();
    _pendingTransactionIds.addAll(
      (json['pending_transaction_ids'] as List<dynamic>? ?? const []).cast(),
    );
    _pendingProfile = json['pending_profile'] as bool? ?? false;
    _pendingCategoryIds.addAll(
      (json['pending_category_ids'] as List<dynamic>? ?? const []).cast(),
    );
    _pendingSourceIds.addAll(
      (json['pending_source_ids'] as List<dynamic>? ?? const []).cast(),
    );
  }

  Future<void> _persist() {
    _hasLocalState = true;
    return store.write(
      userId,
      jsonEncode({
        'version': 1,
        'profile': _profile?.toJson(),
        'categories': _categories.map(_categoryToJson).toList(),
        'sources': _sources.map(_sourceToJson).toList(),
        'transactions': _transactions.map(_transactionToJson).toList(),
        'pending_profile': _pendingProfile,
        'pending_category_ids': _pendingCategoryIds.toList()..sort(),
        'pending_source_ids': _pendingSourceIds.toList()..sort(),
        'pending_transaction_ids': _pendingTransactionIds.toList()..sort(),
      }),
    );
  }

  Future<void> _refresh() async {
    try {
      await synchronize();
      final profile = await remote.loadProfile();
      final categories = profile == null
          ? <Category>[]
          : await remote.loadCategories();
      final sources = profile == null
          ? <IncomeSource>[]
          : await remote.loadSources();
      final transactions = profile == null
          ? <LedgerTransaction>[]
          : await remote.loadTransactions();
      _profile = profile;
      _categories = categories;
      _sources = sources;
      _transactions = transactions;
      isOffline = false;
      await _persist();
    } catch (_) {
      isOffline = true;
      if (!_hasLocalState) rethrow;
    }
  }

  Future<void> synchronize() async {
    await _ensureLocal();
    try {
      if (_pendingProfile) {
        await remote.saveProfile(_profile!);
        _pendingProfile = false;
        final remoteCategories = await remote.loadCategories();
        final pendingCategories = _categories
            .where((value) => _pendingCategoryIds.contains(value.id))
            .toList();
        _categories = [
          ...pendingCategories,
          ...remoteCategories.where(
            (value) => !_pendingCategoryIds.contains(value.id),
          ),
        ];
        await _persist();
      }
      for (final id in _pendingCategoryIds.toList()) {
        final category = _categories.firstWhere((value) => value.id == id);
        final saved = await remote.saveCategory(category);
        _categories = [
          saved,
          ..._categories.where((value) => value.id != saved.id),
        ];
        _pendingCategoryIds.remove(id);
        await _persist();
      }
      for (final id in _pendingSourceIds.toList()) {
        final source = _sources.firstWhere((value) => value.id == id);
        final saved = await remote.saveSource(source);
        _sources = [saved, ..._sources.where((value) => value.id != saved.id)];
        _pendingSourceIds.remove(id);
        await _persist();
      }
      for (final id in _pendingTransactionIds.toList()) {
        final transaction = _transactions.firstWhere((value) => value.id == id);
        final saved = await remote.saveTransaction(transaction);
        _replaceTransaction(saved);
        _pendingTransactionIds.remove(id);
        await _persist();
      }
      isOffline = false;
    } catch (_) {
      isOffline = true;
      await _persist();
      rethrow;
    }
  }

  @override
  Future<Profile?> loadProfile() async {
    await _ensureLocal();
    await _refresh();
    return _profile;
  }

  @override
  Future<List<Category>> loadCategories() async {
    await _ensureLocal();
    return List.unmodifiable(_categories);
  }

  @override
  Future<List<IncomeSource>> loadSources() async {
    await _ensureLocal();
    return List.unmodifiable(_sources);
  }

  @override
  Future<List<LedgerTransaction>> loadTransactions() async {
    await _ensureLocal();
    return _transactions
        .where((transaction) => transaction.deletedAt == null)
        .toList(growable: false);
  }

  @override
  Future<void> saveProfile(Profile profile) async {
    await _ensureLocal();
    _profile = profile;
    _pendingProfile = true;
    await _persist();
    try {
      await synchronize();
    } catch (_) {
      // The durable queue will retry when connectivity returns.
    }
  }

  @override
  Future<Category> saveCategory(Category category) async {
    await _ensureLocal();
    final saved = category;
    _categories = [
      saved,
      ..._categories.where((value) => value.id != saved.id),
    ];
    _pendingCategoryIds.add(saved.id);
    await _persist();
    try {
      await synchronize();
    } catch (_) {
      // The durable queue will retry when connectivity returns.
    }
    return _categories.firstWhere((value) => value.id == saved.id);
  }

  @override
  Future<IncomeSource> saveSource(IncomeSource source) async {
    await _ensureLocal();
    final saved = IncomeSource(source.id, source.name.trim());
    _sources = [saved, ..._sources.where((value) => value.id != saved.id)];
    _pendingSourceIds.add(saved.id);
    await _persist();
    try {
      await synchronize();
    } catch (_) {
      // The durable queue will retry when connectivity returns.
    }
    return _sources.firstWhere((value) => value.id == saved.id);
  }

  @override
  Future<LedgerTransaction> saveTransaction(
    LedgerTransaction transaction,
  ) async {
    await _ensureLocal();
    final now = _clock().toUtc();
    final local = _copyTransaction(
      transaction,
      createdAt: transaction.createdAt ?? now,
      updatedAt: now,
    );
    _replaceTransaction(local);
    _pendingTransactionIds.add(local.id);
    await _persist();
    try {
      await synchronize();
    } catch (_) {
      // The durable queue will retry when connectivity returns.
    }
    return _transactions.firstWhere((value) => value.id == local.id);
  }

  @override
  Future<LedgerTransaction> deleteTransaction(
    LedgerTransaction transaction,
  ) async {
    await _ensureLocal();
    final now = _clock().toUtc();
    final deleted = _copyTransaction(
      transaction,
      createdAt: transaction.createdAt ?? now,
      updatedAt: now,
      deletedAt: now,
    );
    _replaceTransaction(deleted);
    _pendingTransactionIds.add(deleted.id);
    await _persist();
    try {
      await synchronize();
    } catch (_) {
      // The durable queue will retry when connectivity returns.
    }
    return _transactions.firstWhere((value) => value.id == deleted.id);
  }

  void _replaceTransaction(LedgerTransaction transaction) {
    _transactions = [
      transaction,
      ..._transactions.where((value) => value.id != transaction.id),
    ];
  }
}

Map<String, dynamic> _categoryToJson(Category category) => {
  'id': category.id,
  'name': category.name,
  'type': category.type.name,
  'counts_toward_performance': category.countsTowardPerformance,
  'translation_key': category.translationKey,
};

Category _categoryFromJson(Map<String, dynamic> json) =>
    Category.fromJson(json);

Map<String, dynamic> _sourceToJson(IncomeSource source) => {
  'id': source.id,
  'name': source.name,
};

IncomeSource _sourceFromJson(Map<String, dynamic> json) =>
    IncomeSource(json['id'] as String, json['name'] as String);

Map<String, dynamic> _transactionToJson(LedgerTransaction transaction) => {
  ...transaction.toJson(),
  'created_at': transaction.createdAt?.toIso8601String(),
  'updated_at': transaction.updatedAt?.toIso8601String(),
  'deleted_at': transaction.deletedAt?.toIso8601String(),
};

LedgerTransaction _copyTransaction(
  LedgerTransaction transaction, {
  DateTime? createdAt,
  DateTime? updatedAt,
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
  createdAt: createdAt ?? transaction.createdAt,
  updatedAt: updatedAt ?? transaction.updatedAt,
  deletedAt: deletedAt ?? transaction.deletedAt,
);
