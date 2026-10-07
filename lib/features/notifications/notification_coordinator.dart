import 'package:flutter/widgets.dart';

import '../../core/domain/finance.dart';
import '../../core/domain/notification_preferences.dart';
import '../../localization/app_localizations.dart';
import 'domain/notification_plan.dart';
import 'notification_delivery.dart';

class NotificationCoordinator {
  NotificationCoordinator(
    this.delivery, {
    this._engine = const NotificationPlanEngine(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final NotificationDelivery delivery;
  final NotificationPlanEngine _engine;
  final DateTime Function() _clock;

  Future<void> endSession() => delivery.cancelDaily();

  Future<void> syncDaily({
    required Profile profile,
    required NotificationPreferences preferences,
    required Iterable<LedgerTransaction> transactions,
  }) async {
    final date = _engine.dailyReminder(
      asOf: _clock(),
      preferences: preferences,
      transactions: transactions,
    );
    if (date == null) {
      await delivery.cancelDaily();
      return;
    }
    final strings = lookupAppLocalizations(Locale(profile.language));
    await delivery.scheduleDaily(
      date: date,
      title: strings.dailyReminderNotificationTitle,
      body: strings.dailyReminderNotificationBody,
    );
  }

  Future<void> applyPreferences({
    required Profile profile,
    required NotificationPreferences preferences,
    required Iterable<LedgerTransaction> transactions,
  }) async {
    if (_hasEnabledNotification(preferences)) {
      await delivery.requestPermission();
    }
    await syncDaily(
      profile: profile,
      preferences: preferences,
      transactions: transactions,
    );
  }

  Future<void> afterFinancialChange({
    required Profile profile,
    required NotificationPreferences preferences,
    required Iterable<LedgerTransaction> previousTransactions,
    required Iterable<LedgerTransaction> currentTransactions,
  }) async {
    final strings = lookupAppLocalizations(Locale(profile.language));
    final alert = _engine.financialAlert(
      asOf: _clock(),
      profile: profile,
      previousTransactions: previousTransactions,
      currentTransactions: currentTransactions,
      preferences: preferences,
    );
    if (alert != null) {
      final (title, body) = switch (alert) {
        NotificationKind.performanceBalanceRisk => (
          strings.performanceBalanceRiskNotificationTitle,
          strings.performanceBalanceRiskNotificationBody,
        ),
        NotificationKind.negativeDays => (
          strings.negativeDaysNotificationTitle,
          strings.negativeDaysNotificationBody,
        ),
        NotificationKind.monthlyTargetReached => (
          strings.monthlyGoalNotificationTitle,
          strings.monthlyGoalNotificationBody,
        ),
        NotificationKind.achievementFirstEntry => (
          strings.achievementUnlockedNotificationTitle,
          strings.achievementFirstEntry,
        ),
        NotificationKind.achievementThreePositiveDays => (
          strings.achievementUnlockedNotificationTitle,
          strings.achievementThreePositiveDays,
        ),
        NotificationKind.achievementSevenDayTrackingStreak => (
          strings.achievementUnlockedNotificationTitle,
          strings.achievementSevenDayTrackingStreak,
        ),
        NotificationKind.streakEncouragement => (
          strings.streakNotificationTitle,
          strings.streakNotificationBody,
        ),
        NotificationKind.positiveMilestone => (
          strings.positiveMilestoneNotificationTitle,
          strings.positiveMilestoneNotificationBody,
        ),
      };
      await delivery.show(title: title, body: body);
    }
    await syncDaily(
      profile: profile,
      preferences: preferences,
      transactions: currentTransactions,
    );
  }

  bool _hasEnabledNotification(NotificationPreferences preferences) =>
      preferences.dailyReminder ||
      preferences.negativeDaysWarning ||
      preferences.performanceBalanceWarning ||
      preferences.streakEncouragement ||
      preferences.badgeAchievements ||
      preferences.goalProgress ||
      preferences.positiveMilestones;
}
