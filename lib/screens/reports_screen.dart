import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transactions_provider.dart';
import '../providers/budgets_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/category_type.dart';
import '../models/transaction_type.dart';
import '../theme/app_theme.dart';
import '../utils/app_styles.dart';
import '../utils/formatters.dart';
import '../utils/constants.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _showTrend = false;

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
      body: Consumer2<TransactionsProvider, BudgetsProvider>(
        builder: (context, provider, budgetsProvider, child) {
          final monthTransactions = provider.transactions.where((tx) {
            return tx.date.year == _selectedDate.year && tx.date.month == _selectedDate.month;
          }).toList();

          final income = monthTransactions.where((tx) => tx.type == TransactionType.income).fold(0.0, (sum, tx) => sum + tx.amount);
          final expense = monthTransactions.where((tx) => tx.type == TransactionType.expense && tx.categoryId != CategoryType.savings.name).fold(0.0, (sum, tx) => sum + tx.amount);
          final balance = income - expense;
          
          final formatter = AppFormatters.currency;

          // Group expenses by category
          final Map<String, double> categoryExpenses = {};
          for (var tx in monthTransactions.where((tx) => tx.type == TransactionType.expense && tx.categoryId != CategoryType.savings.name)) {
            categoryExpenses.update(tx.categoryId, (value) => value + tx.amount, ifAbsent: () => tx.amount);
          }
          
          final sortedCategories = categoryExpenses.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          // Trend calculations
          final now = DateTime.now();
          List<BarChartGroupData> barGroups = [];
          double maxChartValue = 0;
          List<String> monthLabels = [];

          for (int i = 5; i >= 0; i--) {
            final monthDate = DateTime(now.year, now.month - i);
            monthLabels.add(DateFormat.MMM('es_CL').format(monthDate).toUpperCase());
            final mtx = provider.transactions.where((tx) => tx.date.year == monthDate.year && tx.date.month == monthDate.month);
            final mIn = mtx.where((tx) => tx.type == TransactionType.income).fold(0.0, (s, tx) => s + tx.amount);
            final mEx = mtx.where((tx) => tx.type == TransactionType.expense && tx.categoryId != CategoryType.savings.name).fold(0.0, (s, tx) => s + tx.amount);
            
            if (mIn > maxChartValue) maxChartValue = mIn;
            if (mEx > maxChartValue) maxChartValue = mEx;

            barGroups.add(
              BarChartGroupData(
                x: 5 - i,
                barRods: [
                  BarChartRodData(
                    toY: mIn,
                    color: Colors.green,
                    width: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  BarChartRodData(
                    toY: mEx,
                    color: Colors.red,
                    width: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }

          return GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                _prevMonth();
              } else if (details.primaryVelocity! < 0) {
                // Only allow next month if not current month
                if (!(_selectedDate.month == DateTime.now().month && _selectedDate.year == DateTime.now().year)) {
                  _nextMonth();
                }
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Toggle Mensual vs Tendencia
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Mensual')),
                        ButtonSegment(value: true, label: Text('Tendencia')),
                      ],
                      selected: {_showTrend},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() { _showTrend = newSelection.first; });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (!_showTrend) ...[
                  // Month Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(onPressed: _prevMonth, icon: const Icon(Icons.chevron_left)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
                        child: Text(
                          DateFormat.yMMMM('es_CL').format(_selectedDate).toUpperCase(),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
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
                ],
                
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

                if (_showTrend)
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    ),
                    child: Column(
                      children: [
                        Text("Evolución (6 meses)", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        Expanded(
                          child: BarChart(
                            BarChartData(
                              maxY: maxChartValue == 0 ? 1 : maxChartValue * 1.2,
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    return BarTooltipItem(
                                      formatter.format(rod.toY),
                                      TextStyle(color: rod.color, fontWeight: FontWeight.bold),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 46,
                                    getTitlesWidget: (value, meta) {
                                      if (value == 0) return const SizedBox.shrink();
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Text(
                                          NumberFormat.compact(locale: 'es_CL').format(value),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index >= 0 && index < monthLabels.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(monthLabels[index], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(show: true, drawVerticalLine: false),
                              barGroups: barGroups,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (categoryExpenses.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        "No hay gastos este mes",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
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
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                shape: BoxShape.circle,
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                              ),
                              child: Icon(category.icon, size: 16, color: Color(category.color)),
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
                    final budget = budgetsProvider.getBudgetForCategory(entry.key);
                    final hasBudget = budget != null && budget.amount > 0;
                    final budgetProgress = hasBudget ? (entry.value / budget.amount) : 0.0;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(category.color).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(category.icon, color: Color(category.color)),
                              ),
                              const SizedBox(width: AppConstants.paddingM),
                              Expanded(
                                child: Text(
                                  category.name,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatter.format(entry.value),
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "$percentage%",
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (hasBudget) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: budgetProgress.clamp(0.0, 1.0),
                                backgroundColor: Theme.of(context).dividerColor.withOpacity(0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  budgetProgress > 1.0 ? Colors.red : Color(category.color),
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${(budgetProgress * 100).toStringAsFixed(1)}%",
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: budgetProgress >= 1.0 ? Colors.red : null,
                                  ),
                                ),
                                Text(
                                  "Límite: ${formatter.format(budget.amount)}",
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: AppStyles.getCardDecoration(context).copyWith(
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}
