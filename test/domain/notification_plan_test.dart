import 'package:flutter_test/flutter_test.dart';
import 'package:gainly/core/domain/finance.dart';
import 'package:gainly/core/domain/notification_preferences.dart';
import 'package:gainly/features/notifications/domain/notification_plan.dart';

void main() {
  const engine = NotificationPlanEngine();
  const defaults = NotificationPreferences();

  LedgerTransaction entry({
    required String id,
    required DateTime date,
    required int amount,
    TransactionType type = TransactionType.income,
  }) => LedgerTransaction(
    id: id,
    userId: 'owner',
    amountMinor: amount,
    type: type,
    date: date,
    categoryId: type == TransactionType.income ? 'delivery' : 'fuel',
    countsTowardPerformance: true,
  );

  test('important notifications default on at 20:00', () {
    expect(defaults.dailyReminder, isTrue);
    expect(defaults.negativeDaysWarning, isTrue);
    expect(defaults.performanceBalanceWarning, isTrue);
    expect(defaults.reminderMinutes, 20 * 60);
    expect(defaults.streakEncouragement, isFalse);
    expect(defaults.badgeAchievements, isFalse);
    expect(defaults.goalProgress, isFalse);
    expect(defaults.positiveMilestones, isFalse);
  });

  test('daily reminder uses today before 20:00 when no activity exists', () {
    final plan = engine.dailyReminder(
      asOf: DateTime(2026, 10, 6, 18, 30),
      preferences: defaults,
      transactions: const [],
    );

    expect(plan, DateTime(2026, 10, 6, 20));
  });

  test('daily reminder moves to tomorrow after activity or reminder time', () {
    final active = engine.dailyReminder(
      asOf: DateTime(2026, 10, 6, 18),
      preferences: defaults,
      transactions: [
        entry(id: 'today', date: DateTime(2026, 10, 6), amount: 100),
      ],
    );
    final late = engine.dailyReminder(
      asOf: DateTime(2026, 10, 6, 21),
      preferences: defaults,
      transactions: const [],
    );

    expect(active, DateTime(2026, 10, 7, 20));
    expect(late, DateTime(2026, 10, 7, 20));
  });

  test('third consecutive negative day triggers one warning', () {
    final previous = [
      entry(
        id: 'day-1',
        date: DateTime(2026, 10, 4),
        amount: 100,
        type: TransactionType.expense,
      ),
      entry(
        id: 'day-2',
        date: DateTime(2026, 10, 5),
        amount: 100,
        type: TransactionType.expense,
      ),
    ];
    final current = [
      ...previous,
      entry(
        id: 'day-3',
        date: DateTime(2026, 10, 6),
        amount: 100,
        type: TransactionType.expense,
      ),
    ];

    expect(
      engine.financialAlert(
        asOf: DateTime(2026, 10, 6),
        profile: const Profile(
          userId: 'owner',
          firstName: 'Alex',
          language: 'en',
          currency: 'EUR',
          startingPerformanceBalance: 10000,
        ),
        previousTransactions: previous,
        currentTransactions: current,
        preferences: defaults,
      ),
      NotificationKind.negativeDays,
    );
  });

  test('crossing zero takes priority over a negative-day warning', () {
    final previous = [
      entry(
        id: 'day-1',
        date: DateTime(2026, 10, 4),
        amount: 300,
        type: TransactionType.expense,
      ),
      entry(
        id: 'day-2',
        date: DateTime(2026, 10, 5),
        amount: 300,
        type: TransactionType.expense,
      ),
    ];
    final current = [
      ...previous,
      entry(
        id: 'day-3',
        date: DateTime(2026, 10, 6),
        amount: 500,
        type: TransactionType.expense,
      ),
    ];

    expect(
      engine.financialAlert(
        asOf: DateTime(2026, 10, 6),
        profile: const Profile(
          userId: 'owner',
          firstName: 'Alex',
          language: 'en',
          currency: 'EUR',
          startingPerformanceBalance: 1000,
        ),
        previousTransactions: previous,
        currentTransactions: current,
        preferences: defaults,
      ),
      NotificationKind.performanceBalanceRisk,
    );
  });

  test(
    'optional goal progress is emitted once when the monthly target is reached',
    () {
      final previous = [
        entry(id: 'first', date: DateTime(2026, 10, 6), amount: 900),
      ];
      final current = [
        ...previous,
        entry(id: 'target', date: DateTime(2026, 10, 6), amount: 100),
      ];

      expect(
        engine.financialAlert(
          asOf: DateTime(2026, 10, 6),
          profile: const Profile(
            userId: 'owner',
            firstName: 'Alex',
            language: 'en',
            currency: 'EUR',
            monthlyTarget: 1000,
          ),
          previousTransactions: previous,
          currentTransactions: current,
          preferences: const NotificationPreferences(goalProgress: true),
        ),
        NotificationKind.monthlyTargetReached,
      );
    },
  );

  test('optional badge and positive milestone rules remain off by default', () {
    final first = entry(id: 'first', date: DateTime(2026, 10, 6), amount: 200);
    const profile = Profile(
      userId: 'owner',
      firstName: 'Alex',
      language: 'en',
      currency: 'EUR',
      startingPerformanceBalance: 9900,
    );

    expect(
      engine.financialAlert(
        asOf: DateTime(2026, 10, 6),
        profile: profile,
        previousTransactions: const [],
        currentTransactions: [first],
        preferences: defaults,
      ),
      isNull,
    );
    expect(
      engine.financialAlert(
        asOf: DateTime(2026, 10, 6),
        profile: profile,
        previousTransactions: const [],
        currentTransactions: [first],
        preferences: const NotificationPreferences(badgeAchievements: true),
      ),
      NotificationKind.achievementFirstEntry,
    );
    expect(
      engine.financialAlert(
        asOf: DateTime(2026, 10, 6),
        profile: profile,
        previousTransactions: const [],
        currentTransactions: [first],
        preferences: const NotificationPreferences(positiveMilestones: true),
      ),
      NotificationKind.positiveMilestone,
    );
  });

  test('strong drops and approaching zero trigger the balance warning', () {
    const profile = Profile(
      userId: 'owner',
      firstName: 'Alex',
      language: 'en',
      currency: 'EUR',
      startingPerformanceBalance: 20000,
    );
    final strongDrop = entry(
      id: 'strong-drop',
      date: DateTime(2026, 10, 6),
      amount: 6000,
      type: TransactionType.expense,
    );
    final nearZero = entry(
      id: 'near-zero',
      date: DateTime(2026, 10, 6),
      amount: 19500,
      type: TransactionType.expense,
    );

    for (final current in [strongDrop, nearZero]) {
      expect(
        engine.financialAlert(
          asOf: DateTime(2026, 10, 6),
          profile: profile,
          previousTransactions: const [],
          currentTransactions: [current],
          preferences: defaults,
        ),
        NotificationKind.performanceBalanceRisk,
      );
    }
  });

  test('negative-day warnings require adjacent calendar days', () {
    final current = [
      entry(
        id: 'old',
        date: DateTime(2026, 10, 1),
        amount: 100,
        type: TransactionType.expense,
      ),
      entry(
        id: 'recent-1',
        date: DateTime(2026, 10, 3),
        amount: 100,
        type: TransactionType.expense,
      ),
      entry(
        id: 'recent-2',
        date: DateTime(2026, 10, 4),
        amount: 100,
        type: TransactionType.expense,
      ),
    ];

    expect(
      engine.financialAlert(
        asOf: DateTime(2026, 10, 4),
        profile: const Profile(
          userId: 'owner',
          firstName: 'Alex',
          language: 'en',
          currency: 'EUR',
          startingPerformanceBalance: 10000,
        ),
        previousTransactions: current.take(2),
        currentTransactions: current,
        preferences: defaults,
      ),
      isNull,
    );
  });
}
