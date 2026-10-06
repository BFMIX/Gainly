import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/ledger_controller.dart';
import '../../app/theme.dart';
import '../../core/domain/finance.dart';
import '../../localization/formatters.dart';
import 'statistics_model.dart';

class StatisticsCopy {
  const StatisticsCopy({
    required this.title,
    required this.netPerformance,
    required this.performanceEvolution,
    required this.positiveDayRate,
    required this.longestPositiveStreak,
    required this.dayStates,
    required this.dailyResults,
    required this.weeklyResults,
    required this.monthlyResults,
    required this.incomeByCategory,
    required this.incomeBySource,
    required this.expensesByCategory,
    required this.noData,
    required this.chooseDates,
  });

  final String title;
  final String netPerformance;
  final String performanceEvolution;
  final String positiveDayRate;
  final String longestPositiveStreak;
  final String dayStates;
  final String dailyResults;
  final String weeklyResults;
  final String monthlyResults;
  final String incomeByCategory;
  final String incomeBySource;
  final String expensesByCategory;
  final String noData;
  final String chooseDates;
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({
    super.key,
    required this.controller,
    required this.copy,
    this.showTitle = true,
  });

  final LedgerController controller;
  final StatisticsCopy copy;
  final bool showTitle;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatisticsPeriod period = StatisticsPeriod.thisMonth;
  StatisticsRange? customRange;

  StatisticsRange get range => StatisticsRange.forPeriod(
    period,
    anchor: DateTime.now(),
    custom: customRange,
  );

  String periodLabel(BuildContext context, StatisticsPeriod value) =>
      switch (value) {
        StatisticsPeriod.sevenDays => context.strings.sevenDays,
        StatisticsPeriod.thirtyDays => context.strings.thirtyDays,
        StatisticsPeriod.thisMonth => context.strings.thisMonth,
        StatisticsPeriod.thisYear => context.strings.thisYear,
        StatisticsPeriod.custom => context.strings.customPeriod,
      };

