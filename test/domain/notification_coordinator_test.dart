import 'package:flutter_test/flutter_test.dart';
import 'package:gainly/core/domain/finance.dart';
import 'package:gainly/core/domain/notification_preferences.dart';
import 'package:gainly/features/notifications/notification_coordinator.dart';
import 'package:gainly/features/notifications/notification_delivery.dart';

class FakeNotificationDelivery implements NotificationDelivery {
  bool permissionRequested = false;
  DateTime? dailyDate;
  int cancellationCount = 0;
  String? dailyTitle;
  String? shownTitle;

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
  }) async {
    dailyDate = date;
    dailyTitle = title;
  }

  @override
  Future<void> cancelDaily() async {
    cancellationCount++;
    dailyDate = null;
  }

  @override
  Future<void> show({required String title, required String body}) async {
    shownTitle = title;
  }
}

void main() {
  const profile = Profile(
    userId: 'owner',
    firstName: 'Alex',
    language: 'fr',
    currency: 'EUR',
    startingPerformanceBalance: 100,
  );

  test(
    'saving enabled preferences requests permission and schedules locally',
    () async {
      final delivery = FakeNotificationDelivery();
      final coordinator = NotificationCoordinator(
        delivery,
        clock: () => DateTime(2026, 10, 7, 19),
      );

      await coordinator.applyPreferences(
        profile: profile,
        preferences: const NotificationPreferences(),
        transactions: const [],
      );

      expect(delivery.permissionRequested, isTrue);
      expect(delivery.dailyDate, DateTime(2026, 10, 7, 20));
      expect(delivery.dailyTitle, 'Comment s’est passée ta journée ?');
    },
  );

  test('a zero crossing emits the localized priority alert', () async {
    final delivery = FakeNotificationDelivery();
    final coordinator = NotificationCoordinator(
      delivery,
      clock: () => DateTime(2026, 10, 7, 12),
    );
    final expense = LedgerTransaction(
      id: 'expense',
      userId: 'owner',
      amountMinor: 100,
      type: TransactionType.expense,
      date: DateTime(2026, 10, 7),
      categoryId: 'food',
      countsTowardPerformance: true,
    );

    await coordinator.afterFinancialChange(
      profile: profile,
      preferences: const NotificationPreferences(),
      previousTransactions: const [],
      currentTransactions: [expense],
    );

    expect(delivery.shownTitle, 'Alerte Performance Balance');
    expect(delivery.dailyDate, DateTime(2026, 10, 8, 20));
  });

  test('ending a session cancels the account reminder', () async {
    final delivery = FakeNotificationDelivery();
    final coordinator = NotificationCoordinator(delivery);

    await coordinator.endSession();

    expect(delivery.cancellationCount, 1);
  });
}
