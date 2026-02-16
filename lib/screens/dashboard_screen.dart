import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/oink_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../utils/app_styles.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback? onSeeAllPressed;

  const DashboardScreen({super.key, this.onSeeAllPressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OINK!"),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Text("🐷", style: TextStyle(fontSize: 24)),
            onPressed: () {}, // Maybe easter egg?
          ),
        ],
      ),
      body: Consumer<OinkProvider>(
        builder: (context, provider, child) {
          final transactions = provider.transactions;
          final balance = provider.totalBalance;
          final formatter = AppFormatters.currency;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Balance Card
              Container(
                width: double.infinity,
                height: 220, // Give it a fixed height for the card look
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor, // Solid Pink
                  borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Watermark Icon
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Transform.rotate(
                        angle: -0.2, // Slight tilt
                        child: Icon(
                          Icons.savings_rounded,
                          size: 180,
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                    ),
                    // Card Content
                    Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Balance Total",
                                style: AppStyles.bodyLarge.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppConstants.paddingS),
                              Text(
                                formatter.format(balance),
                                style: AppStyles.moneyBig.copyWith(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSummaryItem(
                                label: "Ingresos",
                                amount: formatter.format(provider.totalIncome),
                                icon: Icons.arrow_upward_rounded,
                                color: Colors.green.shade100,
                                textColor: Colors.white,
                              ),
                              _buildSummaryItem(
                                label: "Gastos",
                                amount: formatter.format(provider.totalExpenses),
                                icon: Icons.arrow_downward_rounded,
                                color: Colors.red.shade100,
                                textColor: Colors.white,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Recent Transactions Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Últimos movimientos",
                    style: AppStyles.heading2,
                  ),
                  TextButton(
                    onPressed: onSeeAllPressed,
                    child: Text(
                      "Ver todo",
                      style: AppStyles.bodyLarge.copyWith(
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
                      Text(
                        "🐷",
                        style: TextStyle(fontSize: 64, color: Colors.grey.shade300),
                      ),
                      const SizedBox(height: AppConstants.paddingM),
                      Text(
                        "No hay movimientos aún",
                        style: AppStyles.bodyLarge.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...transactions.take(5).map((tx) {
                  final category = provider.getCategory(tx.categoryId);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color(category.color).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            category.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.name,
                                style: AppStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (tx.description.isNotEmpty)
                                Text(
                                  tx.description,
                                  style: AppStyles.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${tx.isExpense ? '-' : '+'}${formatter.format(tx.amount)}",
                              style: AppStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: tx.isExpense ? AppTheme.errorColor : Colors.green,
                              ),
                            ),
                            Text(
                              DateFormat.MMMd('es_CL').format(tx.date),
                              style: AppStyles.label,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                
              const SizedBox(height: 80), // Bottom padding for FAB
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String amount,
    required IconData icon,
    required Color color,
    required Color textColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppStyles.label.copyWith(
                color: textColor.withOpacity(0.8),
              ),
            ),
            Text(
              amount,
              style: AppStyles.bodyLarge.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
