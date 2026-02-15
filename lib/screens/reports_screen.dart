import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/oink_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../utils/app_styles.dart';
import '../utils/constants.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedDate = DateTime.now();

  void _prevMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reportes"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
          ),
        ],
      ),
      body: Consumer<OinkProvider>(
        builder: (context, provider, child) {
          final monthTransactions = provider.transactions.where((tx) {
            return tx.date.year == _selectedDate.year && tx.date.month == _selectedDate.month;
          }).toList();

          final income = monthTransactions.where((tx) => tx.type == 'income').fold(0.0, (sum, tx) => sum + tx.amount);
          final expense = monthTransactions.where((tx) => tx.type == 'expense').fold(0.0, (sum, tx) => sum + tx.amount);
          final balance = income - expense;
          
          final formatter = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

          // Group expenses by category
          final Map<String, double> categoryExpenses = {};
          for (var tx in monthTransactions.where((tx) => tx.type == 'expense')) {
            categoryExpenses.update(tx.categoryId, (value) => value + tx.amount, ifAbsent: () => tx.amount);
          }
          
          final sortedCategories = categoryExpenses.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Month Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
                    child: Text(
                      DateFormat.yMMMM('es_CL').format(_selectedDate).toUpperCase(),
                      style: AppStyles.heading3,
                    ),
                  ),
                  IconButton(
                    onPressed: _selectedDate.month == DateTime.now().month && _selectedDate.year == DateTime.now().year
                        ? null
                        : _nextMonth,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      "Ingresos",
                      formatter.format(income),
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      "Gastos",
                      formatter.format(expense),
                      Colors.red,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              if (categoryExpenses.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      "No hay gastos este mes",
                      style: AppStyles.bodyLarge.copyWith(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else ...[
                // Chart
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: sortedCategories.map((entry) {
                        final category = provider.getCategory(entry.key);
                        return PieChartSectionData(
                          color: Color(category.color),
                          value: entry.value,
                          title: '',
                          radius: 50,
                          badgeWidget: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: Text(category.icon, style: const TextStyle(fontSize: 16)),
                          ),
                          badgePositionPercentageOffset: .98,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Category List
                ...sortedCategories.map((entry) {
                  final category = provider.getCategory(entry.key);
                  final percentage = (entry.value / expense * 100).toStringAsFixed(1);
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(category.color).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Text(category.icon),
                        ),
                        const SizedBox(width: AppConstants.paddingM),
                        Expanded(
                          child: Text(
                            category.name,
                            style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatter.format(entry.value),
                              style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "$percentage%",
                              style: AppStyles.label,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: AppStyles.cardDecoration.copyWith(
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppStyles.label,
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: AppStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
