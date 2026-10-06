import 'package:flutter_test/flutter_test.dart';
import 'package:gainly/core/data/cached_ledger_repository.dart';
import 'package:gainly/core/domain/finance.dart';

import '../../support/memory_repository.dart';

class TestLedgerLocalStore implements LedgerLocalStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String userId) async => values[userId];

  @override
  Future<void> write(String userId, String value) async {
    values[userId] = value;
  }
}

void main() {
  const profile = Profile(
    userId: 'owner',
    firstName: 'Alex',
    language: 'en',
    currency: 'EUR',
    startingBalance: 0,
    startingPerformanceBalance: 0,
  );

  LedgerTransaction transaction(String id, int amount) => LedgerTransaction(
    id: id,
    userId: 'owner',
    amountMinor: amount,
    type: TransactionType.income,
    date: DateTime(2026, 10, 6),
    categoryId: 'delivery',
    countsTowardPerformance: true,
  );

  test(
    'cached ledger remains readable after restart without network',
    () async {
      final remote = MemoryRepository()
        ..profile = profile
        ..entries.add(transaction('remote', 2500));
      final store = TestLedgerLocalStore();
      final first = CachedLedgerRepository(
        userId: 'owner',
        remote: remote,
        store: store,
      );

      expect((await first.loadProfile())?.firstName, profile.firstName);
      expect(await first.loadCategories(), isNotEmpty);
      expect(await first.loadTransactions(), hasLength(1));

      remote.failReads = true;
      final restarted = CachedLedgerRepository(
        userId: 'owner',
        remote: remote,
        store: store,
      );

      expect((await restarted.loadProfile())?.firstName, profile.firstName);
      expect((await restarted.loadTransactions()).single.id, 'remote');
      expect(restarted.isOffline, isTrue);
    },
  );

  test('offline transaction survives restart and synchronizes later', () async {
    final remote = MemoryRepository()..profile = profile;
    final store = TestLedgerLocalStore();
    final first = CachedLedgerRepository(
      userId: 'owner',
      remote: remote,
      store: store,
    );
    await first.loadProfile();
    await first.loadTransactions();

    remote.failWrites = true;
    final saved = await first.saveTransaction(transaction('offline', 4200));
    expect(saved.id, 'offline');
    expect(first.pendingChanges, 1);
    expect(first.isOffline, isTrue);

    final restarted = CachedLedgerRepository(
      userId: 'owner',
      remote: remote,
      store: store,
    );
    expect((await restarted.loadProfile())?.userId, 'owner');
    expect((await restarted.loadTransactions()).single.id, 'offline');
    expect(restarted.pendingChanges, 1);

    remote
      ..failWrites = false
      ..failReads = false;
    await restarted.synchronize();

    expect(restarted.pendingChanges, 0);
    expect(restarted.isOffline, isFalse);
    expect(remote.entries.single.id, 'offline');
    expect(remote.entries.single.amountMinor, 4200);
  });

  test('multiple offline edits collapse to the latest transaction', () async {
    final remote = MemoryRepository()..profile = profile;
    final store = TestLedgerLocalStore();
    final repository = CachedLedgerRepository(
      userId: 'owner',
      remote: remote,
      store: store,
    );
    await repository.loadProfile();
    remote.failWrites = true;

    await repository.saveTransaction(transaction('same', 1000));
    await repository.saveTransaction(transaction('same', 3500));

    expect(repository.pendingChanges, 1);
    expect((await repository.loadTransactions()).single.amountMinor, 3500);
    remote.failWrites = false;
    await repository.synchronize();
    expect(remote.entries.single.amountMinor, 3500);
  });

  test(
    'offline deletion stays hidden and synchronizes as a tombstone',
    () async {
      final original = transaction('delete-me', 1800);
      final remote = MemoryRepository()
        ..profile = profile
        ..entries.add(original);
      final store = TestLedgerLocalStore();
      final repository = CachedLedgerRepository(
        userId: 'owner',
        remote: remote,
        store: store,
      );
      await repository.loadProfile();
      remote.failWrites = true;

      await repository.deleteTransaction(original);

      expect(await repository.loadTransactions(), isEmpty);
      expect(repository.pendingChanges, 1);

      remote.failWrites = false;
      await repository.synchronize();
      expect(repository.pendingChanges, 0);
      expect(remote.entries.single.deletedAt, isNotNull);
    },
  );

  test(
    'profile, category, and source changes queue before transactions',
    () async {
      final remote = MemoryRepository()..profile = profile;
      final store = TestLedgerLocalStore();
      final repository = CachedLedgerRepository(
        userId: 'owner',
        remote: remote,
        store: store,
      );
      await repository.loadProfile();
      remote.failWrites = true;

      const editedProfile = Profile(
        userId: 'owner',
        firstName: 'Alexandra',
        language: 'fr',
        currency: 'EUR',
        startingBalance: 0,
        startingPerformanceBalance: 0,
      );
      const category = Category(
        id: 'custom-category',
        name: 'Consulting',
        type: TransactionType.income,
        countsTowardPerformance: true,
      );
      const source = IncomeSource('custom-source', 'Client A');
      await repository.saveProfile(editedProfile);
      await repository.saveCategory(category);
      await repository.saveSource(source);
      await repository.saveTransaction(
        LedgerTransaction(
          id: 'dependent-transaction',
          userId: 'owner',
          amountMinor: 9000,
          type: TransactionType.income,
          date: DateTime(2026, 10, 6),
          categoryId: category.id,
          sourceId: source.id,
          countsTowardPerformance: true,
        ),
      );

      expect(repository.pendingChanges, 4);
      expect((await repository.loadProfile())?.firstName, 'Alexandra');
      expect(
        (await repository.loadCategories()).any(
          (value) => value.id == category.id,
        ),
        isTrue,
      );
      expect((await repository.loadSources()).single.id, source.id);

      remote.failWrites = false;
      await repository.synchronize();

      expect(repository.pendingChanges, 0);
      expect(remote.profile?.firstName, 'Alexandra');
      expect(remote.categories.any((value) => value.id == category.id), isTrue);
      expect(remote.sources.single.id, source.id);
      expect(remote.entries.single.sourceId, source.id);
    },
  );
}
