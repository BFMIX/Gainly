enum TransactionType { income, expense }

enum DayState { positive, zeroAfterActivity, noActivity, negative }

enum PaymentMethod { cash, bankCard, bankTransfer, other }

const maxMinorAmount = 9000000000000;

/// Parses two-decimal currencies without using floating-point arithmetic.
int parseMoney(String input, {bool allowNegative = false}) {
  final normalized = input.trim().replaceAll(',', '.');
  if (!RegExp(allowNegative ? r'^-?\d+(\.\d{1,2})?$' : r'^\d+(\.\d{1,2})?$')
      .hasMatch(normalized)) {
    throw const FormatException('Invalid monetary amount');
  }
  final negative = normalized.startsWith('-');
  final parts = normalized.replaceFirst('-', '').split('.');
  final whole = int.tryParse(parts[0]);
  if (whole == null || whole > maxMinorAmount ~/ 100) {
    throw const FormatException('Amount exceeds supported range');
  }
  final result =
      whole * 100 +
      int.parse(parts.length == 1 ? '0' : parts[1].padRight(2, '0'));
  if (result > maxMinorAmount) {
    throw const FormatException('Amount exceeds supported range');
  }
  return negative ? -result : result;
}

String moneyInput(int? value) => value == null
    ? ''
    : '${value < 0 ? '-' : ''}${value.abs() ~/ 100}.${(value.abs() % 100).toString().padLeft(2, '0')}';
String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class Profile {
  const Profile({
    required this.userId,
    required this.firstName,
    required this.language,
    required this.currency,
    this.startingBalance,
    this.startingPerformanceBalance,
    this.monthlyTarget,
    this.dailyMinimum,
  });
  final String userId, firstName, language, currency;
  final int? startingBalance,
      startingPerformanceBalance,
      monthlyTarget,
      dailyMinimum;
  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    userId: json['user_id'] as String,
    firstName: json['first_name'] as String,
    language: json['language'] as String,
    currency: json['currency'] as String,
    startingBalance: json['starting_balance_minor'] as int?,
    startingPerformanceBalance:
        json['starting_performance_balance_minor'] as int?,
    monthlyTarget: json['monthly_target_minor'] as int?,
    dailyMinimum: json['daily_minimum_minor'] as int?,
  );
  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'first_name': firstName,
    'language': language,
    'currency': currency,
    'starting_balance_minor': startingBalance,
    'starting_performance_balance_minor': startingPerformanceBalance,
    'monthly_target_minor': monthlyTarget,
    'daily_minimum_minor': dailyMinimum,
  };
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.countsTowardPerformance,
    this.translationKey,
  });
  final String id, name;
  final String? translationKey;
  final TransactionType type;
  final bool countsTowardPerformance;
  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    type: TransactionType.values.byName(json['type'] as String),
    countsTowardPerformance: json['counts_toward_performance'] as bool,
    translationKey: json['translation_key'] as String?,
  );
}

class IncomeSource {
  const IncomeSource(this.id, this.name);
  final String id, name;
}

class LedgerTransaction {
  const LedgerTransaction({
    required this.id,
    required this.userId,
    required this.amountMinor,
    required this.type,
    required this.date,
    required this.categoryId,
    required this.countsTowardPerformance,
    this.sourceId,
    this.paymentMethod = PaymentMethod.other,
    this.note,
    this.entryMode = 'detailed',
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });
  final String id, userId, categoryId, entryMode;
  final String? sourceId, note;
  final int amountMinor;
  final TransactionType type;
  final DateTime date;
  final PaymentMethod paymentMethod;
  final bool countsTowardPerformance;
  final DateTime? deletedAt, createdAt, updatedAt;
  int get signedAmount =>
      type == TransactionType.income ? amountMinor : -amountMinor;
  factory LedgerTransaction.fromJson(Map<String, dynamic> json) =>
      LedgerTransaction(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        amountMinor: json['amount_minor'] as int,
        type: TransactionType.values.byName(json['type'] as String),
        date: DateTime.parse(json['date'] as String),
        categoryId: json['category_id'] as String,
        sourceId: json['source_id'] as String?,
        paymentMethod: PaymentMethod.values.byName(
          json['payment_method'] as String,
        ),
        note: json['note'] as String?,
        entryMode: json['entry_mode'] as String,
        countsTowardPerformance: json['counts_toward_performance'] as bool,
        createdAt: json['created_at'] == null
            ? null
            : DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] == null
            ? null
            : DateTime.parse(json['updated_at'] as String),
        deletedAt: json['deleted_at'] == null
            ? null
            : DateTime.parse(json['deleted_at'] as String),
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'amount_minor': amountMinor,
    'type': type.name,
    'date': dateKey(date),
    'category_id': categoryId,
    'source_id': sourceId,
    'payment_method': paymentMethod.name,
    'note': note,
    'entry_mode': entryMode,
    'counts_toward_performance': countsTowardPerformance,
  };
}

class FinancialSummary {
  FinancialSummary(this.profile, Iterable<LedgerTransaction> entries)
    : transactions = entries.where((t) => t.deletedAt == null).toList();
  final Profile profile;
  final List<LedgerTransaction> transactions;
  int? get balance => profile.startingBalance == null
      ? null
      : profile.startingBalance! +
            transactions.fold<int>(0, (sum, t) => sum + t.signedAmount);
  int? get performanceBalance => profile.startingPerformanceBalance == null
      ? null
      : profile.startingPerformanceBalance! +
            transactions
                .where((t) => t.countsTowardPerformance)
                .fold<int>(0, (sum, t) => sum + t.signedAmount);
  List<LedgerTransaction> onDay(DateTime date) =>
      transactions.where((t) => dateKey(t.date) == dateKey(date)).toList();
  int incomeOn(DateTime date) =>
      onDay(date)
          .where((t) => t.type == TransactionType.income)
          .fold(0, (s, t) => s + t.amountMinor);
  int expensesOn(DateTime date) =>
      onDay(date)
          .where((t) => t.type == TransactionType.expense)
          .fold(0, (s, t) => s + t.amountMinor);
  int resultOn(DateTime date) =>
      onDay(date)
          .where((t) => t.countsTowardPerformance)
          .fold(0, (s, t) => s + t.signedAmount);
  DayState stateOn(DateTime date) {
    if (!onDay(date).any((t) => t.countsTowardPerformance)) {
      return DayState.noActivity;
    }
    final result = resultOn(date);
    return result > 0
        ? DayState.positive
        : result < 0
        ? DayState.negative
        : DayState.zeroAfterActivity;
  }
}
