import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/ledger_controller.dart';
import '../../app/theme.dart';
import '../../core/domain/finance.dart';
import '../../localization/formatters.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.controller});

  final LedgerController controller;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

  void changeMonth(int offset) {
    setState(() => month = DateTime(month.year, month.month + offset));
  }

  Color stateColor(DayState state) => switch (state) {
    DayState.positive => GainlyTheme.positive,
    DayState.negative => GainlyTheme.negative,
    DayState.zeroAfterActivity => GainlyTheme.balanced,
    DayState.noActivity => GainlyTheme.inactive,
  };

  void showDay(DateTime day, FinancialSummary summary) {
    final transactions = summary.onDay(
      day,
    )..sort((a, b) => (b.createdAt ?? b.date).compareTo(a.createdAt ?? a.date));
    final profile = widget.controller.profile!;
    final locale = Localizations.localeOf(context).languageCode;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            shrinkWrap: true,
            children: [
              Text(
                context.strings.dayDetails,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(DateFormat.yMMMMEEEEd(locale).format(day)),
              const SizedBox(height: 20),
              _DayValue(
                label: context.strings.income,
                value: context.money(summary.incomeOn(day), profile.currency),
                color: GainlyTheme.positive,
              ),
              const SizedBox(height: 10),
              _DayValue(
                label: context.strings.expenses,
                value: context.money(summary.expensesOn(day), profile.currency),
                color: GainlyTheme.negative,
              ),
              const Divider(height: 28),
              _DayValue(
                label: context.strings.performanceResult,
                value: context.signedMoney(
                  summary.resultOn(day),
                  profile.currency,
                ),
                color: stateColor(summary.stateOn(day)),
              ),
              if (transactions.isNotEmpty) ...[
                const SizedBox(height: 24),
                ...transactions.map((transaction) {
                  final category = widget.controller.categories
                      .where((value) => value.id == transaction.categoryId)
                      .firstOrNull;
                  final source = widget.controller.sources
                      .where((value) => value.id == transaction.sourceId)
                      .firstOrNull;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      transaction.type == TransactionType.income
                          ? Icons.south_west
                          : Icons.north_east,
                      color: transaction.type == TransactionType.income
                          ? GainlyTheme.positive
                          : GainlyTheme.negative,
                    ),
                    title: Text(
                      source?.name ??
                          (category == null
                              ? context.strings.other
                              : context.categoryName(category)),
                    ),
                    subtitle: transaction.note == null
                        ? null
                        : Text(transaction.note!),
                    trailing: Text(
                      context.signedMoney(
                        transaction.signedAmount,
                        profile.currency,
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.controller.profile!;
    final summary = FinancialSummary(profile, widget.controller.transactions);
    final locale = Localizations.localeOf(context).languageCode;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final totalCells = firstWeekday - 1 + days;
    final rowCount = (totalCells / 7).ceil();
    final weekdayLabels = List.generate(
      7,
      (index) => DateFormat.E(locale).format(DateTime(2024, 1, 1 + index)),
    );

    return RefreshIndicator(
      onRefresh: widget.controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: context.strings.previousMonth,
                onPressed: () => changeMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  DateFormat.yMMMM(locale).format(month),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: context.strings.nextMonth,
                onPressed: () => changeMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: weekdayLabels
                .map(
                  (label) => Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: rowCount > 5 ? 0.78 : 0.72,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: rowCount * 7,
            itemBuilder: (context, index) {
              final number = index - firstWeekday + 2;
              if (number < 1 || number > days) return const SizedBox.shrink();
              final day = DateTime(month.year, month.month, number);
              final state = summary.stateOn(day);
              final hasActivity = state != DayState.noActivity;
              final color = stateColor(state);
              return InkWell(
                key: Key('calendarDay-${dateKey(day)}'),
                borderRadius: BorderRadius.circular(14),
                onTap: () => showDay(day, summary),
                child: Ink(
                  decoration: BoxDecoration(
                    color: hasActivity
                        ? color.withValues(alpha: 0.09)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 7,
                    ),
                    child: Column(
                      children: [
                        Text('$number'),
                        const Spacer(),
                        if (hasActivity)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              context.signedMoney(
                                summary.resultOn(day),
                                profile.currency,
                              ),
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayValue extends StatelessWidget {
  const _DayValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
