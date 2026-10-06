import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app/ledger_controller.dart';
import '../../core/domain/finance.dart';
import '../../localization/formatters.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key, required this.controller});

  final LedgerController controller;

  Future<void> editCategory(BuildContext context, [Category? category]) =>
      showDialog<void>(
        context: context,
        builder: (_) =>
            _CategoryDialog(controller: controller, category: category),
      );

  Future<void> editSource(BuildContext context, [IncomeSource? source]) =>
      showDialog<void>(
        context: context,
        builder: (_) => _SourceDialog(controller: controller, source: source),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final strings = context.strings;
      final income = controller.categories.where(
        (category) => category.type == TransactionType.income,
      );
      final expenses = controller.categories.where(
        (category) => category.type == TransactionType.expense,
      );
      return Scaffold(
        appBar: AppBar(title: Text(strings.manageCatalog)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionTitle(
              strings.incomeCategories,
              action: IconButton(
                key: const Key('addCategory'),
                tooltip: strings.addCategory,
                onPressed: () => editCategory(context),
                icon: const Icon(Icons.add),
              ),
            ),
            ...income.map(
              (category) => ListTile(
                title: Text(context.categoryName(category)),
                subtitle: Text(
                  category.countsTowardPerformance
                      ? strings.included
                      : strings.excluded,
                ),
                trailing: IconButton(
                  key: Key('editCategory-${category.id}'),
                  tooltip: strings.edit,
                  onPressed: () => editCategory(context, category),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionTitle(strings.expenseCategories),
            ...expenses.map(
              (category) => ListTile(
                title: Text(context.categoryName(category)),
                subtitle: Text(
                  category.countsTowardPerformance
                      ? strings.included
                      : strings.excluded,
                ),
                trailing: IconButton(
                  key: Key('editCategory-${category.id}'),
                  tooltip: strings.edit,
                  onPressed: () => editCategory(context, category),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionTitle(
              strings.sources,
              action: IconButton(
                key: const Key('addSource'),
                tooltip: strings.addSource,
                onPressed: () => editSource(context),
                icon: const Icon(Icons.add),
              ),
            ),
            ...controller.sources.map(
              (source) => ListTile(
                title: Text(source.name),
                trailing: IconButton(
                  key: Key('editSource-${source.id}'),
                  tooltip: strings.edit,
                  onPressed: () => editSource(context, source),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _SourceDialog extends StatefulWidget {
  const _SourceDialog({required this.controller, this.source});

  final LedgerController controller;
  final IncomeSource? source;

  @override
  State<_SourceDialog> createState() => _SourceDialogState();
}

class _SourceDialogState extends State<_SourceDialog> {
  late final name = TextEditingController(text: widget.source?.name);
  var busy = false;
  var failed = false;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final value = name.text.trim();
    if (value.isEmpty) return;
    setState(() {
      busy = true;
      failed = false;
    });
    try {
      await widget.controller.saveSourceName(value, source: widget.source);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return AlertDialog(
      title: Text(
        widget.source == null ? strings.newSource : strings.editSource,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('catalogName'),
            controller: name,
            autofocus: true,
            decoration: InputDecoration(labelText: strings.sourceName),
          ),
          if (failed)
            Text(
              strings.saveError,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton(onPressed: busy ? null : save, child: Text(strings.save)),
      ],
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.controller, this.category});

  final LedgerController controller;
  final Category? category;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final name = TextEditingController(text: widget.category?.name);
  late var type = widget.category?.type ?? TransactionType.income;
  late var included = widget.category?.countsTowardPerformance ?? true;
  var busy = false;
  var failed = false;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final value = name.text.trim();
    if (value.isEmpty) return;
    setState(() {
      busy = true;
      failed = false;
    });
    try {
      await widget.controller.saveCategory(
        Category(
          id: widget.category?.id ?? const Uuid().v4(),
          name: value,
          type: type,
          countsTowardPerformance: included,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return AlertDialog(
      title: Text(
        widget.category == null ? strings.newCategory : strings.editCategory,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('catalogName'),
              controller: name,
              autofocus: true,
              decoration: InputDecoration(labelText: strings.categoryName),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TransactionType>(
              key: const Key('catalogType'),
              initialValue: type,
              decoration: InputDecoration(labelText: strings.categoryType),
              items: [
                DropdownMenuItem(
                  value: TransactionType.income,
                  child: Text(strings.income),
                ),
                DropdownMenuItem(
                  value: TransactionType.expense,
                  child: Text(strings.expense),
                ),
              ],
              onChanged: busy || widget.category != null
                  ? null
                  : (value) => setState(() => type = value!),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(strings.defaultPerformance),
              value: included,
              onChanged: busy
                  ? null
                  : (value) => setState(() => included = value),
            ),
            if (failed)
              Text(
                strings.saveError,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton(onPressed: busy ? null : save, child: Text(strings.save)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.titleMedium),
        ),
        ?action,
      ],
    ),
  );
}
