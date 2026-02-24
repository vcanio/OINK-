import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/transactions_provider.dart';
import '../models/transaction.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/transaction_type.dart';
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
  final ScrollController _scrollController = ScrollController();
  String _filter = 'all'; // all, income, expense
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;
  String? _selectedCategory; // Category ID (name of enum)

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<TransactionsProvider>().loadMoreTransactions();
    }
  }

  void _resetPagination() {
    context.read<TransactionsProvider>().resetTransactionLimit();
  }

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
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _resetPagination();
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
                _buildFilterChip("Ingresos", TransactionType.income.name),
                const SizedBox(width: AppConstants.paddingS),
                _buildFilterChip("Gastos", TransactionType.expense.name),
                const SizedBox(width: AppConstants.paddingS),
                _buildDateRangeChip(),
                const SizedBox(width: AppConstants.paddingS),
                _buildCategoryChip(),
              ],
            ),
          ),
          
          Expanded(
            child: Consumer<TransactionsProvider>(
              builder: (context, provider, child) {
                // 1. Filtrado
                final filteredTransactions = provider.transactions.where((tx) {
                  final matchesType = _filter == 'all' || tx.type.name == _filter;
                  final matchesSearch = _searchQuery.isEmpty || 
                      tx.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      provider.getCategory(tx.categoryId).name.toLowerCase().contains(_searchQuery.toLowerCase());
                  
                  bool matchesDate = true;
                  if (_selectedDateRange != null) {
                    matchesDate = tx.date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) && 
                                  tx.date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
                  }

                  bool matchesCategory = true;
                  if (_selectedCategory != null) {
                    matchesCategory = tx.categoryId == _selectedCategory;
                  }

                  return matchesType && matchesSearch && matchesDate && matchesCategory;
                }).toList();

                if (filteredTransactions.isEmpty) {
                   return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textSecondary),
                        const SizedBox(height: AppConstants.paddingM),
                        Text(
                          "No se encontraron movimientos",
                          style: AppStyles.bodyLarge.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                // 2. Paginación
                final paginatedTransactions = filteredTransactions.take(provider.transactionLimit).toList();

                // 3. Agrupación por Mes
                final Map<String, List<Transaction>> groupedTransactions = {};
                for (var tx in paginatedTransactions) {
                  final monthYear = DateFormat('MMMM yyyy', 'es_CL').format(tx.date);
                  final capitalizedMonth = "${monthYear[0].toUpperCase()}${monthYear.substring(1)}";
                  
                  if (!groupedTransactions.containsKey(capitalizedMonth)) {
                    groupedTransactions[capitalizedMonth] = [];
                  }
                  groupedTransactions[capitalizedMonth]!.add(tx);
                }

                final groupKeys = groupedTransactions.keys.toList();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  itemCount: groupKeys.length + (filteredTransactions.length > provider.transactionLimit ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == groupKeys.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final groupName = groupKeys[index];
                    final transactionsInGroup = groupedTransactions[groupName]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: Text(
                            groupName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                        ...transactionsInGroup.map((tx) {
                          final category = provider.getCategory(tx.categoryId);
                          return _buildTransactionItem(context, tx, category, provider); 
                        }).toList(),
                      ],
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

  Widget _buildTransactionItem(BuildContext context, Transaction tx, Category category, TransactionsProvider provider) {
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
        await HapticFeedback.mediumImpact();
        
        if (tx.groupId != null) {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("¿Borrar cuota?"),
              content: const Text("Esta transacción es parte de una compra en cuotas. ¿Qué deseas hacer?"),
              actions: [
                TextButton(onPressed: () => context.pop(false), child: const Text("Cancelar")),
                TextButton(
                  onPressed: () {
                    provider.deleteTransaction(tx.id);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cuota eliminada")));
                    context.pop(true);
                  }, 
                  child: const Text("Solo esta cuota", style: TextStyle(color: AppTheme.errorColor)),
                ),
                TextButton(
                  onPressed: () {
                    provider.deleteTransactionGroup(tx.groupId!);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Compra en cuotas eliminada")));
                    context.pop(true);
                  }, 
                  child: const Text("Todas las cuotas", style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }

        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("¿Borrar movimiento?"),
            content: const Text("Esta acción no se puede deshacer"),
            actions: [
              TextButton(onPressed: () => context.pop(false), child: const Text("Cancelar")),
              TextButton(
                onPressed: () {
                  provider.deleteTransaction(tx.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Movimiento eliminado")));
                  context.pop(true);
                }, 
                child: const Text("Borrar", style: TextStyle(color: AppTheme.errorColor)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        // Deletion is already handled inside the dialogs to support the multiple choices
      },
      child: GestureDetector(
        onTap: () {
          context.push('/add-transaction', extra: tx);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(AppConstants.paddingM),
          decoration: AppStyles.getCardDecoration(context),
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
                child: Icon(
                  category.icon,
                  size: 24,
                  color: Color(category.color),
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
                        color: Theme.of(context).textTheme.bodyLarge?.color,
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
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = value;
          _resetPagination();
        });
      },
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      labelStyle: AppStyles.label.copyWith(
        color: isSelected ? AppTheme.primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Theme.of(context).dividerColor,
        ),
      ),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildDateRangeChip() {
    final isSelected = _selectedDateRange != null;
    final label = isSelected 
        ? "${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}"
        : "Fecha";

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) async {
        if (!selected) {
          setState(() {
            _selectedDateRange = null;
            _resetPagination();
          });
          return;
        }
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: _selectedDateRange,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppTheme.primaryColor,
                  onPrimary: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            _selectedDateRange = picked;
            _resetPagination();
          });
        }
      },
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      labelStyle: AppStyles.label.copyWith(
        color: isSelected ? AppTheme.primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Theme.of(context).dividerColor,
        ),
      ),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildCategoryChip() {
    final isSelected = _selectedCategory != null;
    final provider = context.read<TransactionsProvider>();
    final allCategories = provider.allCategories;

    // Find category name if selected
    String label = "Categoría";
    if (isSelected) {
       final cat = allCategories.firstWhere((c) => c.id == _selectedCategory, orElse: () => allCategories.first);
       label = cat.name;
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) async {
        if (!selected) {
          setState(() {
            _selectedCategory = null;
            _resetPagination();
          });
          return;
        }
        // Show Dialog to pick category
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Seleccionar Categoría"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allCategories.length,
                itemBuilder: (context, index) {
                  final cat = allCategories[index];
                  return ListTile(
                    leading: Icon(cat.icon, color: Color(cat.color)),
                    title: Text(cat.name),
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat.id;
                        _resetPagination();
                      });
                      context.pop();
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
      backgroundColor: Theme.of(context).cardColor,
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      labelStyle: AppStyles.label.copyWith(
        color: isSelected ? AppTheme.primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Theme.of(context).dividerColor,
        ),
      ),
      checkmarkColor: AppTheme.primaryColor,
    );
  }
}
