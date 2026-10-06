import 'package:flutter/material.dart';

/// FormField caches error strings. Revalidate after localized descendants rebuild.
mixin LocalizedFormValidation<T extends StatefulWidget> on State<T> {
  GlobalKey<FormState> get form;
  Locale? _validatedLocale;
  bool _validationAttempted = false;

  bool validateForm() {
    _validationAttempted = true;
    return form.currentState!.validate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    if (_validatedLocale != null &&
        _validatedLocale != locale &&
        _validationAttempted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) form.currentState?.validate();
      });
    }
    _validatedLocale = locale;
  }
}
