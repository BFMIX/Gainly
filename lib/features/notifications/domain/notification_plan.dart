import '../../../core/domain/finance.dart';
import '../../../core/domain/notification_preferences.dart';
import '../../goals/domain/goals_progress.dart';

enum NotificationKind {
  performanceBalanceRisk,
  negativeDays,
  monthlyTargetReached,
  achievementFirstEntry,
  achievementThreePositiveDays,
  achievementSevenDayTrackingStreak,
  streakEncouragement,
  positiveMilestone,
}

class NotificationPlanEngine {
  const NotificationPlanEngine();

  DateTime? dailyReminder({
    required DateTime asOf,
    required NotificationPreferences preferences,
    required Iterable<LedgerTransaction> transactions,
  }) {
    if (!preferences.dailyReminder) return null;
    final today = DateTime(asOf.year, asOf.month, asOf.day);
    final hour = preferences.reminderMinutes ~/ 60;
    final minute = preferences.reminderMinutes % 60;
    final todayReminder = DateTime(
      today.year,
      today.month,
      today.day,
      hour,
      minute,
    );
    final hasActivity = transactions.any(
      (entry) =>
          entry.deletedAt == null && dateKey(entry.date) == dateKey(today),
    );
    if (!hasActivity && asOf.isBefore(todayReminder)) return todayReminder;
    final tomorrow = today.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
  }

  NotificationKind? financialAlert({
    required DateTime asOf,
    required Profile profile,
    required Iterable<LedgerTransaction> previousTransactions,
    required Iterable<LedgerTransaction> currentTransactions,
    required NotificationPreferences preferences,
  }) {
    if (preferences.performanceBalanceWarning) {
      final previous = FinancialSummary(
        profile,
        previousTransactions,
      ).performanceBalance;
      final current = FinancialSummary(
        profile,
        currentTransactions,
      ).performanceBalance;
      if (previous != null && current != null && previous > current) {
        const nearZeroThresholdMinor = 1000;
        const strongDropMinimumMinor = 5000;
        final drop = previous - current;
        final crossedZero = previous > 0 && current <= 0;
        final approachedZero =
            previous > nearZeroThresholdMinor &&
            current > 0 &&
            current <= nearZeroThresholdMinor;
        final droppedStrongly =
            drop >= strongDropMinimumMinor && drop * 4 >= previous;
        if (crossedZero || approachedZero || droppedStrongly) {
          return NotificationKind.performanceBalanceRisk;
        }
      }
    }

    if (preferences.negativeDaysWarning) {
      final previousDays = _trailingNegativeDays(previousTransactions);
      final currentDays = _trailingNegativeDays(currentTransactions);
      if (previousDays < 3 && currentDays >= 3) {
        return NotificationKind.negativeDays;
      }
    }

    final progress = const GoalsProgressEngine();
    final previousProgress = progress.evaluateForProfile(
      asOf: asOf,
      profile: profile,
      transactions: previousTransactions,
    );
    final currentProgress = progress.evaluateForProfile(
      asOf: asOf,
      profile: profile,
      transactions: currentTransactions,
    );

    if (preferences.goalProgress &&
        previousProgress.monthlyTarget?.isReached != true &&
        currentProgress.monthlyTarget?.isReached == true) {
      return NotificationKind.monthlyTargetReached;
    }

    if (preferences.badgeAchievements) {
      final previous = previousProgress.achievements.toSet();
      for (final achievement in currentProgress.achievements) {
        if (!previous.contains(achievement)) {
          return switch (achievement) {
            AchievementKind.firstEntry =>
              NotificationKind.achievementFirstEntry,
            AchievementKind.threePositiveDays =>
              NotificationKind.achievementThreePositiveDays,
            AchievementKind.sevenDayTrackingStreak =>
              NotificationKind.achievementSevenDayTrackingStreak,
            AchievementKind.monthlyTargetReached =>
              NotificationKind.monthlyTargetReached,
          };
        }
      }
    }

    if (preferences.streakEncouragement) {
      final previousStreak = _largestStreak(previousProgress.streaks);
      final currentStreak = _largestStreak(currentProgress.streaks);
      if (currentStreak > previousStreak &&
          const {3, 7, 14, 30}.contains(currentStreak)) {
        return NotificationKind.streakEncouragement;
      }
    }

    if (preferences.positiveMilestones) {
      final previousBalance = FinancialSummary(
        profile,
        previousTransactions,
      ).performanceBalance;
      final currentBalance = FinancialSummary(
        profile,
        currentTransactions,
      ).performanceBalance;
      const milestone = 10000;
      if (previousBalance != null &&
          currentBalance != null &&
          currentBalance > previousBalance &&
          currentBalance >= milestone &&
          currentBalance ~/ milestone >
              (previousBalance < 0 ? 0 : previousBalance) ~/ milestone) {
        return NotificationKind.positiveMilestone;
      }
    }
    return null;
  }

  int _largestStreak(StreakSummary streaks) =>
      streaks.positiveStreak > streaks.trackingStreak
      ? streaks.positiveStreak
      : streaks.trackingStreak;

  int _trailingNegativeDays(Iterable<LedgerTransaction> transactions) {
    final results = <String, int>{};
    final dates = <String, DateTime>{};
    for (final entry in transactions.where(
      (value) => value.deletedAt == null && value.countsTowardPerformance,
    )) {
      final key = dateKey(entry.date);
      dates[key] = DateTime(entry.date.year, entry.date.month, entry.date.day);
      results[key] = (results[key] ?? 0) + entry.signedAmount;
    }
    final ordered = dates.keys.toList()
      ..sort((a, b) => dates[b]!.compareTo(dates[a]!));
    var count = 0;
    DateTime? previousDate;
    for (final key in ordered) {
      final currentDate = dates[key]!;
      if (previousDate != null &&
          previousDate.difference(currentDate).inDays != 1) {
        break;
      }
      final result = results[key]!;
      if (result < 0) {
        count++;
        previousDate = currentDate;
      } else {
        break;
      }
    }
    return count;
  }
}
