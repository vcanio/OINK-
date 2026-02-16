import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/oink_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../utils/app_styles.dart';
import '../utils/formatters.dart';
import '../utils/constants.dart';
import 'add_transaction_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = 'all'; // all, income, expense
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM, vertical: AppConstants.paddingS),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM, vertical: AppConstants.paddingS),
            child: Row(
              children: [
                _buildFilterChip("Todos", 'all'),
                const SizedBox(width: AppConstants.paddingS),
                _buildFilterChip("Ingresos", 'income'),
                const SizedBox(width: AppConstants.paddingS),
                _buildFilterChip("Gastos", 'expense'),
              ],
            ),
          ),
          
          Expanded(
            child: Consumer<OinkProvider>(
              builder: (context, provider, child) {
                final transactions = provider.transactions.where((tx) {
                  final matchesFilter = _filter == 'all' || tx.type == _filter;
                  final matchesSearch = tx.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      provider.getCategory(tx.categoryId).name.toLowerCase().contains(_searchQuery.toLowerCase());
                  return matchesFilter && matchesSearch;
                }).toList();

                if (transactions.isEmpty) {
                   return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("🔍", style: TextStyle(fontSize: 48)),
                        const SizedBox(height: AppConstants.paddingM),
                        Text(
                          "No se encontraron movimientos",
                          style: AppStyles.bodyLarge.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final category = provider.getCategory(tx.categoryId);
                    final formatter = AppFormatters.currency;

                    return Dismissible(
                      key: Key(tx.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: AppTheme.errorColor.withOpacity(0.1),
                        child: const Icon(Icons.delete, color: AppTheme.errorColor),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("¿Borrar movimiento?"),
                            content: const Text("Esta acción no se puede deshacer"),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true), 
                                child: Text("Borrar", style: TextStyle(color: AppTheme.errorColor)),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        provider.deleteTransaction(tx.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Movimiento eliminado")),
                        );
                      },
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddTransactionScreen(transaction: tx),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(AppConstants.paddingM),
                          decoration: AppStyles.cardDecoration,
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
                              const SizedBox(width: AppConstants.paddingM),
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
                                    Text(
                                      DateFormat.MMMd('es_CL').format(tx.date),
                                      style: AppStyles.label,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "${tx.isExpense ? '-' : '+'}${formatter.format(tx.amount)}",
                                style: AppStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: tx.isExpense ? AppTheme.errorColor : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      labelStyle: AppStyles.label.copyWith(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
        ),
      ),
      checkmarkColor: AppTheme.primaryColor,
    );
  }
}
