import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/savings_goal.dart';

class HiveService {
  static const String _transactionsBoxName = 'transactionsBox';
  static const String _savingsGoalsBoxName = 'savingsGoalsBox';

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
  
  // Wipe Data
  Future<void> wipeAllData() async {
    await Hive.deleteBoxFromDisk(_transactionsBoxName);
    await Hive.deleteBoxFromDisk(_savingsGoalsBoxName);
  }
}
