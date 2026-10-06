import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../app/ledger_controller.dart';
import '../../core/domain/finance.dart';
import '../../localization/formatters.dart';
import '../../shared/localized_form_validation.dart';

class TransactionForm extends StatefulWidget {
  const TransactionForm({
    super.key,
    required this.controller,
    this.transaction,
  });
  final LedgerController controller;
  final LedgerTransaction? transaction;
  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm>
    with LocalizedFormValidation<TransactionForm> {
  @override
  final form = GlobalKey<FormState>();
  final amount = TextEditingController(),
      note = TextEditingController(),
      source = TextEditingController();
  late final String id;
  TransactionType type = TransactionType.income;
  PaymentMethod method = PaymentMethod.other;
  DateTime date = DateTime.now();
  Category? category;
  bool included = true, quick = false, busy = false, error = false;
  List<Category> get categories =>
      widget.controller.categories.where((c) => c.type == type).toList();
  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    id = transaction?.id ?? const Uuid().v4();
    if (transaction == null) {
      selectDefault();
      return;
    }
    amount.text = moneyInput(transaction.amountMinor);
    note.text = transaction.note ?? '';
    type = transaction.type;
    method = transaction.paymentMethod;
    date = transaction.date;
    category = widget.controller.categories
        .where((value) => value.id == transaction.categoryId)
        .firstOrNull;
    included = transaction.countsTowardPerformance;
    quick = transaction.entryMode == 'quick';
    source.text =
        widget.controller.sources
            .where((value) => value.id == transaction.sourceId)
            .map((value) => value.name)
            .firstOrNull ??
        '';
  }

  void selectDefault() {
    category = categories.isEmpty
        ? null
        : categories.firstWhere(
            (c) =>
                c.translationKey ==
                (type == TransactionType.income ? 'delivery' : 'food'),
            orElse: () => categories.first,
          );
    included = category?.countsTowardPerformance ?? true;
  }

  @override
  void dispose() {
    amount.dispose();
    note.dispose();
    source.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!validateForm() || category == null) return;
    setState(() {
      busy = true;
      error = false;
    });
    try {
      String? sourceId = widget.transaction?.sourceId;
      if (!quick && source.text.trim().isNotEmpty) {
        final existing = widget.controller.sources
            .where(
              (value) =>
                  value.id == widget.transaction?.sourceId &&
                  value.name == source.text.trim(),
            )
            .firstOrNull;
        sourceId = existing?.id;
        sourceId ??= (await widget.controller.saveSourceName(source.text)).id;
      }
      await widget.controller.saveTransaction(
        LedgerTransaction(
          id: id,
          userId: widget.controller.profile!.userId,
          amountMinor: parseMoney(amount.text),
          type: type,
          date: date,
          categoryId: category!.id,
          sourceId: sourceId,
          paymentMethod: method,
          note: note.text.trim().isEmpty ? null : note.text.trim(),
          countsTowardPerformance: included,
          entryMode: quick ? 'quick' : 'detailed',
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => error = true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.transaction == null ? s.addTransaction : s.editTransaction,
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<TransactionType>(
                      segments: [
                        ButtonSegment(
                          value: TransactionType.income,
                          label: Text(s.income),
                          icon: const Icon(Icons.south_west),
                        ),
                        ButtonSegment(
                          value: TransactionType.expense,
                          label: Text(s.expense),
                          icon: const Icon(Icons.north_east),
                        ),
                      ],
                      selected: {type},
                      onSelectionChanged: busy
                          ? null
                          : (v) => setState(() {
                              type = v.first;
                              selectDefault();
                            }),
                    ),
                    const SizedBox(height: 20),
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(value: false, label: Text(s.detailed)),
                        ButtonSegment(value: true, label: Text(s.quick)),
                      ],
                      selected: {quick},
                      onSelectionChanged: busy
                          ? null
                          : (v) => setState(() => quick = v.first),
                    ),
                    const SizedBox(height: 20),
                    if (quick)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(s.quickHelp),
                      ),
                    TextFormField(
                      key: const Key('transactionAmount'),
                      controller: amount,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: s.amount,
                        suffixText: widget.controller.profile!.currency,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        try {
                          if (parseMoney(v ?? '') > 0) return null;
                        } catch (_) {
                          /* Report localized validation below. */
                        }
                        return s.invalidAmount;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey('category-${type.name}'),
                      initialValue: category?.id,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: s.category),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(context.categoryName(c)),
                            ),
                          )
                          .toList(),
                      validator: (v) => v == null ? s.required : null,
                      onChanged: busy
                          ? null
                          : (id) => setState(() {
                              category = categories.firstWhere(
                                (c) => c.id == id,
                              );
                              included = category!.countsTowardPerformance;
                            }),
                    ),
                    const SizedBox(height: 16),
                    if (!quick) ...[
                      TextFormField(
                        controller: source,
                        maxLength: 100,
                        decoration: InputDecoration(
                          labelText: s.source,
                          hintText: s.unspecified,
                        ),
                      ),
                      if (widget.controller.sources.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: widget.controller.sources
                              .take(8)
                              .map(
                                (v) => ActionChip(
                                  label: Text(v.name),
                                  onPressed: busy
                                      ? null
                                      : () => setState(
                                          () => source.text = v.name,
                                        ),
                                ),
                              )
                              .toList(),
                        ),
                      const SizedBox(height: 16),
                    ],
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () async {
                              final selected = await showDatePicker(
                                context: context,
                                initialDate: date,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (selected != null && mounted) {
                                setState(() => date = selected);
                              }
                            },
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        '${s.date}: ${DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(date)}',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<PaymentMethod>(
                      initialValue: method,
                      decoration: InputDecoration(labelText: s.paymentMethod),
                      items: [
                        DropdownMenuItem(
                          value: PaymentMethod.cash,
                          child: Text(s.cash),
                        ),
                        DropdownMenuItem(
                          value: PaymentMethod.bankCard,
                          child: Text(s.bankCard),
                        ),
                        DropdownMenuItem(
                          value: PaymentMethod.bankTransfer,
                          child: Text(s.bankTransfer),
                        ),
                        DropdownMenuItem(
                          value: PaymentMethod.other,
                          child: Text(s.other),
                        ),
                      ],
                      onChanged: busy
                          ? null
                          : (v) => setState(() => method = v!),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: note,
                      maxLength: 500,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: s.note,
                        hintText: s.optional,
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.included),
                      value: included,
                      onChanged: busy
                          ? null
                          : (v) => setState(() => included = v),
                    ),
                    const SizedBox(height: 16),
                    if (error)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          s.saveError,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    FilledButton(
                      onPressed: busy ? null : save,
                      child: busy
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(s.save),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
