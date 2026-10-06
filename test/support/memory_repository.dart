import 'package:gainly/core/data/ledger_repository.dart';
import 'package:gainly/core/domain/finance.dart';

class MemoryRepository implements LedgerRepository {
  Profile? profile;
  final entries = <LedgerTransaction>[];
  bool failWrites = false, failReads = false;
  @override
  Future<Profile?> loadProfile() async {
    if (failReads) throw StateError('offline');
    return profile;
  }

  @override
  Future<void> saveProfile(Profile value) async {
    if (failWrites) throw StateError('offline');
    profile = value;
  }

  @override
  Future<List<Category>> loadCategories() async => const [
    Category(
      id: 'delivery',
      name: 'Delivery',
      type: TransactionType.income,
      countsTowardPerformance: true,
      translationKey: 'delivery',
    ),
    Category(
      id: 'benefits',
      name: 'Benefits',
      type: TransactionType.income,
      countsTowardPerformance: false,
      translationKey: 'benefits',
    ),
    Category(
      id: 'food',
      name: 'Food',
      type: TransactionType.expense,
      countsTowardPerformance: true,
      translationKey: 'food',
    ),
  ];
  @override
  Future<List<IncomeSource>> loadSources() async => [];
  @override
  Future<String> saveSource(String name) async => 'source';
  @override
  Future<List<LedgerTransaction>> loadTransactions() async =>
      entries.where((entry) => entry.deletedAt == null).toList();
  @override
  Future<LedgerTransaction> saveTransaction(
    LedgerTransaction transaction,
  ) async {
    if (failWrites) throw StateError('offline');
    entries.removeWhere((t) => t.id == transaction.id);
    entries.add(transaction);
    return transaction;
  }

  @override
  Future<LedgerTransaction> deleteTransaction(
    LedgerTransaction transaction,
  ) async {
    if (failWrites) throw StateError('offline');
    final deleted = LedgerTransaction(
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
      createdAt: transaction.createdAt,
      updatedAt: DateTime.now().toUtc(),
      deletedAt: DateTime.now().toUtc(),
    );
    final index = entries.indexWhere((entry) => entry.id == transaction.id);
    if (index == -1) throw StateError('Transaction not found');
    entries[index] = deleted;
    return deleted;
  }
}
