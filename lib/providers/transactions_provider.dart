import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/category_type.dart';
import '../models/transaction_type.dart';
import '../services/hive_service.dart';
import '../services/home_widget_service.dart';
import '../models/wallet.dart';
import 'package:uuid/uuid.dart';

class TransactionsProvider with ChangeNotifier {
  final HiveService _hiveService;
  
  TransactionsProvider(this._hiveService);

  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;

  List<Wallet> _wallets = [];
  List<Wallet> get wallets => _wallets;

  int _transactionLimit = 20;
  int get transactionLimit => _transactionLimit;

  double _totalBalance = 0;
  double _totalIncome = 0;
  double _totalExpenses = 0;

  double get totalBalance => _totalBalance;
  double get totalIncome => _totalIncome;
  double get totalExpenses => _totalExpenses;

  void loadMoreTransactions() {
    if (_transactionLimit < _transactions.length) {
      _transactionLimit += 20;
      notifyListeners();
    }
  }

  void resetTransactionLimit() {
    _transactionLimit = 20;
  }

  void _calculateTotals() {
    _totalIncome = _transactions.where((t) => t.type == TransactionType.income).fold(0.0, (sum, t) => sum + t.amount);
    _totalExpenses = _transactions.where((t) => t.type == TransactionType.expense && t.categoryId != CategoryType.savings.name).fold(0.0, (sum, t) => sum + t.amount);
    _totalBalance = 0;

    for (var wallet in _wallets) {
      double wIncome = _transactions.where((t) => t.walletId == wallet.id && t.type == TransactionType.income).fold(0.0, (sum, t) => sum + t.amount);
      // We do not filter 'savings' from wExpense because wallet balance MUST decrease when saving funds
      double wExpense = _transactions.where((t) => t.walletId == wallet.id && t.type == TransactionType.expense).fold(0.0, (sum, t) => sum + t.amount);
      wallet.balance = wIncome - wExpense;
      _totalBalance += wallet.balance;
    }

    HomeWidgetService.updateBalance(_totalBalance);
  }

  Future<void> loadTransactions() async {
    try {
      await loadCustomCategories();
      _wallets = await _hiveService.getWallets();
      if (_wallets.isEmpty) {
        final defaultWallet = Wallet(
          id: 'default',
          name: 'Principal',
          colorValue: Colors.blue.value,
          iconCodePoint: Icons.account_balance_wallet.codePoint,
        );
        await _hiveService.addWallet(defaultWallet);
        _wallets = [defaultWallet];
      }

      _transactions = await _hiveService.getTransactions();

      // --- INICIO MIGRACIÓN SILENCIOSA DE DATOS ---
      bool needsReload = false;
      for (var tx in _transactions) {
        String catId = tx.categoryId;
        String? newCatId;

        // Detectar si la transacción tiene un ID antiguo
        if (catId == 'other_expense') newCatId = 'otherExpense';
        if (catId == 'other_income') newCatId = 'otherIncome';
        if (catId == 'gift_expense') newCatId = 'giftExpense';
        if (catId == 'gift_income') newCatId = 'giftIncome';

        if (newCatId != null) {
          // Si tiene un ID antiguo, creamos una copia corregida y la guardamos en Hive
          final updatedTx = Transaction(
            id: tx.id,
            amount: tx.amount,
            typeString: tx.typeString,
            categoryId: newCatId,
            description: tx.description,
            date: tx.date,
            createdAt: tx.createdAt,
          );
          await _hiveService.updateTransaction(updatedTx);
          needsReload = true;
        }
      }

      // Si migramos al menos un dato, recargamos la lista limpia desde la base de datos
      if (needsReload) {
        _transactions = await _hiveService.getTransactions();
      }
      // --- FIN MIGRACIÓN ---



      _transactions.sort((a, b) => b.date.compareTo(a.date));
      _calculateTotals();
    } catch (e) {
      debugPrint("Error loading transactions: $e");
      _transactions = [];
      _totalBalance = 0;
      _totalIncome = 0;
      _totalExpenses = 0;
    }
    notifyListeners();
  }

