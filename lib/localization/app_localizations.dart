import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Gainly'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Make every day count.'**
  String get tagline;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Your money. Your momentum.'**
  String get welcome;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'See what you earn, what you spend, and how you move forward.'**
  String get welcomeBody;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get google;

  /// No description provided for @apple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get apple;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get email;

  /// No description provided for @emailContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get emailContinue;

  /// No description provided for @linkSent.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox for your sign-in link.'**
  String get linkSent;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Check your connection and try again.'**
  String get authError;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Gainly is not connected yet'**
  String get setupTitle;

  /// No description provided for @setupBody.
  ///
  /// In en, this message translates to:
  /// **'Your financial workspace will be available once setup is complete.'**
  String get setupBody;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'A fresh start'**
  String get onboardingTitle;

  /// No description provided for @onboardingBody.
  ///
  /// In en, this message translates to:
  /// **'A few details, then you are ready. Starting balances are optional.'**
  String get onboardingBody;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @startingBalance.
  ///
  /// In en, this message translates to:
  /// **'Starting Balance'**
  String get startingBalance;

  /// No description provided for @startingPerformanceBalance.
  ///
  /// In en, this message translates to:
  /// **'Starting Performance Balance'**
  String get startingPerformanceBalance;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start tracking'**
  String get start;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get required;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount with up to two decimals'**
  String get invalidAmount;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Your entry is still here. Check your connection and retry.'**
  String get saveError;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh your data. Check your connection and retry.'**
  String get loadError;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @performanceBalance.
  ///
  /// In en, this message translates to:
  /// **'Performance Balance'**
  String get performanceBalance;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @setBalance.
  ///
  /// In en, this message translates to:
  /// **'Set your starting balance'**
  String get setBalance;

  /// No description provided for @setPerformanceBalance.
  ///
  /// In en, this message translates to:
  /// **'Set your starting performance balance'**
  String get setPerformanceBalance;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @performanceResult.
  ///
  /// In en, this message translates to:
  /// **'Performance result'**
  String get performanceResult;

  /// No description provided for @positive.
  ///
  /// In en, this message translates to:
  /// **'Positive day'**
  String get positive;

  /// No description provided for @zeroAfterActivity.
  ///
  /// In en, this message translates to:
  /// **'Balanced after activity'**
  String get zeroAfterActivity;

  /// No description provided for @noActivity.
  ///
  /// In en, this message translates to:
  /// **'No performance activity'**
  String get noActivity;

  /// No description provided for @negative.
  ///
  /// In en, this message translates to:
  /// **'Negative day'**
  String get negative;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Latest transactions'**
  String get recentTransactions;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your first step starts here'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Record an income or expense to see your day take shape.'**
  String get emptyBody;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get addTransaction;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source or merchant'**
  String get source;

  /// No description provided for @unspecified.
  ///
  /// In en, this message translates to:
  /// **'Unspecified source'**
  String get unspecified;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @bankCard.
  ///
  /// In en, this message translates to:
  /// **'Bank Card'**
  String get bankCard;

  /// No description provided for @bankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get bankTransfer;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @included.
  ///
  /// In en, this message translates to:
  /// **'Included in Performance'**
  String get included;

  /// No description provided for @excluded.
  ///
  /// In en, this message translates to:
  /// **'Excluded from Performance'**
  String get excluded;

  /// No description provided for @detailed.
  ///
  /// In en, this message translates to:
  /// **'Detailed'**
  String get detailed;

  /// No description provided for @quick.
  ///
  /// In en, this message translates to:
  /// **'Quick'**
  String get quick;

  /// No description provided for @quickHelp.
  ///
  /// In en, this message translates to:
  /// **'Adds a new amount to your day. Do not include transactions already recorded.'**
  String get quickHelp;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved'**
  String get saved;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Your settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @currencyLocked.
  ///
  /// In en, this message translates to:
  /// **'Currency cannot change after the first transaction.'**
  String get currencyLocked;

  /// No description provided for @nextIteration.
  ///
  /// In en, this message translates to:
  /// **'This view will be added after the first financial flow is validated.'**
  String get nextIteration;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @rideshare.
  ///
  /// In en, this message translates to:
  /// **'Rideshare'**
  String get rideshare;

  /// No description provided for @freelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get freelance;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salary;

  /// No description provided for @benefits.
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get benefits;

  /// No description provided for @refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refund;

  /// No description provided for @gift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get gift;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// No description provided for @fuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get fuel;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @housing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get housing;

  /// No description provided for @bills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get bills;

  /// No description provided for @shopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get shopping;

  /// No description provided for @leisure.
  ///
  /// In en, this message translates to:
  /// **'Leisure'**
  String get leisure;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @workExpenses.
  ///
  /// In en, this message translates to:
  /// **'Work expenses'**
  String get workExpenses;

  /// No description provided for @dayDetails.
  ///
  /// In en, this message translates to:
  /// **'Day details'**
  String get dayDetails;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @searchTransactions.
  ///
  /// In en, this message translates to:
  /// **'Search transactions'**
  String get searchTransactions;

  /// No description provided for @allTransactions.
  ///
  /// In en, this message translates to:
  /// **'All transactions'**
  String get allTransactions;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @allSources.
  ///
  /// In en, this message translates to:
  /// **'All sources'**
  String get allSources;

  /// No description provided for @allPerformance.
  ///
  /// In en, this message translates to:
  /// **'Included and excluded'**
  String get allPerformance;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @sevenDays.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get sevenDays;

  /// No description provided for @thirtyDays.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get thirtyDays;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get thisYear;

  /// No description provided for @customPeriod.
  ///
  /// In en, this message translates to:
  /// **'Custom period'**
  String get customPeriod;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions match these filters.'**
  String get noTransactions;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteTransactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction?'**
  String get deleteTransactionTitle;

  /// No description provided for @deleteTransactionBody.
  ///
  /// In en, this message translates to:
  /// **'This transaction will no longer affect your balances. This action can be synchronized across your devices.'**
  String get deleteTransactionBody;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get deleted;

  /// No description provided for @deleteError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete the transaction. Check your connection and retry.'**
  String get deleteError;

  /// No description provided for @editTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get editTransaction;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @monthlyTarget.
  ///
  /// In en, this message translates to:
  /// **'Monthly target'**
  String get monthlyTarget;

  /// No description provided for @monthlyTargetHelp.
  ///
  /// In en, this message translates to:
  /// **'Gross included Performance income you want to earn each month.'**
  String get monthlyTargetHelp;

  /// No description provided for @dailyMinimum.
  ///
  /// In en, this message translates to:
  /// **'Daily minimum'**
  String get dailyMinimum;

  /// No description provided for @dailyMinimumHelp.
  ///
  /// In en, this message translates to:
  /// **'Suggested from the monthly target, then kept under your control.'**
  String get dailyMinimumHelp;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @netPerformance.
  ///
  /// In en, this message translates to:
  /// **'Net Performance'**
  String get netPerformance;

  /// No description provided for @performanceBalanceEvolution.
  ///
  /// In en, this message translates to:
  /// **'Performance Balance evolution'**
  String get performanceBalanceEvolution;

  /// No description provided for @positiveDayRate.
  ///
  /// In en, this message translates to:
  /// **'Positive Day Rate'**
  String get positiveDayRate;

  /// No description provided for @longestPositiveStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest positive streak'**
  String get longestPositiveStreak;

  /// No description provided for @dayStates.
  ///
  /// In en, this message translates to:
  /// **'Day states'**
  String get dayStates;

  /// No description provided for @dailyResults.
  ///
  /// In en, this message translates to:
  /// **'Daily results'**
  String get dailyResults;

  /// No description provided for @weeklyResults.
  ///
  /// In en, this message translates to:
  /// **'Weekly results'**
  String get weeklyResults;

  /// No description provided for @monthlyResults.
  ///
  /// In en, this message translates to:
  /// **'Monthly results'**
  String get monthlyResults;

  /// No description provided for @incomeByCategory.
  ///
  /// In en, this message translates to:
  /// **'Income by category'**
  String get incomeByCategory;

  /// No description provided for @incomeBySource.
  ///
  /// In en, this message translates to:
  /// **'Income by source'**
  String get incomeBySource;

  /// No description provided for @expensesByCategory.
  ///
  /// In en, this message translates to:
  /// **'Expenses by category'**
  String get expensesByCategory;

  /// No description provided for @noStatisticsData.
  ///
  /// In en, this message translates to:
  /// **'No data for this period.'**
  String get noStatisticsData;

  /// No description provided for @chooseStatisticsDates.
  ///
  /// In en, this message translates to:
  /// **'Choose a statistics period'**
  String get chooseStatisticsDates;

  /// No description provided for @goalProgress.
  ///
  /// In en, this message translates to:
  /// **'Goal progress'**
  String get goalProgress;

  /// No description provided for @requiredDailyPace.
  ///
  /// In en, this message translates to:
  /// **'Required daily pace'**
  String get requiredDailyPace;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'Days remaining'**
  String get daysRemaining;

  /// No description provided for @trackingStreak.
  ///
  /// In en, this message translates to:
  /// **'Tracking streak'**
  String get trackingStreak;

  /// No description provided for @positiveStreak.
  ///
  /// In en, this message translates to:
  /// **'Positive streak'**
  String get positiveStreak;

  /// No description provided for @smartInsights.
  ///
  /// In en, this message translates to:
  /// **'Smart Insights'**
  String get smartInsights;

  /// No description provided for @performanceBalanceRiskInsight.
  ///
  /// In en, this message translates to:
  /// **'Your Performance Balance is at risk.'**
  String get performanceBalanceRiskInsight;

  /// No description provided for @consecutiveNegativeDaysInsight.
  ///
  /// In en, this message translates to:
  /// **'Several consecutive active days were negative.'**
  String get consecutiveNegativeDaysInsight;

  /// No description provided for @spendingAboveAverageInsight.
  ///
  /// In en, this message translates to:
  /// **'Today\'s spending is much higher than your recent average.'**
  String get spendingAboveAverageInsight;

  /// No description provided for @behindMonthlyTargetInsight.
  ///
  /// In en, this message translates to:
  /// **'You are behind this month\'s target pace.'**
  String get behindMonthlyTargetInsight;

  /// No description provided for @aheadMonthlyTargetInsight.
  ///
  /// In en, this message translates to:
  /// **'You are ahead of this month\'s target pace.'**
  String get aheadMonthlyTargetInsight;

  /// No description provided for @requiredDailyPaceInsight.
  ///
  /// In en, this message translates to:
  /// **'This daily pace will keep your monthly target within reach.'**
  String get requiredDailyPaceInsight;

  /// No description provided for @viewStatistics.
  ///
  /// In en, this message translates to:
  /// **'View statistics'**
  String get viewStatistics;

  /// No description provided for @catalogManagement.
  ///
  /// In en, this message translates to:
  /// **'Categories and sources'**
  String get catalogManagement;

  /// No description provided for @manageCatalog.
  ///
  /// In en, this message translates to:
  /// **'Manage categories and sources'**
  String get manageCatalog;

  /// No description provided for @incomeCategories.
  ///
  /// In en, this message translates to:
  /// **'Income categories'**
  String get incomeCategories;

  /// No description provided for @expenseCategories.
  ///
  /// In en, this message translates to:
  /// **'Expense categories'**
  String get expenseCategories;

  /// No description provided for @sources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sources;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @categoryType.
  ///
  /// In en, this message translates to:
  /// **'Category type'**
  String get categoryType;

  /// No description provided for @defaultPerformance.
  ///
  /// In en, this message translates to:
  /// **'Include in Performance by default'**
  String get defaultPerformance;

  /// No description provided for @addSource.
  ///
  /// In en, this message translates to:
  /// **'Add source'**
  String get addSource;

  /// No description provided for @newSource.
  ///
  /// In en, this message translates to:
  /// **'New source'**
  String get newSource;

  /// No description provided for @editSource.
  ///
  /// In en, this message translates to:
  /// **'Edit source'**
  String get editSource;

  /// No description provided for @sourceName.
  ///
  /// In en, this message translates to:
  /// **'Source name'**
  String get sourceName;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @achievementFirstEntry.
  ///
  /// In en, this message translates to:
  /// **'First entry'**
  String get achievementFirstEntry;

  /// No description provided for @achievementThreePositiveDays.
  ///
  /// In en, this message translates to:
  /// **'3 positive days'**
  String get achievementThreePositiveDays;

  /// No description provided for @achievementSevenDayTrackingStreak.
  ///
  /// In en, this message translates to:
  /// **'7-day tracking streak'**
  String get achievementSevenDayTrackingStreak;

  /// No description provided for @achievementMonthlyTargetReached.
  ///
  /// In en, this message translates to:
  /// **'Monthly target reached'**
  String get achievementMonthlyTargetReached;

  /// No description provided for @offlineChangesPending.
  ///
  /// In en, this message translates to:
  /// **'Offline — your changes are saved on this device and will sync automatically.'**
  String get offlineChangesPending;

  /// No description provided for @offlineCachedData.
  ///
  /// In en, this message translates to:
  /// **'Offline — showing data saved on this device.'**
  String get offlineCachedData;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
