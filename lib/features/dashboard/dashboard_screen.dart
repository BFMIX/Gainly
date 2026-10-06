import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/ledger_controller.dart';
import '../../app/theme.dart';
import '../../core/domain/finance.dart';
import '../goals/domain/goals_progress.dart';
import '../../localization/formatters.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.controller,
    required this.onSettings,
    required this.onStatistics,
  });
  final LedgerController controller;
  final VoidCallback onSettings;
  final VoidCallback onStatistics;
  @override
  Widget build(BuildContext context) {
    final s = context.strings, p = controller.profile!;
    final summary = FinancialSummary(p, controller.transactions);
    final today = DateTime.now();
    final progress = const GoalsProgressEngine().evaluateForProfile(
      asOf: today,
      profile: p,
      transactions: controller.transactions,
    );
    final state = summary.stateOn(today);
    final stateColor = switch (state) {
      DayState.positive => GainlyTheme.positive,
      DayState.negative => GainlyTheme.negative,
      DayState.zeroAfterActivity => GainlyTheme.balanced,
      DayState.noActivity => GainlyTheme.inactive,
    };
    final stateLabel = switch (state) {
      DayState.positive => s.positive,
      DayState.negative => s.negative,
      DayState.zeroAfterActivity => s.zeroAfterActivity,
      DayState.noActivity => s.noActivity,
    };
    return RefreshIndicator(
      onRefresh: controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 110),
        children: [
          Text(
            p.firstName,
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(s.tagline),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF173F31),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.performanceBalance,
                  style: const TextStyle(
                    color: Color(0xFFD5EADD),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                if (summary.performanceBalance == null)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: onSettings,
                    child: Text(s.setPerformanceBalance),
                  )
                else
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      context.money(summary.performanceBalance!, p.currency),
                      key: const Key('performanceValue'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Color(0xFF47705A)),
                ),
                Text(
                  s.balance,
                  style: const TextStyle(color: Color(0xFFD5EADD)),
                ),
                const SizedBox(height: 6),
                if (summary.balance == null)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: onSettings,
                    child: Text(s.setBalance),
                  )
                else
                  Text(
                    context.money(summary.balance!, p.currency),
                    key: const Key('balanceValue'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(s.today, style: Theme.of(context).textTheme.titleLarge),
              Chip(
                label: Text(stateLabel),
                labelStyle: TextStyle(color: stateColor),
                backgroundColor: stateColor.withValues(alpha: 0.09),
                side: BorderSide.none,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _Value(
                    label: s.income,
                    value: context.money(summary.incomeOn(today), p.currency),
                    color: GainlyTheme.positive,
                  ),
                  const SizedBox(height: 14),
                  _Value(
                    label: s.expenses,
                    value: context.money(summary.expensesOn(today), p.currency),
                  ),
                  const Divider(height: 32),
                  _Value(
                    label: s.performanceResult,
                    value: context.money(summary.resultOn(today), p.currency),
                    color: stateColor,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ProgressCard(progress: progress, currency: p.currency),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onStatistics,
            icon: const Icon(Icons.query_stats),
            label: Text(s.viewStatistics),
          ),
          const SizedBox(height: 28),
          Text(
            s.recentTransactions,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (controller.transactions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.spa_outlined,
                      size: 40,
                      color: GainlyTheme.positive,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.emptyTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(s.emptyBody, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ...controller.transactions.take(5).map((t) {
            final matches = controller.categories.where(
              (c) => c.id == t.categoryId,
            );
            final sources = controller.sources.where((v) => v.id == t.sourceId);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  t.type == TransactionType.income
                      ? Icons.south_west
                      : Icons.north_east,
                  color: t.type == TransactionType.income
                      ? GainlyTheme.positive
                      : GainlyTheme.negative,
                ),
                title: Text(
                  sources.isEmpty
                      ? (matches.isEmpty
                            ? s.other
                            : context.categoryName(matches.first))
                      : sources.first.name,
                ),
                subtitle: Text(
                  '${DateFormat.MMMd(Localizations.localeOf(context).languageCode).format(t.date)} · ${t.countsTowardPerformance ? s.included : s.excluded}',
                ),
                trailing: Text(
                  context.money(t.signedAmount, p.currency),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress, required this.currency});

  final GoalsProgressSnapshot progress;
  final String currency;

  String insightLabel(BuildContext context, SmartInsightKind kind) =>
      switch (kind) {
        SmartInsightKind.performanceBalanceRisk =>
          context.strings.performanceBalanceRiskInsight,
        SmartInsightKind.consecutiveNegativeDays =>
          context.strings.consecutiveNegativeDaysInsight,
        SmartInsightKind.spendingAboveRecentAverage =>
          context.strings.spendingAboveAverageInsight,
        SmartInsightKind.behindMonthlyTarget =>
          context.strings.behindMonthlyTargetInsight,
        SmartInsightKind.aheadMonthlyTarget =>
          context.strings.aheadMonthlyTargetInsight,
        SmartInsightKind.requiredDailyPace =>
          context.strings.requiredDailyPaceInsight,
      };

  String achievementLabel(BuildContext context, AchievementKind kind) =>
      switch (kind) {
        AchievementKind.firstEntry => context.strings.achievementFirstEntry,
        AchievementKind.threePositiveDays =>
          context.strings.achievementThreePositiveDays,
        AchievementKind.sevenDayTrackingStreak =>
          context.strings.achievementSevenDayTrackingStreak,
        AchievementKind.monthlyTargetReached =>
          context.strings.achievementMonthlyTargetReached,
      };

  @override
  Widget build(BuildContext context) {
    final target = progress.monthlyTarget;
    final minimum = progress.dailyMinimum;
    final rate = progress.streaks.positiveDayRateBasisPoints / 100;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.strings.goalProgress,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (target != null) ...[
              const SizedBox(height: 18),
              Text(context.strings.monthlyTarget),
              const SizedBox(height: 6),
              Text(
                '${context.money(target.earnedMinor, currency)} / ${context.money(target.targetMinor, currency)}',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (target.completionBasisPoints / 10000).clamp(0, 1),
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 10),
              _CompactValue(
                label: context.strings.requiredDailyPace,
                value: context.money(target.requiredDailyPaceMinor, currency),
              ),
              _CompactValue(
                label: context.strings.daysRemaining,
                value: '${target.daysRemaining}',
              ),
            ],
            if (minimum != null) ...[
              const SizedBox(height: 18),
              Text(context.strings.dailyMinimum),
              const SizedBox(height: 6),
              Text(
                context.money(minimum.effectiveMinor, currency),
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (minimum.completionBasisPoints / 10000).clamp(0, 1),
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
            const SizedBox(height: 18),
            _CompactValue(
              label: context.strings.trackingStreak,
              value: '${progress.streaks.trackingStreak}',
            ),
            _CompactValue(
              label: context.strings.positiveStreak,
              value: '${progress.streaks.positiveStreak}',
            ),
            _CompactValue(
              label: context.strings.positiveDayRate,
              value:
                  '${rate.toStringAsFixed(rate == rate.roundToDouble() ? 0 : 1)}%',
            ),
            if (progress.achievements.isNotEmpty) ...[
              const Divider(height: 28),
              Text(
                context.strings.achievements,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: progress.achievements
                    .map(
                      (achievement) => Chip(
                        avatar: const Icon(Icons.emoji_events_outlined),
                        label: Text(achievementLabel(context, achievement)),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            if (progress.insights.isNotEmpty) ...[
              const Divider(height: 28),
              Text(
                context.strings.smartInsights,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...progress.insights.map(
                (insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(insightLabel(context, insight.kind)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompactValue extends StatelessWidget {
  const _CompactValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value, this.color});
  final String label, value;
  final Color? color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    ],
  );
}
