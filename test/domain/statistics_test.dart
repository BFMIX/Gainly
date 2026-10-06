import 'package:flutter_test/flutter_test.dart';
import 'package:gainly/core/domain/finance.dart';
import 'package:gainly/features/statistics/statistics_model.dart';

void main() {
  const profile = Profile(
    userId: 'owner',
    firstName: 'Alex',
    language: 'en',
    currency: 'EUR',
    startingBalance: 100000,
    startingPerformanceBalance: 20000,
  );

  LedgerTransaction entry({
    required String id,
    required DateTime date,
    required int amount,
    TransactionType type = TransactionType.income,
    bool included = true,
    String category = 'work',
    String? source,
    DateTime? deletedAt,
  }) => LedgerTransaction(
    id: id,
    userId: 'owner',
    amountMinor: amount,
    type: type,
    date: date,
    categoryId: category,
    sourceId: source,
    countsTowardPerformance: included,
    deletedAt: deletedAt,
  );

  test('period presets are inclusive and end on the selected day', () {
    final anchor = DateTime(2026, 10, 5, 18);

    expect(
      StatisticsRange.forPeriod(StatisticsPeriod.sevenDays, anchor: anchor),
      StatisticsRange(DateTime(2026, 9, 29), DateTime(2026, 10, 5)),
    );
    expect(
      StatisticsRange.forPeriod(StatisticsPeriod.thirtyDays, anchor: anchor),
      StatisticsRange(DateTime(2026, 9, 6), DateTime(2026, 10, 5)),
    );
    expect(
      StatisticsRange.forPeriod(StatisticsPeriod.thisMonth, anchor: anchor),
      StatisticsRange(DateTime(2026, 10, 1), DateTime(2026, 10, 5)),
    );
    expect(
      StatisticsRange.forPeriod(StatisticsPeriod.thisYear, anchor: anchor),
      StatisticsRange(DateTime(2026, 1, 1), DateTime(2026, 10, 5)),
    );
  });

  test('totals and distributions include all ledger activity in range', () {
    final model = StatisticsModel(
      profile: profile,
      transactions: [
        entry(
          id: 'old',
          date: DateTime(2026, 9, 30),
          amount: 9000,
          source: 'platform-a',
        ),
        entry(
          id: 'income-a',
          date: DateTime(2026, 10, 1),
          amount: 10000,
          category: 'delivery',
          source: 'platform-a',
        ),
        entry(
          id: 'income-b',
          date: DateTime(2026, 10, 2),
          amount: 4000,
          included: false,
          category: 'gift',
        ),
        entry(
          id: 'expense-a',
          date: DateTime(2026, 10, 2),
          amount: 3000,
          type: TransactionType.expense,
          category: 'fuel',
        ),
        entry(
          id: 'deleted',
          date: DateTime(2026, 10, 3),
          amount: 9900,
          deletedAt: DateTime(2026, 10, 4),
        ),
      ],
      range: StatisticsRange(DateTime(2026, 10, 1), DateTime(2026, 10, 5)),
    );

    expect(model.totalIncome, 14000);
    expect(model.totalExpenses, 3000);
    expect(model.performanceResult, 7000);
    expect(model.incomeByCategory, {'delivery': 10000, 'gift': 4000});
    expect(model.expensesByCategory, {'fuel': 3000});
    expect(model.incomeBySource, {'platform-a': 10000, null: 4000});
  });

  test(
    'daily states and positive day rate use performance-active days only',
    () {
      final model = StatisticsModel(
        profile: profile,
        transactions: [
          entry(id: 'p', date: DateTime(2026, 10, 1), amount: 1000),
          entry(id: 'z1', date: DateTime(2026, 10, 2), amount: 500),
          entry(
            id: 'z2',
            date: DateTime(2026, 10, 2),
            amount: 500,
            type: TransactionType.expense,
          ),
          entry(
            id: 'n',
            date: DateTime(2026, 10, 3),
            amount: 200,
            type: TransactionType.expense,
          ),
          entry(
            id: 'excluded',
            date: DateTime(2026, 10, 4),
            amount: 400,
            included: false,
          ),
        ],
        range: StatisticsRange(DateTime(2026, 10, 1), DateTime(2026, 10, 5)),
      );

      expect(model.dayStateCounts[DayState.positive], 1);
      expect(model.dayStateCounts[DayState.zeroAfterActivity], 1);
      expect(model.dayStateCounts[DayState.negative], 1);
      expect(model.dayStateCounts[DayState.noActivity], 2);
      expect(model.positiveDayRate, closeTo(1 / 3, 0.0001));
      expect(model.longestPositiveStreak, 1);
    },
  );

  test('balanced and inactive days preserve a positive streak', () {
    final model = StatisticsModel(
      profile: profile,
      transactions: [
        entry(id: 'p1', date: DateTime(2026, 10, 1), amount: 100),
        entry(id: 'z1', date: DateTime(2026, 10, 2), amount: 100),
        entry(
          id: 'z2',
          date: DateTime(2026, 10, 2),
          amount: 100,
          type: TransactionType.expense,
        ),
        entry(id: 'p2', date: DateTime(2026, 10, 4), amount: 100),
        entry(
          id: 'negative',
          date: DateTime(2026, 10, 5),
          amount: 100,
          type: TransactionType.expense,
        ),
        entry(id: 'p3', date: DateTime(2026, 10, 6), amount: 100),
      ],
      range: StatisticsRange(DateTime(2026, 10, 1), DateTime(2026, 10, 6)),
    );

    expect(model.longestPositiveStreak, 2);
  });

  test('daily weekly and monthly result series use included activity', () {
    final model = StatisticsModel(
      profile: profile,
      transactions: [
        entry(id: 'sun', date: DateTime(2026, 9, 27), amount: 100),
        entry(id: 'mon', date: DateTime(2026, 9, 28), amount: 200),
        entry(
          id: 'oct',
          date: DateTime(2026, 10, 1),
          amount: 50,
          type: TransactionType.expense,
        ),
        entry(
          id: 'ignored',
          date: DateTime(2026, 10, 1),
          amount: 999,
          included: false,
        ),
      ],
      range: StatisticsRange(DateTime(2026, 9, 27), DateTime(2026, 10, 2)),
    );

    expect(model.dailyResults[DateTime(2026, 9, 27)], 100);
    expect(model.dailyResults[DateTime(2026, 10, 1)], -50);
    expect(model.weeklyResults[DateTime(2026, 9, 21)], 100);
    expect(model.weeklyResults[DateTime(2026, 9, 28)], 150);
    expect(model.monthlyResults, {
      DateTime(2026, 9, 1): 300,
      DateTime(2026, 10, 1): -50,
    });
  });

  test('performance balance evolution begins with activity before range', () {
    final model = StatisticsModel(
      profile: profile,
      transactions: [
        entry(id: 'before', date: DateTime(2026, 9, 30), amount: 500),
        entry(id: 'first', date: DateTime(2026, 10, 1), amount: 1000),
        entry(
          id: 'second',
          date: DateTime(2026, 10, 2),
          amount: 300,
          type: TransactionType.expense,
        ),
      ],
      range: StatisticsRange(DateTime(2026, 10, 1), DateTime(2026, 10, 3)),
    );

    expect(model.performanceBalanceEvolution, [
      StatisticsPoint(DateTime(2026, 10, 1), 21500),
      StatisticsPoint(DateTime(2026, 10, 2), 21200),
      StatisticsPoint(DateTime(2026, 10, 3), 21200),
    ]);
  });

  test('missing performance baseline keeps evolution unknown', () {
    final model = StatisticsModel(
      profile: const Profile(
        userId: 'owner',
        firstName: 'Alex',
        language: 'en',
        currency: 'EUR',
      ),
      transactions: [
        entry(id: 'income', date: DateTime(2026, 10, 1), amount: 1000),
      ],
      range: StatisticsRange(DateTime(2026, 10, 1), DateTime(2026, 10, 2)),
    );

    expect(model.performanceBalance, isNull);
    expect(model.performanceBalanceEvolution.map((point) => point.value), [
      null,
      null,
    ]);
  });
}
