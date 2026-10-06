import 'package:flutter/material.dart';

import '../../shared/localized_form_validation.dart';

import '../../core/domain/finance.dart';
import '../../localization/formatters.dart';

class ProfileForm extends StatefulWidget {
  const ProfileForm({
    super.key,
    required this.userId,
    required this.onSave,
    required this.onLocale,
    this.profile,
    this.currencyLocked = false,
  });
  final String userId;
  final Profile? profile;
  final bool currencyLocked;
  final Future<void> Function(Profile profile) onSave;
  final ValueChanged<Locale> onLocale;
  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm>
    with LocalizedFormValidation<ProfileForm> {
  @override
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.profile?.firstName);
  late final balance = TextEditingController(
    text: moneyInput(widget.profile?.startingBalance),
  );
  late final performance = TextEditingController(
    text: moneyInput(widget.profile?.startingPerformanceBalance),
  );
  late final monthlyTarget = TextEditingController(
    text: moneyInput(widget.profile?.monthlyTarget),
  );
  late final dailyMinimum = TextEditingController(
    text: moneyInput(
      widget.profile?.dailyMinimum ??
          (widget.profile?.monthlyTarget == null
              ? null
              : widget.profile!.monthlyTarget! ~/ 30),
    ),
  );
  late bool dailyMinimumEdited = widget.profile?.dailyMinimum != null;
  String? language;
  late String currency = widget.profile?.currency ?? 'EUR';
  bool busy = false, error = false;
  @override
  void dispose() {
    name.dispose();
    balance.dispose();
    performance.dispose();
    monthlyTarget.dispose();
    dailyMinimum.dispose();
    super.dispose();
  }

  String? validateMoney(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      parseMoney(value, allowNegative: true);
      return null;
    } catch (_) {
      return context.strings.invalidAmount;
    }
  }

  String? validatePositiveMoney(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      return parseMoney(value) > 0 ? null : context.strings.invalidAmount;
    } catch (_) {
      return context.strings.invalidAmount;
    }
  }

  void updateDailyMinimumSuggestion(String value) {
    if (dailyMinimumEdited) return;
    if (value.trim().isEmpty) {
      dailyMinimum.clear();
      return;
    }
    try {
      dailyMinimum.text = moneyInput(parseMoney(value) ~/ 30);
    } catch (_) {
      dailyMinimum.clear();
    }
  }

  Future<void> save() async {
    if (!validateForm()) return;
    setState(() {
      busy = true;
      error = false;
    });
    try {
      await widget.onSave(
        Profile(
          userId: widget.userId,
          firstName: name.text.trim(),
          language:
              language ??
              widget.profile?.language ??
              Localizations.localeOf(context).languageCode,
          currency: currency,
          startingBalance: balance.text.trim().isEmpty
              ? null
              : parseMoney(balance.text, allowNegative: true),
          startingPerformanceBalance: performance.text.trim().isEmpty
              ? null
              : parseMoney(performance.text, allowNegative: true),
          monthlyTarget: monthlyTarget.text.trim().isEmpty
              ? null
              : parseMoney(monthlyTarget.text),
          dailyMinimum: dailyMinimum.text.trim().isEmpty
              ? null
              : parseMoney(dailyMinimum.text),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => error = true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.profile == null ? s.onboardingTitle : s.settings,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                if (widget.profile == null) Text(s.onboardingBody),
                const SizedBox(height: 24),
                TextFormField(
                  controller: name,
                  maxLength: 60,
                  decoration: InputDecoration(labelText: s.firstName),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? s.required : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue:
                      language ??
                      widget.profile?.language ??
                      Localizations.localeOf(context).languageCode,
                  decoration: InputDecoration(labelText: s.language),
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'fr', child: Text('Français')),
                    DropdownMenuItem(value: 'es', child: Text('Español')),
                  ],
                  onChanged: busy
                      ? null
                      : (v) {
                          setState(() => language = v!);
                          widget.onLocale(Locale(v!));
                        },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: currency,
                  decoration: InputDecoration(
                    labelText: s.currency,
                    helperText: widget.currencyLocked ? s.currencyLocked : null,
                    helperMaxLines: 3,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                    DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                    DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                  ],
                  onChanged: busy || widget.currencyLocked
                      ? null
                      : (v) => setState(() => currency = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('startingBalance'),
                  controller: balance,
                  decoration: InputDecoration(
                    labelText: s.startingBalance,
                    hintText: s.optional,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: validateMoney,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('startingPerformanceBalance'),
                  controller: performance,
                  decoration: InputDecoration(
                    labelText: s.startingPerformanceBalance,
                    hintText: s.optional,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: validateMoney,
                ),
                if (widget.profile != null) ...[
                  const SizedBox(height: 24),
                  Text(s.goals, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('monthlyTarget'),
                    controller: monthlyTarget,
                    decoration: InputDecoration(
                      labelText: s.monthlyTarget,
                      helperText: s.monthlyTargetHelp,
                      helperMaxLines: 2,
                      hintText: s.optional,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: validatePositiveMoney,
                    onChanged: updateDailyMinimumSuggestion,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('dailyMinimum'),
                    controller: dailyMinimum,
                    decoration: InputDecoration(
                      labelText: s.dailyMinimum,
                      helperText: s.dailyMinimumHelp,
                      helperMaxLines: 2,
                      hintText: s.optional,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: validatePositiveMoney,
                    onChanged: (_) => dailyMinimumEdited = true,
                  ),
                ],
                const SizedBox(height: 24),
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
                      : Text(widget.profile == null ? s.start : s.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
