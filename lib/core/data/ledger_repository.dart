import '../domain/finance.dart';
import '../domain/notification_preferences.dart';

abstract interface class LedgerRepository {
  Future<Profile?> loadProfile();
  Future<void> saveProfile(Profile profile);
  Future<NotificationPreferences> loadNotificationPreferences();
  Future<NotificationPreferences> saveNotificationPreferences(
    NotificationPreferences preferences,
  );
  Future<List<Category>> loadCategories();
  Future<Category> saveCategory(Category category);
  Future<List<IncomeSource>> loadSources();
  Future<IncomeSource> saveSource(IncomeSource source);
  Future<List<LedgerTransaction>> loadTransactions();
  Future<LedgerTransaction> saveTransaction(LedgerTransaction transaction);
  Future<LedgerTransaction> deleteTransaction(LedgerTransaction transaction);
}
