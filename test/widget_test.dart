import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gainly/app/gainly_app.dart';
import 'package:gainly/app/ledger_controller.dart';
import 'package:gainly/app/theme.dart';
import 'package:gainly/core/data/cached_ledger_repository.dart';
import 'package:gainly/core/data/ledger_repository.dart';
import 'package:gainly/core/domain/finance.dart';
import 'package:gainly/localization/app_localizations.dart';

import 'support/memory_repository.dart';

import 'package:gainly/features/auth/auth_screen.dart';

class WidgetLedgerStore implements LedgerLocalStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String userId) async => values[userId];
  @override
  Future<void> write(String userId, String value) async {
    values[userId] = value;
  }
}

Widget workspace(LedgerRepository repo, {String locale = 'en'}) => MaterialApp(
  theme: GainlyTheme.light,
  locale: Locale(locale),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: FinancialWorkspace(
    userId: 'owner',
    controller: LedgerController(repo),
    onLocale: (_) {},
    onLogout: () async {},
  ),
);
void main() {
  test('auth redirect preserves a GitHub Pages project path', () {
    expect(
      authRedirect(
        isWeb: true,
        base: Uri.parse('https://bfmix.github.io/Gainly/'),
      ),
      'https://bfmix.github.io/Gainly/',
    );
    expect(
      authRedirect(isWeb: true, base: Uri.parse('http://localhost:7357/')),
      'http://localhost:7357',
    );
    expect(
      authRedirect(isWeb: false, base: Uri.parse('https://ignored.test/')),
      'com.bfmix.gainly://auth-callback',
    );
  });
  testWidgets('existing auth validation follows a locale change', (
    tester,
  ) async {
    final locale = ValueNotifier(const Locale('en'));
    addTearDown(locale.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<Locale>(
        valueListenable: locale,
        builder: (context, value, _) => MaterialApp(
          locale: value,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: AuthScreen(
            onGoogle: () async {},
            onApple: () async {},
            onEmail: (_) async {},
            onLocale: (value) => locale.value = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue with Email'));
    await tester.tap(find.text('Continue with Email'));
    await tester.pumpAndSettle();
    expect(find.text('This field is required'), findsOneWidget);
    locale.value = const Locale('fr');
    await tester.pumpAndSettle();
    expect(find.text('Ce champ est obligatoire'), findsOneWidget);
    expect(find.text('This field is required'), findsNothing);
  });
  testWidgets('missing config shows localized setup state', (tester) async {
    await tester.pumpWidget(const GainlyApp());
    await tester.pumpAndSettle();
    expect(find.text('Gainly is not connected yet'), findsOneWidget);
  });
  testWidgets('cached workspace explains offline data and pending changes', (
    tester,
  ) async {
    final remote = MemoryRepository()
      ..profile = const Profile(
        userId: 'owner',
        firstName: 'Alex',
        language: 'en',
        currency: 'EUR',
        startingBalance: 0,
        startingPerformanceBalance: 0,
      );
    final store = WidgetLedgerStore();
    final online = CachedLedgerRepository(
      userId: 'owner',
      remote: remote,
      store: store,
    );
    await online.loadProfile();
    remote.failWrites = true;
    await online.saveTransaction(
      LedgerTransaction(
        id: 'pending',
        userId: 'owner',
        amountMinor: 1200,
        type: TransactionType.income,
        date: DateTime.now(),
        categoryId: 'delivery',
        countsTowardPerformance: true,
      ),
    );
    remote.failReads = true;
    final restarted = CachedLedgerRepository(
      userId: 'owner',
      remote: remote,
      store: store,
    );

    await tester.pumpWidget(workspace(restarted));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Offline — your changes are saved on this device and will sync automatically.',
      ),
      findsOneWidget,
    );
    expect(find.text('Sync now'), findsOneWidget);
    expect(find.text('€12.00'), findsWidgets);
  });
  testWidgets('profile opens category and source management', (tester) async {
    final repo = MemoryRepository()
      ..profile = const Profile(
        userId: 'owner',
        firstName: 'Alex',
        language: 'en',
        currency: 'EUR',
        startingBalance: 0,
        startingPerformanceBalance: 0,
      );

    await tester.pumpWidget(workspace(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Categories and sources'), findsOneWidget);
    await tester.ensureVisible(find.text('Categories and sources'));
    await tester.tap(find.text('Categories and sources'));
    await tester.pumpAndSettle();

    expect(find.text('Manage categories and sources'), findsOneWidget);
    expect(find.text('Income categories'), findsOneWidget);
    expect(find.text('Expense categories'), findsOneWidget);
    expect(find.text('Sources'), findsOneWidget);
  });
  testWidgets('a custom category remains available after refresh', (
    tester,
  ) async {
    final repo = MemoryRepository()
      ..profile = const Profile(
        userId: 'owner',
        firstName: 'Alex',
        language: 'en',
        currency: 'EUR',
        startingBalance: 0,
        startingPerformanceBalance: 0,
      );

    await tester.pumpWidget(workspace(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Categories and sources'));
    await tester.tap(find.text('Categories and sources'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('addCategory')), findsOneWidget);
    await tester.tap(find.byKey(const Key('addCategory')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('catalogName')), 'Tips');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Tips'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Categories and sources'));
    await tester.tap(find.text('Categories and sources'));
    await tester.pumpAndSettle();
    expect(find.text('Tips'), findsOneWidget);
  });
  testWidgets('editing a category saves its name and performance default', (
    tester,
  ) async {
    final repo = MemoryRepository()
      ..profile = const Profile(
        userId: 'owner',
        firstName: 'Alex',
        language: 'en',
        currency: 'EUR',
        startingBalance: 0,
        startingPerformanceBalance: 0,
      );

    await tester.pumpWidget(workspace(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Categories and sources'));
    await tester.tap(find.text('Categories and sources'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('editCategory-delivery')), findsOneWidget);
    await tester.tap(find.byKey(const Key('editCategory-delivery')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('catalogName')),
      'Courier work',
    );
    await tester.tap(find.byType(Switch).last);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = repo.categories.singleWhere(
      (category) => category.id == 'delivery',
    );
    expect(saved.name, 'Courier work');
    expect(saved.translationKey, isNull);
    expect(saved.countsTowardPerformance, isFalse);
    expect(find.text('Courier work'), findsOneWidget);
    expect(find.text('Excluded from Performance'), findsWidgets);
  });
  testWidgets('a source can be created, renamed, and reloaded', (tester) async {
    final repo = MemoryRepository()
      ..profile = const Profile(
        userId: 'owner',
        firstName: 'Alex',
        language: 'en',
        currency: 'EUR',
        startingBalance: 0,
        startingPerformanceBalance: 0,
      );

    await tester.pumpWidget(workspace(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Categories and sources'));
    await tester.tap(find.text('Categories and sources'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('addSource')), findsOneWidget);
    await tester.tap(find.byKey(const Key('addSource')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('catalogName')), 'Uber Eats');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Uber Eats'), findsOneWidget);

    await tester.tap(find.byKey(Key('editSource-${repo.sources.single.id}')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('catalogName')), 'Deliveroo');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Deliveroo'), findsOneWidget);
    expect(find.text('Uber Eats'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Categories and sources'));
    await tester.tap(find.text('Categories and sources'));
    await tester.pumpAndSettle();
    expect(find.text('Deliveroo'), findsOneWidget);
  });
  testWidgets(
    'onboarding to persisted income updates both balances and survives controller reload',
    (tester) async {
      final repo = MemoryRepository();
      await tester.pumpWidget(workspace(repo));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Alex');
      await tester.enterText(find.byKey(const Key('startingBalance')), '1000');
      await tester.enterText(
        find.byKey(const Key('startingPerformanceBalance')),
        '250',
      );
      await tester.ensureVisible(find.text('Start tracking'));
      await tester.tap(find.text('Start tracking'));
      await tester.pumpAndSettle();
      expect(find.text('€1,000.00'), findsOneWidget);
      expect(find.text('€250.00'), findsOneWidget);
      await tester.tap(find.text('Add transaction'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('transactionAmount')),
        '50.29',
      );
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repo.entries.single.amountMinor, 5029);
      expect(find.text('€1,050.29'), findsOneWidget);
      expect(find.text('€300.29'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(workspace(repo));
      await tester.pumpAndSettle();
      expect(find.text('€300.29'), findsOneWidget);
      expect(find.text('€1,050.29'), findsOneWidget);
    },
  );
  testWidgets('skipping baselines leaves actionable dashboard states', (
    tester,
  ) async {
    final repo = MemoryRepository();
    await tester.pumpWidget(workspace(repo));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Alex');
    await tester.ensureVisible(find.text('Start tracking'));
    await tester.tap(find.text('Start tracking'));
    await tester.pumpAndSettle();
    expect(find.text('Set your starting balance'), findsOneWidget);
    expect(find.text('Set your starting performance balance'), findsOneWidget);
    await tester.tap(find.text('Set your starting balance'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('startingBalance')), findsOneWidget);
    expect(find.text('Add transaction'), findsNothing);
  });
  for (final locale in ['fr', 'es']) {
    testWidgets('dashboard renders in $locale on a narrow screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = MemoryRepository()
        ..profile = Profile(
          userId: 'owner',
          firstName: 'Alex',
          language: locale,
          currency: 'EUR',
          startingBalance: 0,
          startingPerformanceBalance: 0,
        );
      await tester.pumpWidget(workspace(repo, locale: locale));
      await tester.pumpAndSettle();
      expect(
        find.text(
          locale == 'fr' ? 'Solde de performance' : 'Saldo de rendimiento',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'failed transaction preserves form and does not change balances',
    (tester) async {
      final repo = MemoryRepository()
        ..profile = const Profile(
          userId: 'owner',
          firstName: 'Alex',
          language: 'en',
          currency: 'EUR',
          startingBalance: 0,
          startingPerformanceBalance: 0,
        )
        ..failWrites = true;
      await tester.pumpWidget(workspace(repo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add transaction'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('transactionAmount')), '10');
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repo.entries, isEmpty);
      expect(find.textContaining('Could not save'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      repo.failWrites = false;
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repo.entries.length, 1);
    },
  );

  testWidgets('calendar shows daily performance and opens day details', (
    tester,
  ) async {
    final today = DateTime.now();
    final repo = MemoryRepository()
      ..profile = const Profile(
        userId: 'owner',
        firstName: 'Alex',
        language: 'en',
        currency: 'EUR',
        startingBalance: 0,
        startingPerformanceBalance: 0,
      )
      ..entries.addAll([
        LedgerTransaction(
          id: 'income',
          userId: 'owner',
          amountMinor: 2000,
          type: TransactionType.income,
          date: today,
          categoryId: 'delivery',
          countsTowardPerformance: true,
        ),
        LedgerTransaction(
          id: 'expense',
          userId: 'owner',
          amountMinor: 500,
          type: TransactionType.expense,
          date: today,
          categoryId: 'food',
          countsTowardPerformance: true,
        ),
      ]);

    await tester.pumpWidget(workspace(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    final day = find.byKey(Key('calendarDay-${dateKey(today)}'));
    expect(day, findsOneWidget);
    expect(find.text('+€15.00'), findsOneWidget);

    await tester.tap(day);
    await tester.pumpAndSettle();
    expect(find.text('Day details'), findsOneWidget);
    expect(find.text('€20.00'), findsOneWidget);
    expect(find.text('€5.00'), findsOneWidget);
    expect(find.text('+€15.00'), findsWidgets);
  });

  testWidgets('history searches notes and soft-deletes after confirmation', (
    tester,
  ) async {
    final repo = MemoryRepository()
      ..profile = const Profile(
        userId: 'owner',
        firstName: 'Alex',
        language: 'en',
        currency: 'EUR',
        startingBalance: 0,
        startingPerformanceBalance: 0,
      )
      ..entries.addAll([
        LedgerTransaction(
          id: 'delivery-income',
          userId: 'owner',
          amountMinor: 4200,
          type: TransactionType.income,
          date: DateTime.now(),
          categoryId: 'delivery',
          note: 'Evening route',
          countsTowardPerformance: true,
        ),
        LedgerTransaction(
          id: 'lunch-expense',
          userId: 'owner',
          amountMinor: 1200,
          type: TransactionType.expense,
          date: DateTime.now(),
          categoryId: 'food',
          note: 'Lunch break',
          countsTowardPerformance: true,
        ),
      ]);

    await tester.pumpWidget(workspace(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();
    expect(find.text('Evening route'), findsOneWidget);
    expect(find.text('Lunch break'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('transactionSearch')), 'lunch');
    await tester.pumpAndSettle();
    expect(find.text('Evening route'), findsNothing);
    expect(find.text('Lunch break'), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete-lunch-expense')));
    await tester.pumpAndSettle();
    expect(find.text('Delete transaction?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(
      repo.entries
          .singleWhere((entry) => entry.id == 'lunch-expense')
          .deletedAt,
      isNotNull,
    );
    expect(find.text('Lunch break'), findsNothing);
  });

  testWidgets('history filters by type and edits an existing transaction', (
    tester,
  ) async {
    final repo = MemoryRepository()
      ..profile = const Profile(
        userId: 'owner',
        firstName: 'Alex',
        language: 'en',
        currency: 'EUR',
        startingBalance: 0,
        startingPerformanceBalance: 0,
      )
      ..entries.addAll([
        LedgerTransaction(
          id: 'income-to-hide',
          userId: 'owner',
          amountMinor: 4200,
          type: TransactionType.income,
          date: DateTime.now(),
          categoryId: 'delivery',
          note: 'Evening route',
          countsTowardPerformance: true,
        ),
        LedgerTransaction(
          id: 'expense-to-edit',
          userId: 'owner',
          amountMinor: 1200,
          type: TransactionType.expense,
          date: DateTime.now(),
          categoryId: 'food',
          note: 'Lunch break',
          countsTowardPerformance: true,
        ),
      ]);

    await tester.pumpWidget(workspace(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('filterExpense')));
    await tester.pumpAndSettle();
    expect(find.text('Evening route'), findsNothing);
    expect(find.text('Lunch break'), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit-expense-to-edit')));
    await tester.pumpAndSettle();
    expect(find.text('Edit transaction'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('transactionAmount')), '15.00');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      repo.entries
          .singleWhere((entry) => entry.id == 'expense-to-edit')
          .amountMinor,
      1500,
    );
    expect(find.text('−€15.00'), findsOneWidget);
  });

  testWidgets('daily minimum recommendation remains user-controlled', (
    tester,
  ) async {
    final repo = MemoryRepository()
      ..profile = const Profile(
        userId: 'owner',
        firstName: 'Alex',
        language: 'en',
        currency: 'EUR',
        startingBalance: 0,
        startingPerformanceBalance: 0,
      );
    await tester.pumpWidget(workspace(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('monthlyTarget')), '1500');
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('dailyMinimum')))
          .controller!
          .text,
      '50.00',
    );
    await tester.enterText(find.byKey(const Key('dailyMinimum')), '60');
    await tester.enterText(find.byKey(const Key('monthlyTarget')), '1800');
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('dailyMinimum')))
          .controller!
          .text,
      '60',
    );

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.profile!.monthlyTarget, 180000);
    expect(repo.profile!.dailyMinimum, 6000);
  });

  testWidgets('dashboard shows deterministic target and streak progress', (
    tester,
  ) async {
    final repo = MemoryRepository()
      ..profile = const Profile(
        userId: 'owner',
        firstName: 'Alex',
        language: 'en',
        currency: 'EUR',
        startingBalance: 0,
        startingPerformanceBalance: 0,
        monthlyTarget: 150000,
        dailyMinimum: 6000,
      )
      ..entries.add(
        LedgerTransaction(
          id: 'today-income',
          userId: 'owner',
          amountMinor: 90000,
          type: TransactionType.income,
          date: DateTime.now(),
          categoryId: 'delivery',
          countsTowardPerformance: true,
        ),
      );
    await tester.pumpWidget(workspace(repo));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Monthly target'), findsOneWidget);
    expect(find.text('€900.00 / €1,500.00'), findsOneWidget);
    expect(find.text('Daily minimum'), findsOneWidget);
    expect(find.text('€60.00'), findsWidgets);
    expect(find.text('Tracking streak'), findsOneWidget);
    expect(find.text('Positive Day Rate'), findsOneWidget);
  });

  testWidgets('dashboard shows earned achievements', (tester) async {
    final repo = MemoryRepository()
      ..profile = const Profile(
        userId: 'owner',
        firstName: 'Alex',
        language: 'en',
        currency: 'EUR',
        startingBalance: 0,
        startingPerformanceBalance: 0,
      )
      ..entries.add(
        LedgerTransaction(
          id: 'first-entry',
          userId: 'owner',
          amountMinor: 1000,
          type: TransactionType.income,
          date: DateTime.now(),
          categoryId: 'delivery',
          countsTowardPerformance: true,
        ),
      );

    await tester.pumpWidget(workspace(repo));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -800));
    await tester.pumpAndSettle();

    expect(find.text('Achievements'), findsOneWidget);
    expect(find.text('First entry'), findsOneWidget);
  });

  testWidgets('dashboard opens localized statistics with period totals', (
    tester,
  ) async {
    final repo = MemoryRepository()
      ..profile = const Profile(
        userId: 'owner',
        firstName: 'Alex',
        language: 'en',
        currency: 'EUR',
        startingBalance: 0,
        startingPerformanceBalance: 0,
      )
      ..entries.add(
        LedgerTransaction(
          id: 'statistics-income',
          userId: 'owner',
          amountMinor: 4200,
          type: TransactionType.income,
          date: DateTime.now(),
          categoryId: 'delivery',
          countsTowardPerformance: true,
        ),
      );
    await tester.pumpWidget(workspace(repo));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -800));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View statistics'));
    await tester.pumpAndSettle();

    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('This month'), findsOneWidget);
    expect(find.text('€42.00'), findsWidgets);
    await tester.drag(find.byType(ListView).last, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('Performance Balance evolution'), findsOneWidget);
  });
}
