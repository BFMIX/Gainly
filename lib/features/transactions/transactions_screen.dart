import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/ledger_controller.dart';
import '../../app/theme.dart';
import '../../core/domain/finance.dart';
import '../../localization/formatters.dart';
import 'transaction_form.dart';

enum _Period { sevenDays, thirtyDays, thisMonth, thisYear, custom }

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, required this.controller});

  final LedgerController controller;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final search = TextEditingController();
  _Period period = _Period.thisMonth;
  TransactionType? type;
  String? categoryId;
  String? sourceId;
  bool? included;
  DateTimeRange? customRange;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  DateTime startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool inPeriod(LedgerTransaction transaction) {
    final now = startOfDay(DateTime.now());
    final date = startOfDay(transaction.date);
    return switch (period) {
      _Period.sevenDays =>
        !date.isBefore(now.subtract(const Duration(days: 6))) &&
            !date.isAfter(now),
      _Period.thirtyDays =>
        !date.isBefore(now.subtract(const Duration(days: 29))) &&
            !date.isAfter(now),
      _Period.thisMonth => date.year == now.year && date.month == now.month,
      _Period.thisYear => date.year == now.year,
      _Period.custom =>
        customRange == null ||
            (!date.isBefore(startOfDay(customRange!.start)) &&
                !date.isAfter(startOfDay(customRange!.end))),
    };
  }

  List<LedgerTransaction> get filtered {
    final query = search.text.trim().toLowerCase();
    final result = widget.controller.transactions.where((transaction) {
      if (!inPeriod(transaction) ||
          (type != null && transaction.type != type) ||
          (categoryId != null && transaction.categoryId != categoryId) ||
          (sourceId != null && transaction.sourceId != sourceId) ||
          (included != null &&
              transaction.countsTowardPerformance != included)) {
        return false;
      }
      if (query.isEmpty) return true;
      final category = widget.controller.categories
          .where((value) => value.id == transaction.categoryId)
          .firstOrNull;
      final source = widget.controller.sources
          .where((value) => value.id == transaction.sourceId)
          .firstOrNull;
      return [
        transaction.note,
        category?.name,
        category?.translationKey,
        source?.name,
      ].whereType<String>().any((value) => value.toLowerCase().contains(query));
    }).toList();
    result.sort((a, b) {
      final day = b.date.compareTo(a.date);
      return day != 0
          ? day
          : (b.createdAt ?? b.date).compareTo(a.createdAt ?? a.date);
    });
    return result;
  }

  String periodLabel(BuildContext context, _Period value) => switch (value) {
    _Period.sevenDays => context.strings.sevenDays,
    _Period.thirtyDays => context.strings.thirtyDays,
    _Period.thisMonth => context.strings.thisMonth,
    _Period.thisYear => context.strings.thisYear,
    _Period.custom => context.strings.customPeriod,
  };

  void clearFilters() {
    setState(() {
      search.clear();
      period = _Period.thisMonth;
      type = null;
      categoryId = null;
      sourceId = null;
      included = null;
      customRange = null;
    });
  }

  Future<void> selectPeriod(_Period value) async {
    if (value != _Period.custom) {
      setState(() => period = value);
      return;
    }
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: customRange,
    );
    if (selected != null && mounted) {
      setState(() {
        customRange = selected;
        period = value;
      });
    }
  }

  Future<void> edit(LedgerTransaction transaction) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionForm(
          controller: widget.controller,
          transaction: transaction,
        ),
      ),
    );
    if (saved == true && mounted) setState(() {});
  }

  Future<void> remove(LedgerTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.strings.deleteTransactionTitle),
        content: Text(context.strings.deleteTransactionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.strings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.controller.deleteTransaction(transaction);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.strings.deleted)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.strings.deleteError)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = filtered;
    final profile = widget.controller.profile!;
    final locale = Localizations.localeOf(context).languageCode;
    return RefreshIndicator(
      onRefresh: widget.controller.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          TextField(
            key: const Key('transactionSearch'),
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: context.strings.searchTransactions,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: search.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () => setState(search.clear),
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                key: const Key('filterIncome'),
                label: Text(context.strings.income),
                selected: type == TransactionType.income,
                onSelected: (selected) => setState(
                  () => type = selected ? TransactionType.income : null,
                ),
              ),
              FilterChip(
                key: const Key('filterExpense'),
                label: Text(context.strings.expense),
                selected: type == TransactionType.expense,
                onSelected: (selected) => setState(
                  () => type = selected ? TransactionType.expense : null,
                ),
              ),
            ],
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(context.strings.filters),
            leading: const Icon(Icons.tune),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  DropdownMenu<_Period>(
                    initialSelection: period,
                    label: Text(context.strings.period),
                    dropdownMenuEntries: _Period.values
                        .map(
                          (value) => DropdownMenuEntry(
                            value: value,
                            label: periodLabel(context, value),
                          ),
                        )
                        .toList(),
                    onSelected: (value) {
                      if (value != null) selectPeriod(value);
                    },
                  ),
                  ChoiceChip(
                    label: Text(context.strings.included),
                    selected: included == true,
                    onSelected: (selected) =>
                        setState(() => included = selected ? true : null),
                  ),
                  ChoiceChip(
                    label: Text(context.strings.excluded),
                    selected: included == false,
                    onSelected: (selected) =>
                        setState(() => included = selected ? false : null),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: categoryId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.strings.category,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(context.strings.allCategories),
                        ),
                        ...widget.controller.categories.map(
                          (category) => DropdownMenuItem(
                            value: category.id,
                            child: Text(context.categoryName(category)),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => categoryId = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: sourceId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.strings.source,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text(context.strings.allSources),
                        ),
                        ...widget.controller.sources.map(
                          (source) => DropdownMenuItem(
                            value: source.id,
                            child: Text(source.name),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => sourceId = value),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: clearFilters,
                  child: Text(context.strings.clearFilters),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                context.strings.noTransactions,
                textAlign: TextAlign.center,
              ),
            ),
          ...transactions.map((transaction) {
            final category = widget.controller.categories
                .where((value) => value.id == transaction.categoryId)
                .firstOrNull;
            final source = widget.controller.sources
                .where((value) => value.id == transaction.sourceId)
                .firstOrNull;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                key: Key('edit-${transaction.id}'),
                onTap: () => edit(transaction),
                leading: Icon(
                  transaction.type == TransactionType.income
                      ? Icons.south_west
                      : Icons.north_east,
                  color: transaction.type == TransactionType.income
                      ? GainlyTheme.positive
                      : GainlyTheme.negative,
                ),
                title: Text(
                  transaction.note ??
                      source?.name ??
                      (category == null
                          ? context.strings.other
                          : context.categoryName(category)),
                ),
                subtitle: Text(
                  '${DateFormat.yMMMd(locale).format(transaction.date)} · ${category == null ? context.strings.other : context.categoryName(category)} · ${transaction.countsTowardPerformance ? context.strings.included : context.strings.excluded}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.money(transaction.signedAmount, profile.currency),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      key: Key('delete-${transaction.id}'),
                      tooltip: context.strings.delete,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => remove(transaction),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
