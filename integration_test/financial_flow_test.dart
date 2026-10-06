import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gainly/app/gainly_app.dart';
import 'package:gainly/app/ledger_controller.dart';
import 'package:gainly/app/theme.dart';
import 'package:gainly/localization/app_localizations.dart';

import '../test/support/memory_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native onboarding, transaction entry, and balance display', (
    tester,
  ) async {
    final repository = MemoryRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: GainlyTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: FinancialWorkspace(
          userId: 'synthetic-user',
          controller: LedgerController(repository),
          onLocale: (_) {},
          onLogout: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Alex');
    await tester.enterText(find.byKey(const Key('startingBalance')), '1000');
    await tester.enterText(
      find.byKey(const Key('startingPerformanceBalance')),
      '250',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start tracking'));
    await tester.tap(find.text('Start tracking'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add transaction'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('transactionAmount')), '50.29');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('€1,050.29'), findsOneWidget);
    expect(find.text('€300.29'), findsOneWidget);
    expect(repository.entries.single.amountMinor, 5029);
  });
}
