import 'package:flutter_test/flutter_test.dart';
import 'package:gainly/core/domain/finance.dart';
import 'package:gainly/features/goals/domain/goals_progress.dart';

void main() {
  const engine = GoalsProgressEngine();
  final asOf = DateTime(2026, 4, 21, 12);

  LedgerTransaction entry({
    required String id,
    required int amount,
    required DateTime date,
    TransactionType type = TransactionType.income,
    bool included = true,
    String categoryId = 'category',
    DateTime? deletedAt,
  }) => LedgerTransaction(
    id: id,
    userId: 'owner',
    amountMinor: amount,
    type: type,
    date: date,
    categoryId: categoryId,
    countsTowardPerformance: included,
    deletedAt: deletedAt,
  );

  group('monthly target and daily minimum', () {
    test('reads persisted goal settings from a profile', () {
      final result = engine.evaluateForProfile(
        asOf: asOf,
        profile: const Profile(
          userId: 'owner',
          firstName: 'Alex',
          language: 'en',
          currency: 'EUR',
          startingPerformanceBalance: 5000,
          monthlyTarget: 150000,
          dailyMinimum: 6000,
        ),
        transactions: [entry(id: 'today', amount: 2500, date: asOf)],
      );

      expect(result.monthlyTarget!.targetMinor, 150000);
      expect(result.dailyMinimum!.effectiveMinor, 6000);
      expect(result.insights, isNotEmpty);
    });

    test('uses gross included performance income for monthly progress', () {
      final result = engine.evaluate(
        asOf: asOf,
        monthlyTargetMinor: 150000,
        transactions: [
          entry(id: 'earned', amount: 90000, date: DateTime(2026, 4, 10)),
          entry(
            id: 'expense',
            amount: 70000,
            date: DateTime(2026, 4, 11),
            type: TransactionType.expense,
          ),
          entry(
            id: 'excluded',
            amount: 99000,
            date: DateTime(2026, 4, 12),
            included: false,
          ),
          entry(id: 'old', amount: 50000, date: DateTime(2026, 3, 31)),
          entry(id: 'future', amount: 50000, date: DateTime(2026, 4, 22)),
          entry(
            id: 'deleted',
            amount: 50000,
            date: DateTime(2026, 4, 13),
            deletedAt: DateTime(2026, 4, 14),
          ),
        ],
      );

      expect(result.monthlyTarget!.earnedMinor, 90000);
      expect(result.monthlyTarget!.remainingMinor, 60000);
      expect(result.monthlyTarget!.daysRemaining, 10);
      expect(result.monthlyTarget!.requiredDailyPaceMinor, 6000);
      expect(result.monthlyTarget!.completionBasisPoints, 6000);
    });

    test('rounds pace up in minor units and handles reached targets', () {
      final pending = engine
          .evaluate(
            asOf: DateTime(2026, 2, 27),
            monthlyTargetMinor: 10000,
            transactions: [
              entry(id: 'income', amount: 9999, date: DateTime(2026, 2, 1)),
            ],
          )
          .monthlyTarget!;
      expect(pending.daysRemaining, 2);
      expect(pending.requiredDailyPaceMinor, 1);

      final reached = engine
          .evaluate(
            asOf: asOf,
            monthlyTargetMinor: 10000,
            transactions: [
              entry(id: 'income', amount: 12000, date: DateTime(2026, 4, 1)),
            ],
          )
          .monthlyTarget!;
      expect(reached.remainingMinor, 0);
      expect(reached.requiredDailyPaceMinor, 0);
      expect(reached.completionBasisPoints, 12000);
      expect(reached.isReached, isTrue);
    });

    test('recommends target divided by 30 without replacing manual value', () {
      final suggested = engine
          .evaluate(
            asOf: asOf,
            monthlyTargetMinor: 10000,
            transactions: const [],
          )
          .dailyMinimum!;
      expect(suggested.recommendedMinor, 334);
      expect(suggested.configuredMinor, isNull);
      expect(suggested.effectiveMinor, 334);
      expect(suggested.isUsingRecommendation, isTrue);

      final manual = engine
          .evaluate(
            asOf: asOf,
            monthlyTargetMinor: 10000,
            dailyMinimumMinor: 6000,
            transactions: [entry(id: 'today', amount: 2500, date: asOf)],
          )
          .dailyMinimum!;
      expect(manual.recommendedMinor, 334);
      expect(manual.effectiveMinor, 6000);
      expect(manual.earnedTodayMinor, 2500);
      expect(manual.remainingTodayMinor, 3500);
      expect(manual.isUsingRecommendation, isFalse);
    });
  });

  group('streaks and positive day rate', () {
    test('positive streak follows the four-state rules', () {
      final result = engine.evaluate(
        asOf: DateTime(2026, 4, 5),
        transactions: [
          entry(id: 'p1', amount: 4000, date: DateTime(2026, 4, 1)),
          entry(id: 'p2', amount: 2500, date: DateTime(2026, 4, 2)),
          entry(id: 'z1', amount: 1000, date: DateTime(2026, 4, 3)),
          entry(
            id: 'z2',
            amount: 1000,
            date: DateTime(2026, 4, 3),
            type: TransactionType.expense,
          ),
          entry(id: 'p3', amount: 3000, date: DateTime(2026, 4, 4)),
          entry(
            id: 'n1',
            amount: 1500,
            date: DateTime(2026, 4, 5),
            type: TransactionType.expense,
          ),
        ],
      );
      expect(result.streaks.positiveStreak, 0);

      final beforeNegative = engine.evaluate(
        asOf: DateTime(2026, 4, 4),
        transactions: result.transactions,
      );
      expect(beforeNegative.streaks.positiveStreak, 3);
    });

    test('positive rate excludes no-activity and included false days', () {
      final transactions = <LedgerTransaction>[];
      for (var day = 1; day <= 6; day++) {
        transactions.add(
          entry(id: 'positive-$day', amount: 100, date: DateTime(2026, 4, day)),
        );
      }
      for (var day = 7; day <= 8; day++) {
        transactions
          ..add(
            entry(
              id: 'zero-in-$day',
              amount: 100,
              date: DateTime(2026, 4, day),
            ),
          )
          ..add(
            entry(
              id: 'zero-out-$day',
              amount: 100,
              date: DateTime(2026, 4, day),
              type: TransactionType.expense,
            ),
          );
      }
      for (var day = 9; day <= 10; day++) {
        transactions.add(
          entry(
            id: 'negative-$day',
            amount: 100,
            date: DateTime(2026, 4, day),
            type: TransactionType.expense,
          ),
        );
      }
      transactions.add(
        entry(
          id: 'excluded',
          amount: 100,
          date: DateTime(2026, 4, 11),
          included: false,
        ),
      );

      final rate = engine
          .evaluate(asOf: DateTime(2026, 4, 12), transactions: transactions)
          .streaks;
      expect(rate.positiveDays, 6);
      expect(rate.performanceActiveDays, 10);
      expect(rate.positiveDayRateBasisPoints, 6000);
    });

    test(
      'tracking streak counts recorded days and tolerates unfinished today',
      () {
        final transactions = [
          entry(
            id: 'one',
            amount: 100,
            date: DateTime(2026, 4, 18),
            included: false,
          ),
          entry(
            id: 'two',
            amount: 100,
            date: DateTime(2026, 4, 19),
            included: false,
          ),
          entry(
            id: 'three',
            amount: 100,
            date: DateTime(2026, 4, 20),
            included: false,
          ),
        ];
        expect(
          engine
              .evaluate(asOf: asOf, transactions: transactions)
              .streaks
              .trackingStreak,
          3,
        );
        expect(
          engine
              .evaluate(asOf: DateTime(2026, 4, 22), transactions: transactions)
              .streaks
              .trackingStreak,
          0,
        );
      },
    );
  });

  group('smart insights', () {
    test(
      'returns at most two typed insights in deterministic priority order',
      () {
        final transactions = [
          for (var day = 18; day <= 20; day++)
            entry(
              id: 'negative-$day',
              amount: 1000,
              date: DateTime(2026, 4, day),
              type: TransactionType.expense,
            ),
        ];
        final result = engine.evaluate(
          asOf: asOf,
          monthlyTargetMinor: 150000,
          startingPerformanceBalanceMinor: 1000,
          transactions: transactions,
        );

        expect(result.insights, hasLength(2));
        expect(
          result.insights.first.kind,
          SmartInsightKind.performanceBalanceRisk,
        );
        expect(
          result.insights.last.kind,
          SmartInsightKind.consecutiveNegativeDays,
        );
        expect(result.insights.last.dayCount, 3);
      },
    );

    test('reports target position and required pace with typed amounts', () {
      final result = engine.evaluate(
        asOf: asOf,
        monthlyTargetMinor: 150000,
        transactions: [
          entry(id: 'income', amount: 90000, date: DateTime(2026, 4, 10)),
        ],
      );

      expect(result.insights.first.kind, SmartInsightKind.behindMonthlyTarget);
      expect(result.insights.first.amountMinor, 15000);
      expect(result.insights.last.kind, SmartInsightKind.requiredDailyPace);
      expect(result.insights.last.amountMinor, 6000);
    });
  });
}
