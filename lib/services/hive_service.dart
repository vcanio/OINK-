import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/savings_goal.dart';
import '../models/budget.dart';
import '../models/wallet.dart';
import '../models/category.dart';

class HiveService {
  static const String _transactionsBoxName = 'transactionsBox';
  static const String _savingsGoalsBoxName = 'savingsGoalsBox';
  static const String _budgetsBoxName = 'budgetsBox';
  static const String _walletsBoxName = 'walletsBox';
  static const String _categoriesBoxName = 'categoriesBox';

  // Categories
  Future<Box<Category>> get _categoriesBox async {
    if (Hive.isBoxOpen(_categoriesBoxName)) {
      return Hive.box<Category>(_categoriesBoxName);
    } else {
      return await Hive.openBox<Category>(_categoriesBoxName);
    }
  }

  Future<void> addCategory(Category category) async {
    final box = await _categoriesBox;
    await box.put(category.id, category);
  }

  Future<List<Category>> getCategories() async {
    final box = await _categoriesBox;
    return box.values.toList();
  }

  Future<void> deleteCategory(String id) async {
    final box = await _categoriesBox;
    await box.delete(id);
  }

  // Transactions
  Future<Box<Transaction>> get _transactionsBox async {
    if (Hive.isBoxOpen(_transactionsBoxName)) {
      return Hive.box<Transaction>(_transactionsBoxName);
    } else {
      return await Hive.openBox<Transaction>(_transactionsBoxName);
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    final box = await _transactionsBox;
    await box.put(transaction.id, transaction);
  }



  Future<List<Transaction>> getTransactions() async {
    final box = await _transactionsBox;
    return box.values.toList();
  }

  Future<void> deleteTransaction(String id) async {
    final box = await _transactionsBox;
    await box.delete(id);
  }
  
  Future<void> updateTransaction(Transaction transaction) async {
    final box = await _transactionsBox;
    await box.put(transaction.id, transaction);
  }

  // Savings Goals
  Future<Box<SavingsGoal>> get _savingsGoalsBox async {
    if (Hive.isBoxOpen(_savingsGoalsBoxName)) {
      return Hive.box<SavingsGoal>(_savingsGoalsBoxName);
    } else {
      return await Hive.openBox<SavingsGoal>(_savingsGoalsBoxName);
    }
  }

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    final box = await _savingsGoalsBox;
    await box.put(goal.id, goal);
  }

  Future<List<SavingsGoal>> getSavingsGoals() async {
    final box = await _savingsGoalsBox;
    return box.values.toList();
  }

  Future<void> deleteSavingsGoal(String id) async {
    final box = await _savingsGoalsBox;
    await box.delete(id);
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    final box = await _savingsGoalsBox;
    await box.put(goal.id, goal);
  }
  
  // Budgets
  Future<Box<Budget>> get _budgetsBox async {
    if (Hive.isBoxOpen(_budgetsBoxName)) {
      return Hive.box<Budget>(_budgetsBoxName);
    } else {
      return await Hive.openBox<Budget>(_budgetsBoxName);
    }
  }

  Future<void> addBudget(Budget budget) async {
    final box = await _budgetsBox;
    await box.put(budget.id, budget);
  }

  Future<List<Budget>> getBudgets() async {
    final box = await _budgetsBox;
    return box.values.toList();
  }

  Future<void> deleteBudget(String id) async {
    final box = await _budgetsBox;
    await box.delete(id);
  }

  Future<void> updateBudget(Budget budget) async {
    final box = await _budgetsBox;
    await box.put(budget.id, budget);
  }

  // Wallets
  Future<Box<Wallet>> get _walletsBox async {
    if (Hive.isBoxOpen(_walletsBoxName)) {
      return Hive.box<Wallet>(_walletsBoxName);
    } else {
      return await Hive.openBox<Wallet>(_walletsBoxName);
    }
  }

  Future<void> addWallet(Wallet wallet) async {
    final box = await _walletsBox;
    await box.put(wallet.id, wallet);
  }

  Future<List<Wallet>> getWallets() async {
    final box = await _walletsBox;
    return box.values.toList();
  }

  Future<void> deleteWallet(String id) async {
    final box = await _walletsBox;
    await box.delete(id);
  }

  Future<void> updateWallet(Wallet wallet) async {
    final box = await _walletsBox;
    await box.put(wallet.id, wallet);
  }

  // Settings
  static const String _settingsBoxName = 'settingsBox';

  Future<Box> get _settingsBox async {
    if (Hive.isBoxOpen(_settingsBoxName)) {
      return Hive.box(_settingsBoxName);
    } else {
      return await Hive.openBox(_settingsBoxName);
    }
  }

  Future<bool> get isFirstLaunch async {
    final box = await _settingsBox;
    return box.get('isFirstLaunch', defaultValue: true);
  }

  Future<void> setFirstLaunch(bool value) async {
    final box = await _settingsBox;
    await box.put('isFirstLaunch', value);
  }

  Future<String?> get lastSeenVersion async {
    final box = await _settingsBox;
    return box.get('lastSeenVersion');
  }

  Future<void> setLastSeenVersion(String version) async {
    final box = await _settingsBox;
    await box.put('lastSeenVersion', version);
  }

  // Notification Settings
  Future<bool> get dailyReminderEnabled async {
    final box = await _settingsBox;
    return box.get('dailyReminderEnabled', defaultValue: false);
  }

  Future<void> setDailyReminderEnabled(bool value) async {
    final box = await _settingsBox;
    await box.put('dailyReminderEnabled', value);
  }

  Future<String?> get dailyReminderTime async {
    final box = await _settingsBox;
    return box.get('dailyReminderTime');
  }

  Future<void> setDailyReminderTime(String value) async {
    final box = await _settingsBox;
    await box.put('dailyReminderTime', value);
  }

  // Wipe Data
  Future<void> wipeAllData() async {
    await Hive.deleteBoxFromDisk(_transactionsBoxName);
    await Hive.deleteBoxFromDisk(_savingsGoalsBoxName);
    await Hive.deleteBoxFromDisk(_budgetsBoxName);
    await Hive.deleteBoxFromDisk(_walletsBoxName);
    await Hive.deleteBoxFromDisk(_categoriesBoxName);
    await Hive.deleteBoxFromDisk(_settingsBoxName);
  }
}
