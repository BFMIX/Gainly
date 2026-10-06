import '../../core/domain/finance.dart';

enum StatisticsPeriod { sevenDays, thirtyDays, thisMonth, thisYear, custom }

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

class StatisticsRange {
  StatisticsRange(DateTime start, DateTime end)
    : start = _day(start),
      end = _day(end) {
    if (this.end.isBefore(this.start)) {
      throw ArgumentError.value(end, 'end', 'Must not be before start');
    }
  }

  factory StatisticsRange.forPeriod(
    StatisticsPeriod period, {
    required DateTime anchor,
    StatisticsRange? custom,
  }) {
    final end = _day(anchor);
    return switch (period) {
      StatisticsPeriod.sevenDays => StatisticsRange(
        end.subtract(const Duration(days: 6)),
        end,
      ),
      StatisticsPeriod.thirtyDays => StatisticsRange(
        end.subtract(const Duration(days: 29)),
        end,
      ),
      StatisticsPeriod.thisMonth => StatisticsRange(
        DateTime(end.year, end.month),
        end,
      ),
      StatisticsPeriod.thisYear => StatisticsRange(DateTime(end.year), end),
      StatisticsPeriod.custom =>
        custom ?? (throw ArgumentError.notNull('custom')),
    };
  }

  final DateTime start;
  final DateTime end;

  Iterable<DateTime> get days sync* {
    for (
      var date = start;
      !date.isAfter(end);
      date = date.add(const Duration(days: 1))
    ) {
      yield date;
    }
  }

  bool contains(DateTime value) {
    final date = _day(value);
    return !date.isBefore(start) && !date.isAfter(end);
  }

  @override
  bool operator ==(Object other) =>
      other is StatisticsRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

class StatisticsPoint {
  const StatisticsPoint(this.date, this.value);

  final DateTime date;
  final int? value;

  @override
  bool operator ==(Object other) =>
      other is StatisticsPoint && other.date == date && other.value == value;

  @override
  int get hashCode => Object.hash(date, value);
}

class StatisticsModel {
  StatisticsModel({
    required this.profile,
    required Iterable<LedgerTransaction> transactions,
    required this.range,
  }) : transactions = transactions
           .where((entry) => entry.deletedAt == null)
           .toList() {
    _periodTransactions = this.transactions
        .where((entry) => range.contains(entry.date))
        .toList();
  }

  final Profile profile;
  final StatisticsRange range;
  final List<LedgerTransaction> transactions;
  late final List<LedgerTransaction> _periodTransactions;

  FinancialSummary get _all => FinancialSummary(profile, transactions);
  int? get balance => _all.balance;
  int? get performanceBalance => _all.performanceBalance;

  int get totalIncome => _sumWhere(
    _periodTransactions,
    (entry) => entry.type == TransactionType.income,
  );

  int get totalExpenses => _sumWhere(
    _periodTransactions,
    (entry) => entry.type == TransactionType.expense,
  );

  int get performanceResult => _periodTransactions
      .where((entry) => entry.countsTowardPerformance)
      .fold(0, (sum, entry) => sum + entry.signedAmount);

  Map<String, int> get incomeByCategory => _groupByString(
    _periodTransactions.where((entry) => entry.type == TransactionType.income),
    (entry) => entry.categoryId,
  );

  Map<String, int> get expensesByCategory => _groupByString(
    _periodTransactions.where((entry) => entry.type == TransactionType.expense),
    (entry) => entry.categoryId,
  );

  Map<String?, int> get incomeBySource {
    final result = <String?, int>{};
    for (final entry in _periodTransactions.where(
      (entry) => entry.type == TransactionType.income,
    )) {
      result.update(
        entry.sourceId,
        (value) => value + entry.amountMinor,
        ifAbsent: () => entry.amountMinor,
      );
    }
    return result;
  }

  Map<DateTime, int> get dailyResults {
    final result = {for (final day in range.days) day: 0};
    for (final entry in _periodTransactions.where(
      (entry) => entry.countsTowardPerformance,
    )) {
      final date = _day(entry.date);
      result[date] = result[date]! + entry.signedAmount;
    }
    return result;
  }

  Map<DateTime, int> get weeklyResults => _rollup(
    (date) => date.subtract(Duration(days: date.weekday - DateTime.monday)),
  );

  Map<DateTime, int> get monthlyResults =>
      _rollup((date) => DateTime(date.year, date.month));

  Map<DayState, int> get dayStateCounts {
    final result = {for (final state in DayState.values) state: 0};
    for (final state in dayStates.values) {
      result[state] = result[state]! + 1;
    }
    return result;
  }

  Map<DateTime, DayState> get dayStates {
    final periodSummary = FinancialSummary(profile, _periodTransactions);
    return {for (final day in range.days) day: periodSummary.stateOn(day)};
  }

  double get positiveDayRate {
    final counts = dayStateCounts;
    final active =
        counts[DayState.positive]! +
        counts[DayState.zeroAfterActivity]! +
        counts[DayState.negative]!;
    return active == 0 ? 0 : counts[DayState.positive]! / active;
  }

  int get longestPositiveStreak {
    var current = 0;
    var longest = 0;
    for (final state in dayStates.values) {
      switch (state) {
        case DayState.positive:
          current++;
          if (current > longest) longest = current;
        case DayState.negative:
          current = 0;
        case DayState.zeroAfterActivity:
        case DayState.noActivity:
          break;
      }
    }
    return longest;
  }

  List<StatisticsPoint> get performanceBalanceEvolution {
    final starting = profile.startingPerformanceBalance;
    if (starting == null) {
      return [for (final day in range.days) StatisticsPoint(day, null)];
    }
    var running = starting;
    for (final entry in transactions.where(
      (entry) =>
          entry.countsTowardPerformance &&
          _day(entry.date).isBefore(range.start),
    )) {
      running += entry.signedAmount;
    }
    final daily = dailyResults;
    return [
      for (final day in range.days)
        StatisticsPoint(day, running += daily[day]!),
    ];
  }

  int _sumWhere(
    Iterable<LedgerTransaction> entries,
    bool Function(LedgerTransaction) predicate,
  ) =>
      entries.where(predicate).fold(0, (sum, entry) => sum + entry.amountMinor);

  Map<String, int> _groupByString(
    Iterable<LedgerTransaction> entries,
    String Function(LedgerTransaction) keyFor,
  ) {
    final result = <String, int>{};
    for (final entry in entries) {
      result.update(
        keyFor(entry),
        (value) => value + entry.amountMinor,
        ifAbsent: () => entry.amountMinor,
      );
    }
    return result;
  }

  Map<DateTime, int> _rollup(DateTime Function(DateTime) keyFor) {
    final result = <DateTime, int>{};
    for (final entry in dailyResults.entries) {
      final key = keyFor(entry.key);
      result.update(
        key,
        (value) => value + entry.value,
        ifAbsent: () => entry.value,
      );
    }
    return result;
  }
}
