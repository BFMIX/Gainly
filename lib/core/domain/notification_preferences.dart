class NotificationPreferences {
  const NotificationPreferences({
    this.dailyReminder = true,
    this.reminderMinutes = 20 * 60,
    this.negativeDaysWarning = true,
    this.performanceBalanceWarning = true,
    this.streakEncouragement = false,
    this.badgeAchievements = false,
    this.goalProgress = false,
    this.positiveMilestones = false,
  }) : assert(reminderMinutes >= 0 && reminderMinutes < 24 * 60);

  final bool dailyReminder;
  final int reminderMinutes;
  final bool negativeDaysWarning;
  final bool performanceBalanceWarning;
  final bool streakEncouragement;
  final bool badgeAchievements;
  final bool goalProgress;
  final bool positiveMilestones;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        dailyReminder: json['daily_reminder'] as bool? ?? true,
        reminderMinutes: json['reminder_minutes'] as int? ?? 20 * 60,
        negativeDaysWarning: json['negative_days_warning'] as bool? ?? true,
        performanceBalanceWarning:
            json['performance_balance_warning'] as bool? ?? true,
        streakEncouragement: json['streak_encouragement'] as bool? ?? false,
        badgeAchievements: json['badge_achievements'] as bool? ?? false,
        goalProgress: json['goal_progress'] as bool? ?? false,
        positiveMilestones: json['positive_milestones'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
    'daily_reminder': dailyReminder,
    'reminder_minutes': reminderMinutes,
    'negative_days_warning': negativeDaysWarning,
    'performance_balance_warning': performanceBalanceWarning,
    'streak_encouragement': streakEncouragement,
    'badge_achievements': badgeAchievements,
    'goal_progress': goalProgress,
    'positive_milestones': positiveMilestones,
  };

  NotificationPreferences copyWith({
    bool? dailyReminder,
    int? reminderMinutes,
    bool? negativeDaysWarning,
    bool? performanceBalanceWarning,
    bool? streakEncouragement,
    bool? badgeAchievements,
    bool? goalProgress,
    bool? positiveMilestones,
  }) => NotificationPreferences(
    dailyReminder: dailyReminder ?? this.dailyReminder,
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    negativeDaysWarning: negativeDaysWarning ?? this.negativeDaysWarning,
    performanceBalanceWarning:
        performanceBalanceWarning ?? this.performanceBalanceWarning,
    streakEncouragement: streakEncouragement ?? this.streakEncouragement,
    badgeAchievements: badgeAchievements ?? this.badgeAchievements,
    goalProgress: goalProgress ?? this.goalProgress,
    positiveMilestones: positiveMilestones ?? this.positiveMilestones,
  );
}