  Future<void> addTransaction(Transaction transaction, {int installments = 1}) async {
    if (installments <= 1) {
      await _hiveService.addTransaction(transaction);
    } else {
      double installmentAmount = transaction.amount / installments;
      DateTime baseDate = transaction.date;
      String groupId = Uuid().v4(); // Unique ID for this group of installments

      for (int i = 0; i < installments; i++) {
        DateTime installmentDate = DateTime(baseDate.year, baseDate.month + i, baseDate.day);
        final tx = Transaction.create(
          amount: installmentAmount,
          type: transaction.type,
          categoryId: transaction.categoryId,
          description: "${transaction.description} (${i + 1}/$installments)",
          date: installmentDate,
          walletId: transaction.walletId,
          isRecurring: transaction.isRecurring,
          frequency: transaction.frequency,
          groupId: groupId,
        );
        await _hiveService.addTransaction(tx);
      }
    }
    await loadTransactions();
  }

  Future<void> deleteTransactionGroup(String groupId) async {
    final groupTransactions = _transactions.where((t) => t.groupId == groupId).toList();
    for (var tx in groupTransactions) {
      await _hiveService.deleteTransaction(tx.id);
    }
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

  List<Category> _customCategories = [];
  List<Category> get customCategories => _customCategories;

  List<Category> get allCategories => [...defaultCategories, ..._customCategories];

  Future<void> loadCustomCategories() async {
    try {
      _customCategories = await _hiveService.getCategories();
    } catch (e) {
      debugPrint("Error loading custom categories: $e");
      _customCategories = [];
    }
    notifyListeners();
  }

  Future<void> addCustomCategory(Category category) async {
    await _hiveService.addCategory(category);
    await loadCustomCategories();
  }

  Future<void> deleteCustomCategory(String categoryId) async {
    await _hiveService.deleteCategory(categoryId);
    await loadCustomCategories();
  }

  Category getCategory(String id) {
    // 1. Normalización para retrocompatibilidad con versiones/JSON antiguos
    String normalizedId = id;
    if (id == 'other_expense') normalizedId = 'otherExpense';
    if (id == 'other_income') normalizedId = 'otherIncome';
    if (id == 'gift_expense') normalizedId = 'giftExpense';
    if (id == 'gift_income') normalizedId = 'giftIncome';

    // 2. Búsqueda segura combinando categorías por defecto y personalizadas
    return allCategories.firstWhere(
      (c) => c.id == normalizedId,
      orElse: () => defaultCategories.last, // Opcional: Podrías crear una categoría genérica de error aquí
    );
  }

  Future<void> setInitialBalance(double amount) async {
    if (amount > 0) {
      final transaction = Transaction.create(
        amount: amount,
        type: TransactionType.income,
        categoryId: CategoryType.otherIncome.name,
        description: 'Saldo Inicial',
        date: DateTime.now(),
        walletId: 'default',
      );
      await addTransaction(transaction);
    }
  }

  Future<void> addNewWallet(String name, double initialBalance, int colorValue, int iconCodePoint) async {
    final wallet = Wallet.create(name: name, initialBalance: initialBalance, colorValue: colorValue, iconCodePoint: iconCodePoint);
    await _hiveService.addWallet(wallet);
    
    if (initialBalance > 0) {
      final tx = Transaction.create(
        amount: initialBalance,
        type: TransactionType.income,
        categoryId: CategoryType.otherIncome.name,
        description: 'Saldo Inicial - $name',
        date: DateTime.now(),
        walletId: wallet.id,
      );
      await _hiveService.addTransaction(tx);
    }
    await loadTransactions();
  }

  List<String> getInsights() {
    if (_transactions.isEmpty) return ["Comienza a registrar tus gastos para ver estadísticas."];
    
    final now = DateTime.now();
    final currentMonthExpenses = _transactions
        .where((t) => t.isExpense && t.categoryId != CategoryType.savings.name && t.date.year == now.year && t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
        
    final lastMonth = DateTime(now.year, now.month - 1);
    final lastMonthExpenses = _transactions
        .where((t) => t.isExpense && t.categoryId != CategoryType.savings.name && t.date.year == lastMonth.year && t.date.month == lastMonth.month)
        .fold(0.0, (sum, t) => sum + t.amount);

    if (lastMonthExpenses == 0) return ["¡Tu primer mes con Oink! Ve registrando tus gastos."];

    final diff = currentMonthExpenses - lastMonthExpenses;
    final percentage = (diff / lastMonthExpenses * 100).abs().toStringAsFixed(1);
    
    if (diff < 0) {
      return ["Gastaste $percentage% menos que el mes pasado. ¡Buen trabajo!"];
    } else if (diff > 0) {
      return ["Tus gastos superaron en un $percentage% al mes pasado."];
    } else {
      return ["Tus gastos son idénticos al mes pasado."];
    }
  }
}
