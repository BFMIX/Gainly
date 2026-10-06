import 'package:flutter/foundation.dart' hide Category;

import '../core/data/ledger_repository.dart';
import '../core/domain/finance.dart';

class LedgerController extends ChangeNotifier {
  LedgerController(this.repository);
  final LedgerRepository repository;
  Profile? profile;
  List<Category> categories = [];
  List<IncomeSource> sources = [];
  List<LedgerTransaction> transactions = [];
  bool loading = true, failed = false;
  bool _disposed = false;
  int _revision = 0;
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
      if (_disposed || revision != _revision) return;
      profile = nextProfile;
      categories = nextCategories;
      sources = nextSources;
      transactions = nextTransactions;
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
    _emit();
  }

  Future<void> saveTransaction(LedgerTransaction value) async {
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
    _emit();
  }

  Future<void> deleteTransaction(LedgerTransaction value) async {
    await repository.deleteTransaction(value);
    _revision++;
    loading = false;
    failed = false;
    transactions = transactions.where((entry) => entry.id != value.id).toList();
    _emit();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
