import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../providers/goals_provider.dart';
import '../models/savings_goal.dart';
import '../models/category_type.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import '../utils/formatters.dart';
import '../theme/app_theme.dart';
import '../utils/app_styles.dart';
import '../utils/constants.dart';
import '../widgets/add_goal_bottom_sheet.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Metas de Ahorro"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(context),
        label: const Text("Nueva Meta"),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Consumer<GoalsProvider>(
            builder: (context, provider, child) {
              final goals = provider.savingsGoals;
              final formatter = AppFormatters.currency;

          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.track_changes_rounded, size: 48, color: AppTheme.textSecondary),
                  const SizedBox(height: AppConstants.paddingM),
                  Text(
                    "No tienes metas aún",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingS),
                  Text(
                    "¡Crea una para empezar a ahorrar!",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final goal = goals[index];
              final progress = goal.targetAmount > 0 ? goal.savedAmount / goal.targetAmount : 0.0;
              final isCompleted = progress >= 1.0;

              return Dismissible(
                key: Key(goal.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  child: const Icon(Icons.delete, color: AppTheme.errorColor),
                ),
                confirmDismiss: (direction) async {
                  await HapticFeedback.mediumImpact();
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("¿Borrar meta?"),
                      content: const Text("Esta acción no se puede deshacer"),
                      actions: [
                        TextButton(onPressed: () => context.pop(false), child: const Text("Cancelar")),
                        TextButton(
                          onPressed: () => context.pop(true), 
                          child: Text("Borrar", style: TextStyle(color: AppTheme.errorColor)),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) {
                  provider.deleteSavingsGoal(goal.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Meta eliminada")),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  decoration: AppStyles.getCardDecoration(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(goal.color).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.savings_rounded, color: Colors.teal), // Could be custom icon
                          ),
                          const SizedBox(width: AppConstants.paddingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.name,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "Meta: ${formatter.format(goal.targetAmount)}",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          if (isCompleted)
                            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingM),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppConstants.radiusS),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Theme.of(context).dividerColor.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(Color(goal.color)),
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingS),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatter.format(goal.savedAmount),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Color(goal.color),
                            ),
                          ),
                          Text(
                            "${(progress * 100).toStringAsFixed(0)}%",
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingM),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isCompleted
                              ? null
                              : () => _showAddFundsDialog(context, goal, provider),
                          icon: const Icon(Icons.add),
                          label: const Text("Abonar"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(goal.color).withOpacity(0.1),
                            foregroundColor: Color(goal.color),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusM),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      Align(
        alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const AddGoalBottomSheet();
      },
    );
  }

  void _showAddFundsDialog(BuildContext context, SavingsGoal goal, GoalsProvider provider) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Abonar a ${goal.name}"),
          content: TextField(
            controller: amountController,
            decoration: const InputDecoration(labelText: "Monto a abonar", prefixText: "\$"),
            keyboardType: TextInputType.number,
            inputFormatters: [
               ThousandsSeparatorInputFormatter(),
            ],
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                final amountString = amountController.text.replaceAll('.', '');
                final amount = double.tryParse(amountString) ?? 0;
                if (amount > 0) {
                  // Use the new method that creates the transaction
                  _addFunds(context, goal, provider, amount);
                }
              },
              child: const Text("Abonar"),
            ),
          ],
        );
      },
    );
  }

  void _addFunds(BuildContext context, SavingsGoal goal, GoalsProvider provider, double amount) {
    final previousAmount = goal.savedAmount;
    provider.addFundsToGoal(goal, amount);
    
    context.pop();
    
    if (previousAmount < goal.targetAmount && (previousAmount + amount) >= goal.targetAmount) {
      _confettiController.play();
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("¡Abonado \$${amount.toStringAsFixed(0)} a ${goal.name}!")),
    );
  }
}
