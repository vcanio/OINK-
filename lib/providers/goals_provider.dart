import 'package:flutter/material.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../models/category_type.dart';
import '../models/transaction_type.dart';
import '../services/hive_service.dart';
import 'transactions_provider.dart';

class GoalsProvider with ChangeNotifier {
  final HiveService _hiveService;
  final TransactionsProvider _transactionsProvider;

  GoalsProvider(this._hiveService, this._transactionsProvider);

  List<SavingsGoal> _savingsGoals = [];
  List<SavingsGoal> get savingsGoals => _savingsGoals;

  Future<void> loadSavingsGoals() async {
    try {
      _savingsGoals = await _hiveService.getSavingsGoals();
    } catch (e) {
       debugPrint("Error loading savings goals: $e");
       _savingsGoals = [];
    }
    notifyListeners();
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

  Future<void> addFundsToGoal(SavingsGoal goal, double amount) async {
    final updatedGoal = goal.copyWith(
      savedAmount: goal.savedAmount + amount,
    );
    await updateSavingsGoal(updatedGoal);

    final transaction = Transaction.create(
      amount: amount,
      type: TransactionType.expense,
      categoryId: CategoryType.savings.name, 
      description: 'Abono a meta: ${goal.name}',
      date: DateTime.now(),
    );
    await _transactionsProvider.addTransaction(transaction);
  }
}
