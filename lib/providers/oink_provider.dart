import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/savings_goal.dart';
import '../models/category.dart';
import '../services/hive_service.dart';

class OinkProvider with ChangeNotifier {
  final HiveService _hiveService = HiveService();
  List<Transaction> _transactions = [];
  List<SavingsGoal> _savingsGoals = [];

  List<Transaction> get transactions => _transactions;
  List<SavingsGoal> get savingsGoals => _savingsGoals;

  // Calculardos
  double get totalBalance {
    return _transactions.fold(0, (sum, item) {
      if (item.type == 'expense') {
        return sum - item.amount;
      } else {
        return sum + item.amount;
      }
    });
  }
  
  double get totalIncome {
    return _transactions.where((t) => t.type == 'income').fold(0, (sum, t) => sum + t.amount);
  }

  double get totalExpenses {
    return _transactions.where((t) => t.type == 'expense').fold(0, (sum, t) => sum + t.amount);
  }

  Future<void> loadData() async {
    await loadTransactions();
    await loadSavingsGoals();
  }

  Future<void> loadTransactions() async {
    try {
      _transactions = await _hiveService.getTransactions();
      // Sort by date, newest first
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint("Error loading transactions: $e");
      _transactions = [];
    }
    notifyListeners();
  }
  
  Future<void> loadSavingsGoals() async {
    try {
      _savingsGoals = await _hiveService.getSavingsGoals();
    } catch (e) {
       debugPrint("Error loading savings goals: $e");
       _savingsGoals = [];
    }
     notifyListeners();
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _hiveService.addTransaction(transaction);
    await loadTransactions();
  }


  
  Future<void> updateTransaction(Transaction transaction) async {
    await _hiveService.updateTransaction(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await _hiveService.deleteTransaction(id);
    await loadTransactions();
  }
  
  Future<void> addSavingsGoal(SavingsGoal goal) async {
    await _hiveService.addSavingsGoal(goal);
    await loadSavingsGoals();
  }
  
  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    await _hiveService.updateSavingsGoal(goal);
    await loadSavingsGoals();
  }
  
  Future<void> deleteSavingsGoal(String id) async {
    await _hiveService.deleteSavingsGoal(id);
    await loadSavingsGoals();
  }
  
  Future<void> wipeData() async {
    await _hiveService.wipeAllData();
    await loadData();
  }

  Category getCategory(String id) {
    return defaultCategories.firstWhere(
      (c) => c.id == id,
      orElse: () => defaultCategories.last, // 'Otros' as fallback
    );
  }
}
