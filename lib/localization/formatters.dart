import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/domain/finance.dart';
import 'app_localizations.dart';

extension GainlyStrings on BuildContext {
  AppLocalizations get strings => AppLocalizations.of(this);
  String money(int minor, String currency) {
    final locale = Localizations.localeOf(this).languageCode;
    final symbol = switch (currency) {
      'EUR' => '€',
      'GBP' => '£',
      _ => r'$',
    };
    final whole = NumberFormat.decimalPattern(locale)
        .format(minor.abs() ~/ 100);
    final fraction = (minor.abs() % 100).toString().padLeft(2, '0');
    final decimal = locale == 'en' ? '.' : ',';
    final value = '$whole$decimal$fraction';
    return '${minor < 0 ? '−' : ''}${locale == 'en' ? '$symbol$value' : '$value\u00a0$symbol'}';
  }

  String signedMoney(int minor, String currency) =>
      minor > 0 ? '+${money(minor, currency)}' : money(minor, currency);

  String categoryName(Category category) {
    final s = strings;
    return switch (category.translationKey) {
      'delivery' => s.delivery,
      'rideshare' => s.rideshare,
      'freelance' => s.freelance,
      'sales' => s.sales,
      'salary' => s.salary,
      'benefits' => s.benefits,
      'refund' => s.refund,
      'gift' => s.gift,
      'food' => s.food,
      'fuel' => s.fuel,
      'transport' => s.transport,
      'housing' => s.housing,
      'bills' => s.bills,
      'shopping' => s.shopping,
      'leisure' => s.leisure,
      'health' => s.health,
      'workExpenses' => s.workExpenses,
      'other' => s.other,
      _ => category.name,
    };
  }
}
