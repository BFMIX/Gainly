import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gainly/app/ledger_controller.dart';
import 'package:gainly/core/domain/finance.dart';
import 'package:gainly/features/notifications/notification_coordinator.dart';
import 'package:gainly/features/notifications/notification_delivery.dart';

import '../support/memory_repository.dart';

class DelayedRepository extends MemoryRepository {
  Completer<List<LedgerTransaction>>? pending;
  @override
  Future<List<LedgerTransaction>> loadTransactions() =>
      pending?.future ?? super.loadTransactions();
}

class PermissionDelivery implements NotificationDelivery {
  bool permissionRequested = false;
  int cancellationCount = 0;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermission() async {
    permissionRequested = true;
    return true;
  }

  @override
  Future<void> scheduleDaily({
    required DateTime date,
    required String title,
    required String body,
  }) async {}
  @override
  Future<void> cancelDaily() async {
    cancellationCount++;
  }

  @override
  Future<void> show({required String title, required String body}) async {}
}

void main() {
  test('onboarding requests permission for default important alerts', () async {
    final delivery = PermissionDelivery();
    final controller = LedgerController(
      MemoryRepository(),
      notifications: NotificationCoordinator(delivery),
    );

    await controller.saveProfile(
      const Profile(
        userId: 'owner',
        firstName: 'Alex',
        language: 'en',
        currency: 'EUR',
      ),
    );

    expect(delivery.permissionRequested, isTrue);
    controller.dispose();
  });

  test(
    'loading an existing profile bootstraps notification permission',
    () async {
      final delivery = PermissionDelivery();
      final repository = MemoryRepository()
        ..profile = const Profile(
          userId: 'owner',
          firstName: 'Alex',
          language: 'en',
          currency: 'EUR',
        );
      final controller = LedgerController(
        repository,
        notifications: NotificationCoordinator(delivery),
      );

      await controller.load();

      expect(delivery.permissionRequested, isTrue);
      await controller.endSession();
      expect(delivery.cancellationCount, 1);
      controller.dispose();
    },
  );

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
