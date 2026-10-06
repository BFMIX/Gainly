import '../domain/finance.dart';

abstract interface class LedgerRepository {
  Future<Profile?> loadProfile();
  Future<void> saveProfile(Profile profile);
  Future<List<Category>> loadCategories();
  Future<List<IncomeSource>> loadSources();
  Future<String> saveSource(String name);
  Future<List<LedgerTransaction>> loadTransactions();
  Future<LedgerTransaction> saveTransaction(LedgerTransaction transaction);
  Future<LedgerTransaction> deleteTransaction(LedgerTransaction transaction);
}
