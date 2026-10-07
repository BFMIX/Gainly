import 'package:flutter/foundation.dart' hide Category;
import 'package:uuid/uuid.dart';

import '../core/data/ledger_repository.dart';
import '../core/data/cached_ledger_repository.dart';
import '../core/domain/finance.dart';
import '../core/domain/notification_preferences.dart';
import '../features/notifications/notification_coordinator.dart';

class LedgerController extends ChangeNotifier {
  LedgerController(this.repository, {this.notifications});
  final LedgerRepository repository;
  final NotificationCoordinator? notifications;
  Profile? profile;
  NotificationPreferences notificationPreferences =
      const NotificationPreferences();
  List<Category> categories = [];
  List<IncomeSource> sources = [];
  List<LedgerTransaction> transactions = [];
  bool loading = true, failed = false;
  bool _disposed = false;
  int _revision = 0;
  bool get isOffline => switch (repository) {
    CachedLedgerRepository cached => cached.isOffline,
    _ => false,
  };
  int get pendingChanges => switch (repository) {
    CachedLedgerRepository cached => cached.pendingChanges,
    _ => 0,
  };
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    final revision = ++_revision;
    loading = true;
    failed = false;
    _emit();
    try {
      final nextProfile = await repository.loadProfile();
      final nextCategories = nextProfile == null
          ? <Category>[]
          : await repository.loadCategories();
      final nextSources = nextProfile == null
          ? <IncomeSource>[]
          : await repository.loadSources();
      final nextTransactions = nextProfile == null
          ? <LedgerTransaction>[]
          : await repository.loadTransactions();
      final nextNotificationPreferences = nextProfile == null
          ? const NotificationPreferences()
          : await repository.loadNotificationPreferences();
      if (_disposed || revision != _revision) return;
      profile = nextProfile;
      categories = nextCategories;
      sources = nextSources;
      transactions = nextTransactions;
      notificationPreferences = nextNotificationPreferences;
      if (nextProfile != null) {
        try {
          await notifications?.applyPreferences(
            profile: nextProfile,
            preferences: nextNotificationPreferences,
            transactions: nextTransactions,
          );
        } catch (_) {
          // Notification delivery must never block access to financial data.
        }
      }
    } catch (_) {
      if (revision == _revision) failed = true;
    } finally {
      if (revision == _revision) {
        loading = false;
        _emit();
      }
    }
  }

  Future<void> saveProfile(Profile value) async {
    await repository.saveProfile(value);
    final nextCategories = await repository.loadCategories();
    _revision++;
    loading = false;
    failed = false;
    profile = value;
    categories = nextCategories;
    try {
      await notifications?.applyPreferences(
        profile: value,
        preferences: notificationPreferences,
        transactions: transactions,
      );
    } catch (_) {
      // Profile persistence succeeds even when notification setup is denied.
    }
    _emit();
  }

  Future<void> saveTransaction(LedgerTransaction value) async {
    final previousTransactions = List<LedgerTransaction>.of(transactions);
    final saved = await repository.saveTransaction(value);
    _revision++;
    loading = false;
    failed = false;
    transactions = [saved, ...transactions.where((t) => t.id != saved.id)]
      ..sort((a, b) {
        final day = b.date.compareTo(a.date);
        return day != 0
            ? day
            : (b.createdAt ?? b.date).compareTo(a.createdAt ?? a.date);
      });
    final currentProfile = profile;
    if (currentProfile != null) {
      try {
        await notifications?.afterFinancialChange(
          profile: currentProfile,
          preferences: notificationPreferences,
          previousTransactions: previousTransactions,
          currentTransactions: transactions,
        );
      } catch (_) {
        // The transaction is already durable; notification failure is nonfatal.
      }
    }
    _emit();
  }

  Future<void> saveNotificationPreferences(
    NotificationPreferences value,
  ) async {
    notificationPreferences = await repository.saveNotificationPreferences(
      value,
    );
    final currentProfile = profile;
    if (currentProfile != null) {
      try {
        await notifications?.applyPreferences(
          profile: currentProfile,
          preferences: notificationPreferences,
          transactions: transactions,
        );
      } catch (_) {
        // Preferences remain saved even when the OS rejects notification work.
      }
    }
    _revision++;
    failed = false;
    _emit();
  }

  Future<void> saveCategory(Category value) async {
    final saved = await repository.saveCategory(value);
    _revision++;
    failed = false;
    categories =
        [saved, ...categories.where((category) => category.id != saved.id)]
          ..sort((a, b) {
            final type = a.type.index.compareTo(b.type.index);
            return type != 0
                ? type
                : a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
    _emit();
  }

  Future<IncomeSource> saveSourceName(
    String name, {
    IncomeSource? source,
  }) async {
    final trimmedName = name.trim();
    final saved = await repository.saveSource(
      IncomeSource(source?.id ?? const Uuid().v4(), trimmedName),
    );
    _revision++;
    failed = false;
    sources = [saved, ...sources.where((value) => value.id != saved.id)]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _emit();
    return saved;
  }

  Future<void> deleteTransaction(LedgerTransaction value) async {
    final previousTransactions = List<LedgerTransaction>.of(transactions);
    await repository.deleteTransaction(value);
    _revision++;
    loading = false;
    failed = false;
    transactions = transactions.where((entry) => entry.id != value.id).toList();
    final currentProfile = profile;
    if (currentProfile != null) {
      try {
        await notifications?.afterFinancialChange(
          profile: currentProfile,
          preferences: notificationPreferences,
          previousTransactions: previousTransactions,
          currentTransactions: transactions,
        );
      } catch (_) {
        // The deletion is already durable; notification failure is nonfatal.
      }
    }
    _emit();
  }

  Future<void> endSession() async {
    try {
      await notifications?.endSession();
    } catch (_) {
      // Signing out must proceed even if the OS notification service fails.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
