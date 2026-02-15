import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../widgets/expenses_chart.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initial load of data
    Future.microtask(() =>
        Provider.of<TransactionProvider>(context, listen: false).loadTransactions());

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('OINK!', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFB6C1), // Pink
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: const Icon(Icons.savings), // Piggy bank icon approximation
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: CustomScrollView(
          slivers: [
             SliverToBoxAdapter(child: SaldoCard()),
             SliverToBoxAdapter(child: SizedBox(height: 20)),
             SliverToBoxAdapter(child: ExpensesChartWrapper()), // Wrapper needed to access context of provider inside build or just move logic
             SliverToBoxAdapter(child: SizedBox(height: 20)),
             SliverToBoxAdapter(child: TransactionForm()),
             SliverToBoxAdapter(child: SizedBox(height: 20)),
             TransactionSliverList(),
          ],
        ),
      ),
    );
  }
}

class ExpensesChartWrapper extends StatelessWidget {
  const ExpensesChartWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<TransactionProvider>().transactions;
    return ExpensesChart(transactions: transactions);
  }
}

class SaldoCard extends StatelessWidget {
  const SaldoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final balance = context.select<TransactionProvider, double>((p) => p.totalBalance);
    // Remove decimals for CLP
    final currencyFormat = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFFFD700), // Gold
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Saldo Total',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(balance),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionForm extends StatefulWidget {
  const TransactionForm({super.key});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategoryId = 'others';
  bool _isExpense = true;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final description = _descriptionController.text;
    // Strip dots before parsing
    final amountText = _amountController.text.replaceAll('.', '');

    if (description.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monto inválido')),
      );
      return;
    }

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      isExpense: _isExpense,
      description: description,
      date: DateTime.now(),
      categoryId: _selectedCategoryId,
    );

    Provider.of<TransactionProvider>(context, listen: false).addTransaction(transaction);

    _descriptionController.clear();
    _amountController.clear();
    FocusScope.of(context).unfocus(); // Close keyboard
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Monto'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      // Thousand separator formatter (dots)
                      ThousandsSeparatorInputFormatter(),
                    ],
                  ),
                ),
              ],
            ),
            if (_isExpense)
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: defaultCategories.map((category) {
                  return DropdownMenuItem(
                    value: category.id,
                    child: Row(
                      children: [
                        Icon(category.icon, color: category.color),
                        const SizedBox(width: 10),
                        Text(category.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    if (value != null) _selectedCategoryId = value;
                  });
                },
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('Tipo: '),
                    Switch(
                      value: _isExpense,
                      onChanged: (value) {
                        setState(() {
                          _isExpense = value;
                        });
                      },
                      activeColor: Colors.redAccent,
                      inactiveThumbColor: Colors.green,
                      inactiveTrackColor: Colors.green.withOpacity(0.5),
                    ),
                    Text(
                      _isExpense ? 'Gasto' : 'Ingreso',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isExpense ? Colors.redAccent : Colors.green,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Agregar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionSliverList extends StatelessWidget {
  const TransactionSliverList({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<TransactionProvider>().transactions;
    // Remove decimals for CLP
    final currencyFormat = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

    if (transactions.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('No hay transacciones aún.'),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final tx = transactions[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: tx.isExpense 
                  ? (defaultCategories.firstWhere((c) => c.id == tx.categoryId, orElse: () => defaultCategories.last).color.withOpacity(0.2)) 
                  : Colors.green[100],
                child: Icon(
                  tx.isExpense 
                    ? (defaultCategories.firstWhere((c) => c.id == tx.categoryId, orElse: () => defaultCategories.last).icon) 
                    : Icons.attach_money,
                  color: tx.isExpense 
                    ? (defaultCategories.firstWhere((c) => c.id == tx.categoryId, orElse: () => defaultCategories.last).color) 
                    : Colors.green,
                ),
              ),
              title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(tx.date)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (tx.isExpense ? '- ' : '+ ') + currencyFormat.format(tx.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: tx.isExpense ? Colors.red : Colors.green,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () {
                      context.read<TransactionProvider>().deleteTransaction(tx.id);
                    },
                  ),
                ],
              ),
            ),
          );
        },
        childCount: transactions.length,
      ),
    );
  }
}

/// Custom formatter to add dots as thousand separators while typing
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Get digits only
    final intValue = int.tryParse(newValue.text.replaceAll('.', ''));
    if (intValue == null) return oldValue;

    // Format with dots
    final formatter = NumberFormat.decimalPattern('es_CL');
    final newString = formatter.format(intValue);

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}

