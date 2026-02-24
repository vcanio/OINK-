import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/oink_provider.dart';
import '../providers/transactions_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../utils/app_styles.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_item.dart';
import '../widgets/whats_new_dialog.dart';
import '../providers/settings_provider.dart';
import '../providers/budgets_provider.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onSeeAllPressed;

  const DashboardScreen({super.key, this.onSeeAllPressed});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWhatsNew();
    });
  }
  
  void _checkWhatsNew() {
    if (!mounted) return;
    
    final settingsProvider = context.read<SettingsProvider>();
    if (settingsProvider.showWhatsNew) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const WhatsNewDialog(),
      ).then((_) {
        // When dialog is closed, update the settings
        if (mounted) {
          context.read<SettingsProvider>().dismissWhatsNew();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OINK!", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              context.push('/settings');
            },
          ),

        ],
      ),
      body: Consumer<TransactionsProvider>(
        builder: (context, provider, child) {
          final transactions = provider.transactions;
          final balance = provider.totalBalance;
          final formatter = AppFormatters.currency;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // Budget Alerts
              Consumer<BudgetsProvider>(
                builder: (context, budgetsProvider, child) {
                  final budgets = budgetsProvider.budgets;
                  if (budgets.isEmpty) return const SizedBox.shrink();

                  final now = DateTime.now();
                  final currentMonthExpenses = transactions.where((t) => t.isExpense && t.date.year == now.year && t.date.month == now.month).toList();
                  
                  List<Widget> alerts = [];
                  for (var budget in budgets) {
                    final spent = currentMonthExpenses.where((t) => t.categoryId == budget.categoryId).fold(0.0, (sum, t) => sum + t.amount);
                    if (budget.amount > 0 && spent >= budget.amount * 0.9) {
                      final category = provider.getCategory(budget.categoryId);
                      final percentage = (spent / budget.amount * 100);
                      final isOver = spent > budget.amount;
                      
                      alerts.add(
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isOver ? AppTheme.errorColor.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isOver ? AppTheme.errorColor.withOpacity(0.3) : Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: isOver ? AppTheme.errorColor : Colors.orange),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isOver 
                                    ? "¡Superaste tu presupuesto de ${category.name} por ${formatter.format(spent - budget.amount)}!"
                                    : "Has usado el ${percentage.toStringAsFixed(0)}% de tu presupuesto de ${category.name}.",
                                  style: AppStyles.bodyMedium.copyWith(
                                    color: isOver ? AppTheme.errorColor : Colors.orange.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      );
                    }
                  }

                  if (alerts.isEmpty) return const SizedBox.shrink();
                  
                  return Column(
                    children: [
                      ...alerts,
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
              if (provider.getInsights().isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  decoration: AppStyles.getCardDecoration(context).copyWith(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: AppTheme.primaryColor),
                      const SizedBox(width: AppConstants.paddingM),
                      Expanded(
                        child: Text(
                          provider.getInsights().first,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Balance Card
              BalanceCard(
                totalBalance: balance,
                totalIncome: provider.totalIncome,
                totalExpenses: provider.totalExpenses,
              ),


              
              const SizedBox(height: 32),
              
              // Recent Transactions Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Últimos movimientos",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () => context.go('/history'),
                    child: Text(
                      "Ver todo",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Transactions List
              if (transactions.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                        Icon(
                          Icons.savings_rounded,
                          size: 64,
                          color: Theme.of(context).disabledColor,
                        ),
                      const SizedBox(height: AppConstants.paddingM),
                      Text(
                        "No hay movimientos aún",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).disabledColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...transactions.take(5).map((tx) {
                  final category = provider.getCategory(tx.categoryId);
                  return TransactionItem(
                    transaction: tx,
                    category: category,
                  );
                }),
                
              const SizedBox(height: 80), // Bottom padding for FAB
            ],
          );
        },
      ),
    );
  }
}
