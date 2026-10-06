import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gainly/app/ledger_controller.dart';
import 'package:gainly/core/domain/finance.dart';

import '../support/memory_repository.dart';

class DelayedRepository extends MemoryRepository {
  Completer<List<LedgerTransaction>>? pending;
  @override
  Future<List<LedgerTransaction>> loadTransactions() =>
      pending?.future ?? super.loadTransactions();
}

void main() {
  test('late refresh cannot overwrite a confirmed save', () async {
    final repo = DelayedRepository()
      ..profile = const Profile(
        userId: 'owner',
        firstName: 'Alex',
        language: 'en',
        currency: 'EUR',
      );
    final controller = LedgerController(repo);
    await controller.load();
    repo.pending = Completer<List<LedgerTransaction>>();
    final refresh = controller.load();
    await Future<void>.delayed(Duration.zero);
    final transaction = LedgerTransaction(
      id: 'new',
      userId: 'owner',
      amountMinor: 100,
      type: TransactionType.income,
      date: DateTime(2026),
      categoryId: 'delivery',
      countsTowardPerformance: true,
    );
    await controller.saveTransaction(transaction);
    repo.pending!.complete([]);
    await refresh;
    expect(controller.transactions.single.id, 'new');
    expect(controller.loading, isFalse);
    controller.dispose();
  });
  test('failed refresh preserves loaded user data', () async {
    final repo = MemoryRepository()
      ..profile = const Profile(
        userId: 'owner',
        firstName: 'Alex',
        language: 'en',
        currency: 'EUR',
      );
    final controller = LedgerController(repo);
    await controller.load();
    repo.failReads = true;
    await controller.load();
    expect(controller.failed, isTrue);
    expect(controller.profile?.userId, 'owner');
    controller.dispose();
  });
  test('retrying a confirmed transaction ID does not double count', () async {
    final repo = MemoryRepository();
    final controller = LedgerController(repo);
    final transaction = LedgerTransaction(
      id: 'stable-id',
      userId: 'owner',
      amountMinor: 100,
      type: TransactionType.income,
      date: DateTime(2026),
      categoryId: 'delivery',
      countsTowardPerformance: true,
    );
    await controller.saveTransaction(transaction);
    await controller.saveTransaction(transaction);
    expect(controller.transactions.length, 1);
    expect(repo.entries.length, 1);
    controller.dispose();
  });
}
