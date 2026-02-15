import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class ExpensesChart extends StatelessWidget {
  final List<Transaction> transactions;

  const ExpensesChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final expenses = transactions.where((tx) => tx.isExpense).toList();

    if (expenses.isEmpty) {
      return const SizedBox.shrink();
    }

    final Map<String, double> categoryTotals = {};
    double totalExpenses = 0;

    for (var tx in expenses) {
      categoryTotals[tx.categoryId] = (categoryTotals[tx.categoryId] ?? 0) + tx.amount;
      totalExpenses += tx.amount;
    }

    // Sort categories by amount descending
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             const Text(
              'Gastos por Categoría',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sortedEntries.map((entry) {
                    final category = defaultCategories.firstWhere(
                      (c) => c.id == entry.key,
                      orElse: () => defaultCategories.last, // 'others'
                    );
                    final percentage = (entry.value / totalExpenses) * 100;
                    
                    return PieChartSectionData(
                      color: category.color,
                      value: entry.value,
                      title: '${percentage.toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: sortedEntries.map((entry) {
                 final category = defaultCategories.firstWhere(
                      (c) => c.id == entry.key,
                      orElse: () => defaultCategories.last,
                    );
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(category.name),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
