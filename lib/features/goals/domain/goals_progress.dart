import '../../../core/domain/finance.dart';

enum SmartInsightKind {
  performanceBalanceRisk,
  consecutiveNegativeDays,
  spendingAboveRecentAverage,
  behindMonthlyTarget,
  aheadMonthlyTarget,
  requiredDailyPace,
}

class MonthlyTargetProgress {
  const MonthlyTargetProgress({
    required this.targetMinor,
    required this.earnedMinor,
    required this.remainingMinor,
    required this.daysRemaining,
    required this.requiredDailyPaceMinor,
    required this.expectedEarnedMinor,
    required this.completionBasisPoints,
  });

  final int targetMinor;
  final int earnedMinor;
  final int remainingMinor;
  final int daysRemaining;
  final int requiredDailyPaceMinor;
  final int expectedEarnedMinor;
  final int completionBasisPoints;

  bool get isReached => earnedMinor >= targetMinor;
  int get paceDifferenceMinor => earnedMinor - expectedEarnedMinor;
}

class DailyMinimumProgress {
  const DailyMinimumProgress({
    required this.configuredMinor,
    required this.recommendedMinor,
    required this.effectiveMinor,
    required this.earnedTodayMinor,
    required this.remainingTodayMinor,
    required this.completionBasisPoints,
  });

  final int? configuredMinor;
  final int? recommendedMinor;
  final int effectiveMinor;
  final int earnedTodayMinor;
  final int remainingTodayMinor;
  final int completionBasisPoints;

  bool get isUsingRecommendation => configuredMinor == null;
  bool get isReached => earnedTodayMinor >= effectiveMinor;
}

class StreakSummary {
  const StreakSummary({
    required this.positiveStreak,
    required this.trackingStreak,
    required this.positiveDays,
    required this.performanceActiveDays,
    required this.positiveDayRateBasisPoints,
  });

  final int positiveStreak;
  final int trackingStreak;
  final int positiveDays;
  final int performanceActiveDays;
  final int positiveDayRateBasisPoints;
}

class SmartInsight {
  const SmartInsight({
    required this.kind,
    required this.priority,
    this.amountMinor,
    this.comparisonMinor,
    this.dayCount,
  });

  final SmartInsightKind kind;
  final int priority;
  final int? amountMinor;
  final int? comparisonMinor;
  final int? dayCount;
}

class GoalsProgressSnapshot {
  const GoalsProgressSnapshot({
    required this.asOf,
    required this.transactions,
    required this.monthlyTarget,
    required this.dailyMinimum,
    required this.streaks,
    required this.insights,
  });

  final DateTime asOf;
  final List<LedgerTransaction> transactions;
  final MonthlyTargetProgress? monthlyTarget;
  final DailyMinimumProgress? dailyMinimum;
  final StreakSummary streaks;
  final List<SmartInsight> insights;
}

/// Pure, deterministic financial progress calculations.
///
/// Amounts are integer minor units. The current calendar day is included in
/// remaining-day calculations because users can still earn during that day.
class GoalsProgressEngine {
  const GoalsProgressEngine();

  GoalsProgressSnapshot evaluateForProfile({
    required DateTime asOf,
    required Profile profile,
    required Iterable<LedgerTransaction> transactions,
    DateTime? positiveRatePeriodStart,
  }) => evaluate(
    asOf: asOf,
    transactions: transactions,
    monthlyTargetMinor: profile.monthlyTarget,
    dailyMinimumMinor: profile.dailyMinimum,
    startingPerformanceBalanceMinor: profile.startingPerformanceBalance,
    positiveRatePeriodStart: positiveRatePeriodStart,
  );

  GoalsProgressSnapshot evaluate({
    required DateTime asOf,
    required Iterable<LedgerTransaction> transactions,
    int? monthlyTargetMinor,
    int? dailyMinimumMinor,
    int? startingPerformanceBalanceMinor,
    DateTime? positiveRatePeriodStart,
  }) {
    _validateOptionalAmount(monthlyTargetMinor, 'monthlyTargetMinor');
    _validateOptionalAmount(dailyMinimumMinor, 'dailyMinimumMinor');

    final today = _day(asOf);
    final activeTransactions = transactions
        .where((entry) => entry.deletedAt == null)
        .where((entry) => !_day(entry.date).isAfter(today))
        .toList(growable: false);
    final monthStart = DateTime(today.year, today.month);
    final monthEnd = DateTime(today.year, today.month + 1, 0);
    final monthTransactions = activeTransactions
        .where((entry) => !_day(entry.date).isBefore(monthStart))
        .toList(growable: false);

    final target = monthlyTargetMinor == null
        ? null
        : _monthlyTarget(
            targetMinor: monthlyTargetMinor,
            transactions: monthTransactions,
            today: today,
            monthEnd: monthEnd,
          );
    final dailyMinimum = _dailyMinimum(
      configuredMinor: dailyMinimumMinor,
      monthlyTargetMinor: monthlyTargetMinor,
      transactions: activeTransactions,
      today: today,
    );
    final streaks = _streaks(
      transactions: activeTransactions,
      today: today,
      positiveRatePeriodStart: _day(positiveRatePeriodStart ?? monthStart),
    );
    final insights = _insights(
      transactions: activeTransactions,
      today: today,
      monthlyTarget: target,
      startingPerformanceBalanceMinor: startingPerformanceBalanceMinor,
    );

    return GoalsProgressSnapshot(
      asOf: today,
      transactions: List.unmodifiable(activeTransactions),
      monthlyTarget: target,
      dailyMinimum: dailyMinimum,
      streaks: streaks,
      insights: List.unmodifiable(insights.take(2)),
    );
  }

