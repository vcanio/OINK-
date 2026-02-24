import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../services/hive_service.dart';

class BudgetsProvider with ChangeNotifier {
  final HiveService _hiveService;

  BudgetsProvider(this._hiveService);

  List<Budget> _budgets = [];
  List<Budget> get budgets => _budgets;

  Future<void> loadBudgets() async {
    try {
      _budgets = await _hiveService.getBudgets();
    } catch (e) {
      debugPrint("Error loading budgets: $e");
      _budgets = [];
    }
    notifyListeners();
  }

  Future<void> addBudget(Budget budget) async {
    await _hiveService.addBudget(budget);
    await loadBudgets();
  }

  Future<void> updateBudget(Budget budget) async {
    await _hiveService.updateBudget(budget);
    await loadBudgets();
  }

  Future<void> deleteBudget(String id) async {
    await _hiveService.deleteBudget(id);
    await loadBudgets();
  }

  Budget? getBudgetForCategory(String categoryId) {
    try {
      return _budgets.firstWhere((b) => b.categoryId == categoryId);
    } catch (StateError) {
      return null;
    }
  }
}
