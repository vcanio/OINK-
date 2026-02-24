import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/budgets_provider.dart';
import '../providers/transactions_provider.dart';
import '../models/category.dart';
import '../models/budget.dart';
import '../models/transaction_type.dart';
import '../theme/app_theme.dart';
import '../utils/app_styles.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class BudgetsConfigScreen extends StatelessWidget {
  const BudgetsConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tus Presupuestos"),
      ),
      body: Consumer2<BudgetsProvider, TransactionsProvider>(
        builder: (context, budgetsProvider, txProvider, child) {
          final expenseCategories = txProvider.allCategories
              .where((c) => c.type == TransactionType.expense)
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: expenseCategories.length,
            itemBuilder: (context, index) {
              final category = expenseCategories[index];
              final budget = budgetsProvider.getBudgetForCategory(category.id);
              final hasBudget = budget != null && budget.amount > 0;
              final formatter = AppFormatters.currency;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: AppStyles.getCardDecoration(context),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(category.color).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(category.icon, color: Color(category.color)),
                  ),
                  title: Text(
                    category.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    hasBudget ? 'Límite: ${formatter.format(budget.amount)}' : 'Sin límite',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: hasBudget ? AppTheme.primaryColor : Theme.of(context).disabledColor,
                    ),
                  ),
                  trailing: const Icon(Icons.edit_rounded, size: 20),
                  onTap: () => _showEditBudgetDialog(context, category, budget, budgetsProvider),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditBudgetDialog(
    BuildContext context, 
    Category category, 
    Budget? currentBudget,
    BudgetsProvider provider,
  ) {
    final amountController = TextEditingController(
      text: currentBudget != null && currentBudget.amount > 0
          ? currentBudget.amount.toStringAsFixed(0)
          : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Presupuesto para ${category.name}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Define un límite mensual. Déjalo en 0 o vacío para eliminarlo.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: "Límite (\$)",
                  prefixText: "\$ ",
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                   ThousandsSeparatorInputFormatter(),
                ],
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                final amountString = amountController.text.replaceAll('.', '');
                final amount = double.tryParse(amountString) ?? 0;

                if (currentBudget != null) {
                  if (amount > 0) {
                    currentBudget.amount = amount;
                    provider.updateBudget(currentBudget);
                  } else {
                    provider.deleteBudget(currentBudget.id);
                  }
                } else if (amount > 0) {
                  final newBudget = Budget.create(
                    categoryId: category.id,
                    amount: amount,
                  );
                  provider.addBudget(newBudget);
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Presupuesto actualizado para ${category.name}")),
                );
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }
}