  MonthlyTargetProgress _monthlyTarget({
    required int targetMinor,
    required List<LedgerTransaction> transactions,
    required DateTime today,
    required DateTime monthEnd,
  }) {
    final earned = transactions
        .where(_isGrossPerformanceIncome)
        .fold<int>(0, (sum, entry) => sum + entry.amountMinor);
    final remaining = _nonNegative(targetMinor - earned);
    final daysRemaining = monthEnd.difference(today).inDays + 1;
    final daysInMonth = monthEnd.day;
    final elapsedDays = today.day;
    return MonthlyTargetProgress(
      targetMinor: targetMinor,
      earnedMinor: earned,
      remainingMinor: remaining,
      daysRemaining: daysRemaining,
      requiredDailyPaceMinor: remaining == 0
          ? 0
          : _ceilDivide(remaining, daysRemaining),
      expectedEarnedMinor: _ceilDivide(targetMinor * elapsedDays, daysInMonth),
      completionBasisPoints: _basisPoints(earned, targetMinor),
    );
  }

  DailyMinimumProgress? _dailyMinimum({
    required int? configuredMinor,
    required int? monthlyTargetMinor,
    required List<LedgerTransaction> transactions,
    required DateTime today,
  }) {
    final recommended = monthlyTargetMinor == null
        ? null
        : _ceilDivide(monthlyTargetMinor, 30);
    final effective = configuredMinor ?? recommended;
    if (effective == null) return null;

    final earned = transactions
        .where((entry) => _day(entry.date) == today)
        .where(_isGrossPerformanceIncome)
        .fold<int>(0, (sum, entry) => sum + entry.amountMinor);
    return DailyMinimumProgress(
      configuredMinor: configuredMinor,
      recommendedMinor: recommended,
      effectiveMinor: effective,
      earnedTodayMinor: earned,
      remainingTodayMinor: _nonNegative(effective - earned),
      completionBasisPoints: _basisPoints(earned, effective),
    );
  }

