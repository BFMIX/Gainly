import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/data/supabase_ledger_repository.dart';
import '../features/auth/auth_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/onboarding/profile_form.dart';
import '../features/statistics/statistics_screen.dart';
import '../features/transactions/transaction_form.dart';
import '../features/transactions/transactions_screen.dart';
import '../localization/app_localizations.dart';
import '../localization/formatters.dart';
import 'ledger_controller.dart';
import 'theme.dart';

String authRedirect({required bool isWeb, required Uri base}) {
  if (!isWeb) return 'com.bfmix.gainly://auth-callback';
  if (base.path == '/') return base.origin;
  final projectPath = base.path.endsWith('/') ? base.path : '${base.path}/';
  return '${base.origin}$projectPath';
}

class GainlyApp extends StatefulWidget {
  const GainlyApp({super.key, this.client});
  final SupabaseClient? client;
  @override
  State<GainlyApp> createState() => _GainlyAppState();
}

class _GainlyAppState extends State<GainlyApp> {
  Locale? locale;
  final navigatorKey = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Gainly',
    navigatorKey: navigatorKey,
    debugShowCheckedModeBanner: false,
    theme: GainlyTheme.light,
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: widget.client == null
        ? const SetupScreen()
        : SessionGate(
            client: widget.client!,
            onAccountChanged: () =>
                navigatorKey.currentState?.popUntil((route) => route.isFirst),
            onLocale: (v) {
              if (locale != v) setState(() => locale = v);
            },
          ),
  );
}

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.trending_up,
              size: 64,
              color: GainlyTheme.positive,
            ),
            const SizedBox(height: 24),
            Text(
              context.strings.setupTitle,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(context.strings.setupBody, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}

class SessionGate extends StatefulWidget {
  const SessionGate({
    super.key,
    required this.client,
    required this.onLocale,
    required this.onAccountChanged,
  });
  final SupabaseClient client;
  final VoidCallback onAccountChanged;
  final ValueChanged<Locale> onLocale;
  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  StreamSubscription<AuthState>? subscription;
  String? userId;
  @override
  void initState() {
    super.initState();
    userId = widget.client.auth.currentUser?.id;
    subscription = widget.client.auth.onAuthStateChange.listen(
      (state) {
        final next = state.session?.user.id;
        if (mounted && next != userId) {
          widget.onAccountChanged();
          setState(() => userId = next);
        }
      },
      onError: (Object error) {
        /* Transient refresh errors must not discard the session. */
      },
    );
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  String get redirect => authRedirect(isWeb: kIsWeb, base: Uri.base);
  Future<void> oauth(OAuthProvider provider) async {
    final launched = await widget.client.auth.signInWithOAuth(
      provider,
      redirectTo: redirect,
    );
    if (!launched) throw StateError('OAuth browser could not open');
  }

  @override
  Widget build(BuildContext context) => userId == null
      ? AuthScreen(
          onGoogle: () => oauth(OAuthProvider.google),
          onApple: () => oauth(OAuthProvider.apple),
          onEmail: (email) => widget.client.auth.signInWithOtp(
            email: email,
            emailRedirectTo: redirect,
          ),
          onLocale: widget.onLocale,
        )
      : FinancialWorkspace(
          key: ValueKey(userId),
          userId: userId!,
          controller: LedgerController(SupabaseLedgerRepository(widget.client)),
          onLocale: widget.onLocale,
          onLogout: () => widget.client.auth.signOut(),
        );
}

class FinancialWorkspace extends StatefulWidget {
  const FinancialWorkspace({
    super.key,
    required this.userId,
    required this.controller,
    required this.onLocale,
    required this.onLogout,
  });
  final String userId;
  final LedgerController controller;
  final ValueChanged<Locale> onLocale;
  final Future<void> Function() onLogout;
  @override
  State<FinancialWorkspace> createState() => _FinancialWorkspaceState();
}

class _FinancialWorkspaceState extends State<FinancialWorkspace> {
  late final controller = widget.controller;
  int tab = 0;
  @override
  void initState() {
    super.initState();
    unawaited(
      controller.load().then((_) {
        if (mounted && controller.profile != null) {
          widget.onLocale(Locale(controller.profile!.language));
        }
      }),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> add() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionForm(controller: controller),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.strings.saved)));
    }
  }

  StatisticsCopy statisticsCopy(BuildContext context) {
    final s = context.strings;
    return StatisticsCopy(
      title: s.statistics,
      netPerformance: s.netPerformance,
      performanceEvolution: s.performanceBalanceEvolution,
      positiveDayRate: s.positiveDayRate,
      longestPositiveStreak: s.longestPositiveStreak,
      dayStates: s.dayStates,
      dailyResults: s.dailyResults,
      weeklyResults: s.weeklyResults,
      monthlyResults: s.monthlyResults,
      incomeByCategory: s.incomeByCategory,
      incomeBySource: s.incomeBySource,
      expensesByCategory: s.expensesByCategory,
      noData: s.noStatisticsData,
      chooseDates: s.chooseStatisticsDates,
    );
  }

  Future<void> showStatistics() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text(context.strings.statistics)),
        body: StatisticsScreen(
          controller: controller,
          copy: statisticsCopy(context),
          showTitle: false,
        ),
      ),
    ),
  );

  Future<void> logout() async {
    try {
      await widget.onLogout();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.strings.authError)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final s = context.strings;
      if (controller.loading && controller.profile == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (controller.failed && controller.profile == null) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.loadError),
                FilledButton(onPressed: controller.load, child: Text(s.retry)),
                TextButton(onPressed: logout, child: Text(s.logout)),
              ],
            ),
          ),
        );
      }
      if (controller.profile == null) {
        return Scaffold(
          appBar: AppBar(
            title: Text(s.appName),
            actions: [
              IconButton(
                tooltip: s.logout,
                onPressed: logout,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: ProfileForm(
            userId: widget.userId,
            onSave: controller.saveProfile,
            onLocale: widget.onLocale,
          ),
        );
      }
      final profile = controller.profile!;
      return Scaffold(
        appBar: AppBar(
          title: Text(
            s.appName,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: [
            if (controller.loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                tooltip: s.refresh,
                onPressed: controller.load,
                icon: const Icon(Icons.refresh),
              ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                if (controller.failed)
                  MaterialBanner(
                    content: Text(s.loadError),
                    actions: [
                      TextButton(
                        onPressed: controller.load,
                        child: Text(s.retry),
                      ),
                    ],
                  ),
                Expanded(
                  child: switch (tab) {
                    0 => DashboardScreen(
                      controller: controller,
                      onSettings: () => setState(() => tab = 3),
                      onStatistics: showStatistics,
                    ),
                    1 => CalendarScreen(controller: controller),
                    2 => TransactionsScreen(controller: controller),
                    3 => Column(
                      children: [
                        Expanded(
                          child: ProfileForm(
                            userId: widget.userId,
                            profile: profile,
                            currencyLocked: controller.transactions.isNotEmpty,
                            onSave: (p) async {
                              await controller.saveProfile(p);
                              if (mounted) {
                                widget.onLocale(Locale(p.language));
                                setState(() => tab = 0);
                              }
                            },
                            onLocale: widget.onLocale,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: logout,
                          icon: const Icon(Icons.logout),
                          label: Text(s.logout),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: tab == 3
            ? null
            : FloatingActionButton.extended(
                onPressed: add,
                icon: const Icon(Icons.add),
                label: Text(s.addTransaction),
              ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: s.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              label: s.calendar,
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              label: s.transactions,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              label: s.profile,
            ),
          ],
        ),
      );
    },
  );
}
