import 'package:flutter_test/flutter_test.dart';
import 'package:gainly/core/domain/finance.dart';

void main() {
  final day = DateTime(2026, 10, 5);
  const profile = Profile(
    userId: 'owner',
    firstName: 'Alex',
    language: 'en',
    currency: 'EUR',
    startingBalance: 100000,
    startingPerformanceBalance: 25000,
  );
  LedgerTransaction entry(
    int amount, {
    TransactionType type = TransactionType.income,
    bool included = true,
    DateTime? deleted,
  }) => LedgerTransaction(
    id: 'id',
    userId: 'owner',
    amountMinor: amount,
    type: type,
    date: day,
    categoryId: 'category',
    countsTowardPerformance: included,
    deletedAt: deleted,
  );
  test('decimal parsing remains exact and accepts comma decimals', () {
    expect(parseMoney('0.29'), 29);
    expect(parseMoney('12,5'), 1250);
    expect(parseMoney('-0.01', allowNegative: true), -1);
    expect(parseMoney(' 100 '), 10000);
  });
  test('invalid or unsafe amounts are rejected instead of rounded', () {
    for (final value in [
      '1.001',
      '1e6',
      'NaN',
      '-1',
      '1,000.00',
      '',
      '90000000000.01',
      '999999999999999999999',
    ]) {
      expect(() => parseMoney(value), throwsFormatException, reason: value);
    }
  });
  test('money input preserves negative fractional values', () {
    expect(moneyInput(-1), '-0.01');
    expect(moneyInput(null), '');
    expect(parseMoney(moneyInput(maxMinorAmount)), maxMinorAmount);
  });
  test('real and performance balances are independent', () {
    final summary = FinancialSummary(profile, [
      entry(10000),
      entry(50000, included: false),
      entry(3000, type: TransactionType.expense),
      entry(2000, type: TransactionType.expense, included: false),
    ]);
    expect(summary.balance, 155000);
    expect(summary.performanceBalance, 32000);
    expect(summary.incomeOn(day), 60000);
    expect(summary.expensesOn(day), 5000);
    expect(summary.resultOn(day), 7000);
  });
  test('missing baselines remain unknown even with transactions', () {
    final summary = FinancialSummary(
      const Profile(
        userId: 'owner',
        firstName: 'Alex',
        language: 'en',
        currency: 'EUR',
      ),
      [entry(100)],
    );
    expect(summary.balance, isNull);
    expect(summary.performanceBalance, isNull);
    expect(summary.resultOn(day), 100);
  });
  test('explicit zero is configured, independent from missing baseline', () {
    final summary = FinancialSummary(
      const Profile(
        userId: 'owner',
        firstName: 'Alex',
        language: 'en',
        currency: 'EUR',
        startingBalance: 0,
      ),
      [entry(100)],
    );
    expect(summary.balance, 100);
    expect(summary.performanceBalance, isNull);
  });
  test('soft deletion excludes transactions from every aggregate', () {
    final summary = FinancialSummary(profile, [entry(5000, deleted: day)]);
    expect(summary.balance, 100000);
    expect(summary.performanceBalance, 25000);
    expect(summary.incomeOn(day), 0);
    expect(summary.stateOn(day), DayState.noActivity);
  });
  test('four daily states are distinct', () {
    expect(
      FinancialSummary(profile, [entry(100)]).stateOn(day),
      DayState.positive,
    );
    expect(
      FinancialSummary(profile, [
        entry(100),
        entry(100, type: TransactionType.expense),
      ]).stateOn(day),
      DayState.zeroAfterActivity,
    );
    expect(
      FinancialSummary(profile, [entry(100, included: false)]).stateOn(day),
      DayState.noActivity,
    );
    expect(
      FinancialSummary(profile, [
        entry(100, type: TransactionType.expense),
      ]).stateOn(day),
      DayState.negative,
    );
    expect(
      FinancialSummary(profile, [
        entry(100),
      ]).stateOn(day.add(const Duration(days: 1))),
      DayState.noActivity,
    );
  });
  test('calendar grouping ignores time of day', () {
    expect(dateKey(DateTime(2026, 1, 2, 23, 59)), '2026-01-02');
  });
  test('profile goal settings round-trip through persistence JSON', () {
    final value = Profile.fromJson({
      'user_id': 'owner',
      'first_name': 'Alex',
      'language': 'en',
      'currency': 'EUR',
      'starting_balance_minor': 100,
      'starting_performance_balance_minor': 200,
      'monthly_target_minor': 150000,
      'daily_minimum_minor': 6000,
    });
    expect(value.monthlyTarget, 150000);
    expect(value.dailyMinimum, 6000);
    expect(value.toJson()['monthly_target_minor'], 150000);
    expect(value.toJson()['daily_minimum_minor'], 6000);
  });
}