  StreakSummary _streaks({
    required List<LedgerTransaction> transactions,
    required DateTime today,
    required DateTime positiveRatePeriodStart,
  }) {
    final states = _performanceStates(transactions);
    var positiveStreak = 0;
    for (final date in states.keys.toList()..sort()) {
      switch (states[date]!) {
        case DayState.positive:
          positiveStreak++;
        case DayState.negative:
          positiveStreak = 0;
        case DayState.zeroAfterActivity:
        case DayState.noActivity:
          break;
      }
    }

    final rateStates = states.entries
        .where((entry) => !entry.key.isBefore(positiveRatePeriodStart))
        .map((entry) => entry.value)
        .where((state) => state != DayState.noActivity)
        .toList(growable: false);
    final positiveDays = rateStates
        .where((state) => state == DayState.positive)
        .length;

    final trackedDates = transactions.map((entry) => _day(entry.date)).toSet();
    var cursor = trackedDates.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    var trackingStreak = 0;
    while (trackedDates.contains(cursor)) {
      trackingStreak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return StreakSummary(
      positiveStreak: positiveStreak,
      trackingStreak: trackingStreak,
      positiveDays: positiveDays,
      performanceActiveDays: rateStates.length,
      positiveDayRateBasisPoints: rateStates.isEmpty
          ? 0
          : _basisPoints(positiveDays, rateStates.length),
    );
  }

  List<SmartInsight> _insights({
    required List<LedgerTransaction> transactions,
    required DateTime today,
    required MonthlyTargetProgress? monthlyTarget,
    required int? startingPerformanceBalanceMinor,
  }) {
    final insights = <SmartInsight>[];
    if (startingPerformanceBalanceMinor != null) {
      final currentBalance =
          startingPerformanceBalanceMinor +
          transactions
              .where((entry) => entry.countsTowardPerformance)
              .fold<int>(0, (sum, entry) => sum + entry.signedAmount);
      if (currentBalance <= 0) {
        insights.add(
          SmartInsight(
            kind: SmartInsightKind.performanceBalanceRisk,
            priority: 100,
            amountMinor: currentBalance,
          ),
        );
      }
    }

    final negativeDays = _trailingNegativeActiveDays(transactions);
    if (negativeDays >= 3) {
      insights.add(
        SmartInsight(
          kind: SmartInsightKind.consecutiveNegativeDays,
          priority: 90,
          dayCount: negativeDays,
        ),
      );
    }

    final spendingInsight = _spendingInsight(transactions, today);
    if (spendingInsight != null) insights.add(spendingInsight);

    if (monthlyTarget != null && !monthlyTarget.isReached) {
      final difference = monthlyTarget.paceDifferenceMinor;
      if (difference < 0) {
        insights.add(
          SmartInsight(
            kind: SmartInsightKind.behindMonthlyTarget,
            priority: 70,
            amountMinor: -difference,
            comparisonMinor: monthlyTarget.expectedEarnedMinor,
          ),
        );
      } else if (difference > 0) {
        insights.add(
          SmartInsight(
            kind: SmartInsightKind.aheadMonthlyTarget,
            priority: 60,
            amountMinor: difference,
            comparisonMinor: monthlyTarget.expectedEarnedMinor,
          ),
        );
      }
      if (monthlyTarget.requiredDailyPaceMinor > 0) {
        insights.add(
          SmartInsight(
            kind: SmartInsightKind.requiredDailyPace,
            priority: 50,
            amountMinor: monthlyTarget.requiredDailyPaceMinor,
            dayCount: monthlyTarget.daysRemaining,
          ),
        );
      }
    }

    insights.sort((a, b) {
      final priority = b.priority.compareTo(a.priority);
      return priority != 0 ? priority : a.kind.index.compareTo(b.kind.index);
    });
    return insights;
  }

  SmartInsight? _spendingInsight(
    List<LedgerTransaction> transactions,
    DateTime today,
  ) {
    final todaySpending = transactions
        .where((entry) => entry.type == TransactionType.expense)
        .where((entry) => _day(entry.date) == today)
        .fold<int>(0, (sum, entry) => sum + entry.amountMinor);
    if (todaySpending == 0) return null;

    final start = today.subtract(const Duration(days: 7));
    final previousSpending = transactions
        .where((entry) => entry.type == TransactionType.expense)
        .where((entry) {
          final date = _day(entry.date);
          return !date.isBefore(start) && date.isBefore(today);
        })
        .fold<int>(0, (sum, entry) => sum + entry.amountMinor);
    if (previousSpending == 0) return null;
    final dailyAverage = _ceilDivide(previousSpending, 7);
    if (todaySpending < _ceilDivide(dailyAverage * 3, 2)) return null;
    return SmartInsight(
      kind: SmartInsightKind.spendingAboveRecentAverage,
      priority: 80,
      amountMinor: todaySpending,
      comparisonMinor: dailyAverage,
    );
  }

  int _trailingNegativeActiveDays(List<LedgerTransaction> transactions) {
    final states = _performanceStates(transactions).entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    var count = 0;
    for (final state in states.map((entry) => entry.value)) {
      if (state == DayState.noActivity) continue;
      if (state != DayState.negative) break;
      count++;
    }
    return count;
  }

  Map<DateTime, DayState> _performanceStates(
    List<LedgerTransaction> transactions,
  ) {
    final grouped = <DateTime, List<LedgerTransaction>>{};
    for (final entry in transactions) {
      (grouped[_day(entry.date)] ??= []).add(entry);
    }
    return {
      for (final entry in grouped.entries)
        entry.key: _stateForTransactions(entry.value),
    };
  }

  DayState _stateForTransactions(List<LedgerTransaction> transactions) {
    final performance = transactions
        .where((entry) => entry.countsTowardPerformance)
        .toList(growable: false);
    if (performance.isEmpty) return DayState.noActivity;
    final result = performance.fold<int>(
      0,
      (sum, entry) => sum + entry.signedAmount,
    );
    if (result > 0) return DayState.positive;
    if (result < 0) return DayState.negative;
    return DayState.zeroAfterActivity;
  }

  bool _isGrossPerformanceIncome(LedgerTransaction entry) =>
      entry.type == TransactionType.income && entry.countsTowardPerformance;

  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static int _nonNegative(int value) => value < 0 ? 0 : value;

  static int _ceilDivide(int numerator, int denominator) =>
      (numerator + denominator - 1) ~/ denominator;

  static int _basisPoints(int numerator, int denominator) =>
      ((BigInt.from(numerator) * BigInt.from(10000)) ~/
              BigInt.from(denominator))
          .toInt();

  static void _validateOptionalAmount(int? value, String name) {
    if (value != null && (value <= 0 || value > maxMinorAmount)) {
      throw ArgumentError.value(
        value,
        name,
        'must be a supported positive amount',
      );
    }
  }
}