  Future<void> selectPeriod(StatisticsPeriod value) async {
    if (value != StatisticsPeriod.custom) {
      setState(() => period = value);
      return;
    }
    final today = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: today,
      initialDateRange: customRange == null
          ? DateTimeRange(
              start: today.subtract(const Duration(days: 6)),
              end: today,
            )
          : DateTimeRange(start: customRange!.start, end: customRange!.end),
      helpText: widget.copy.chooseDates,
    );
    if (selected != null && mounted) {
      setState(() {
        customRange = StatisticsRange(selected.start, selected.end);
        period = StatisticsPeriod.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.controller.profile!;
    final model = StatisticsModel(
      profile: profile,
      transactions: widget.controller.transactions,
      range: range,
    );
    final locale = Localizations.localeOf(context).languageCode;
    final dateFormat = DateFormat.MMMd(locale);
    final monthFormat = DateFormat.yMMM(locale);

    return RefreshIndicator(
      onRefresh: widget.controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          if (widget.showTitle) ...[
            Text(
              widget.copy.title,
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
          ],
          DropdownButtonFormField<StatisticsPeriod>(
            key: const Key('statisticsPeriod'),
            initialValue: period,
            decoration: InputDecoration(
              labelText: context.strings.period,
              prefixIcon: const Icon(Icons.date_range_outlined),
            ),
            items: StatisticsPeriod.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(periodLabel(context, value)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) selectPeriod(value);
            },
          ),
          const SizedBox(height: 8),
          Text(
            '${dateFormat.format(range.start)} – ${DateFormat.yMMMd(locale).format(range.end)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          _BalanceCard(model: model, currency: profile.currency),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.45,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _MetricCard(
                label: context.strings.income,
                value: context.money(model.totalIncome, profile.currency),
                color: GainlyTheme.positive,
              ),
              _MetricCard(
                label: context.strings.expenses,
                value: context.money(model.totalExpenses, profile.currency),
                color: GainlyTheme.negative,
              ),
              _MetricCard(
                label: widget.copy.netPerformance,
                value: context.signedMoney(
                  model.performanceResult,
                  profile.currency,
                ),
                color: model.performanceResult < 0
                    ? GainlyTheme.negative
                    : GainlyTheme.positive,
              ),
              _MetricCard(
                label: widget.copy.positiveDayRate,
                value: NumberFormat.percentPattern(locale)
                    .format(model.positiveDayRate),
                color: GainlyTheme.positive,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionCard(
            title: widget.copy.performanceEvolution,
            child: _EvolutionChart(
              points: model.performanceBalanceEvolution,
              noData: widget.copy.noData,
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: widget.copy.dayStates,
            child: Column(
              children: [
                _StateRow(
                  label: context.strings.positive,
                  value: model.dayStateCounts[DayState.positive]!,
                  color: GainlyTheme.positive,
                ),
                _StateRow(
                  label: context.strings.zeroAfterActivity,
                  value: model.dayStateCounts[DayState.zeroAfterActivity]!,
                  color: GainlyTheme.balanced,
                ),
                _StateRow(
                  label: context.strings.negative,
                  value: model.dayStateCounts[DayState.negative]!,
                  color: GainlyTheme.negative,
                ),
                _StateRow(
                  label: context.strings.noActivity,
                  value: model.dayStateCounts[DayState.noActivity]!,
                  color: GainlyTheme.inactive,
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(child: Text(widget.copy.longestPositiveStreak)),
                    Text(
                      '${model.longestPositiveStreak}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DistributionCard(
            title: widget.copy.incomeByCategory,
            values: model.incomeByCategory,
            labelFor: (id) => _categoryName(context, id),
            currency: profile.currency,
            color: GainlyTheme.positive,
            noData: widget.copy.noData,
          ),
          const SizedBox(height: 16),
          _DistributionCard(
            title: widget.copy.incomeBySource,
            values: model.incomeBySource,
            labelFor: (id) => _sourceName(id),
            currency: profile.currency,
            color: Theme.of(context).colorScheme.primary,
            noData: widget.copy.noData,
          ),
          const SizedBox(height: 16),
          _DistributionCard(
            title: widget.copy.expensesByCategory,
            values: model.expensesByCategory,
            labelFor: (id) => _categoryName(context, id),
            currency: profile.currency,
            color: GainlyTheme.negative,
            noData: widget.copy.noData,
          ),
          const SizedBox(height: 16),
          _ResultCard(
            title: widget.copy.dailyResults,
            values: model.dailyResults,
            labelFor: dateFormat.format,
            currency: profile.currency,
          ),
          const SizedBox(height: 16),
          _ResultCard(
            title: widget.copy.weeklyResults,
            values: model.weeklyResults,
            labelFor: dateFormat.format,
            currency: profile.currency,
          ),
          const SizedBox(height: 16),
          _ResultCard(
            title: widget.copy.monthlyResults,
            values: model.monthlyResults,
            labelFor: monthFormat.format,
            currency: profile.currency,
          ),
        ],
      ),
    );
  }

  String _categoryName(BuildContext context, String? id) {
    final matches = widget.controller.categories.where(
      (value) => value.id == id,
    );
    return matches.isEmpty
        ? context.strings.other
        : context.categoryName(matches.first);
  }

  String _sourceName(String? id) {
    if (id == null) return context.strings.unspecified;
    final matches = widget.controller.sources.where((value) => value.id == id);
    return matches.isEmpty ? context.strings.unspecified : matches.first.name;
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.model, required this.currency});

  final StatisticsModel model;
  final String currency;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF173F31),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Expanded(
            child: _DarkValue(
              label: context.strings.performanceBalance,
              value: model.performanceBalance == null
                  ? '—'
                  : context.money(model.performanceBalance!, currency),
            ),
          ),
          const SizedBox(
            height: 48,
            child: VerticalDivider(color: Color(0xFF47705A)),
          ),
          Expanded(
            child: _DarkValue(
              label: context.strings.balance,
              value: model.balance == null
                  ? '—'
                  : context.money(model.balance!, currency),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DarkValue extends StatelessWidget {
  const _DarkValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: Color(0xFFD5EADD), fontSize: 12),
      ),
      const SizedBox(height: 8),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

class _StateRow extends StatelessWidget {
  const _StateRow({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _DistributionCard<K> extends StatelessWidget {
  const _DistributionCard({
    required this.title,
    required this.values,
    required this.labelFor,
    required this.currency,
    required this.color,
    required this.noData,
  });

  final String title;
  final Map<K, int> values;
  final String Function(K) labelFor;
  final String currency;
  final Color color;
  final String noData;

  @override
  Widget build(BuildContext context) {
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maximum = entries.fold<int>(
      0,
      (value, entry) => math.max(value, entry.value),
    );
    return _SectionCard(
      title: title,
      child: entries.isEmpty
          ? Text(noData)
          : Column(
              children: [
                for (final entry in entries) ...[
                  Row(
                    children: [
                      Expanded(child: Text(labelFor(entry.key))),
                      Text(context.money(entry.value, currency)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: maximum == 0 ? 0 : entry.value / maximum,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.values,
    required this.labelFor,
    required this.currency,
  });
  final String title;
  final Map<DateTime, int> values;
  final String Function(DateTime) labelFor;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final entries = values.entries.toList().reversed.take(12);
    return _SectionCard(
      title: title,
      child: Column(
        children: [
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(child: Text(labelFor(entry.key))),
                  Text(
                    context.signedMoney(entry.value, currency),
                    style: TextStyle(
                      color: entry.value < 0
                          ? GainlyTheme.negative
                          : entry.value > 0
                          ? GainlyTheme.positive
                          : GainlyTheme.inactive,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EvolutionChart extends StatelessWidget {
  const _EvolutionChart({required this.points, required this.noData});
  final List<StatisticsPoint> points;
  final String noData;

  @override
  Widget build(BuildContext context) {
    if (points.every((point) => point.value == null)) return Text(noData);
    return Semantics(
      label: points
          .where((point) => point.value != null)
          .map((point) => '${dateKey(point.date)}: ${point.value}')
          .join(', '),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: CustomPaint(
          painter: _EvolutionPainter(
            points: points,
            color: Theme.of(context).colorScheme.primary,
            gridColor: Theme.of(context).dividerColor,
          ),
        ),
      ),
    );
  }
}

class _EvolutionPainter extends CustomPainter {
  const _EvolutionPainter({
    required this.points,
    required this.color,
    required this.gridColor,
  });
  final List<StatisticsPoint> points;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final values = points.where((point) => point.value != null).toList();
    if (values.isEmpty) return;
    final minimum = values.map((point) => point.value!).reduce(math.min);
    final maximum = values.map((point) => point.value!).reduce(math.max);
    final spread = math.max(1, maximum - minimum);
    final grid = Paint()
      ..color = gridColor.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var row = 0; row <= 3; row++) {
      final y = size.height * row / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * index / (values.length - 1);
      final y =
          size.height - (values[index].value! - minimum) / spread * size.height;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _EvolutionPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.color != color ||
      oldDelegate.gridColor != gridColor;
}
