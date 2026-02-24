import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../providers/transactions_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/transaction_type.dart';
import '../utils/formatters.dart';
import '../theme/app_theme.dart';
import '../utils/app_styles.dart';
import '../utils/constants.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  TransactionType _type = TransactionType.expense;
  double _amount = 0;
  String? _selectedCategoryId;
  String _description = '';
  DateTime _date = DateTime.now();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;


  bool _isInstallment = false;
  int _installments = 1;

  bool _isRecurring = false;
  String _frequency = 'monthly';

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TransactionsProvider>(context, listen: false);


    if (widget.transaction != null) {
      _type = widget.transaction!.type;
      _amount = widget.transaction!.amount;
      _selectedCategoryId = widget.transaction!.categoryId;
      _description = widget.transaction!.description;
      _date = widget.transaction!.date;
      _isRecurring = widget.transaction!.isRecurring;
      if (widget.transaction!.frequency != null) {
        _frequency = widget.transaction!.frequency!;
      }
      
      final formatter = NumberFormat('#,###', 'es_CL');
      _amountController = TextEditingController(text: formatter.format(_amount));
      _descriptionController = TextEditingController(text: _description);
    } else {
      _amountController = TextEditingController();
      _descriptionController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa un monto válido"), backgroundColor: AppTheme.errorColor),
      );
      return;
    }
    
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, selecciona una categoría"), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    if (widget.transaction != null) {
      final updatedTransaction = Transaction(
        id: widget.transaction!.id,
        amount: _amount,
        typeString: _type.name,
        categoryId: _selectedCategoryId!,
        description: _description,
        date: _date,
        createdAt: widget.transaction!.createdAt,
        walletId: 'default',
        isRecurring: _isRecurring,
        frequency: _isRecurring ? _frequency : null,
        groupId: widget.transaction!.groupId,
        recurrenceId: widget.transaction!.recurrenceId,
      );
      Provider.of<TransactionsProvider>(context, listen: false).updateTransaction(updatedTransaction);
    } else {
      final newTransaction = Transaction.create(
        amount: _amount,
        type: _type,
        categoryId: _selectedCategoryId!,
        description: _description,
        date: _date,
        walletId: 'default',
        isRecurring: _isRecurring,
        frequency: _isRecurring ? _frequency : null,
      );
      Provider.of<TransactionsProvider>(context, listen: false).addTransaction(newTransaction, installments: _isInstallment ? _installments : 1);
    }
    
    context.pop();
  }

  bool get _isValid => _amount > 0 && _selectedCategoryId != null;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionsProvider>();
    final categories = provider.allCategories.where((c) => c.type == _type).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = _type == TransactionType.expense ? AppTheme.expenseColor : AppTheme.incomeColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.transaction != null ? "Editar Movimiento" : "Nuevo Movimiento",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Selector de Tipo (Gasto / Ingreso)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))
                  ]
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildTypeButton("Gasto", TransactionType.expense)),
                    Expanded(child: _buildTypeButton("Ingreso", TransactionType.income)),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 2. Ingreso de Monto Gigante
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
              child: Column(
                children: [
                  Text(
                    "Monto",
                    style: AppStyles.label.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  TextField(
                    controller: _amountController,
                    autofocus: widget.transaction == null, // Autofocus solo si es nuevo (Rapidez)
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ThousandsSeparatorInputFormatter(),
                    ],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: headerColor,
                    ),
                    decoration: InputDecoration(
                      prefixText: "\$ ",
                      prefixStyle: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: headerColor),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: "0",
                      hintStyle: TextStyle(color: headerColor.withOpacity(0.3)),
                      filled: false,
                    ),
                    onChanged: (value) {
                      setState(() {
                        String cleanedValue = value.replaceAll('.', '');
                        _amount = double.tryParse(cleanedValue) ?? 0;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 3. Detalles (Categoría, Nota, Fecha) en un contenedor tipo BottomSheet
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.surfaceDark : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Categoría",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // Grid de Categorías compacta
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = _selectedCategoryId == category.id;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => _selectedCategoryId = category.id);
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Color(category.color) : Color(category.color).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: isSelected ? Border.all(color: Color(category.color).withOpacity(0.3), width: 4) : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    category.icon,
                                    size: 26,
                                    color: isSelected ? Colors.white : Color(category.color),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  category.name,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Selector de Fecha y Nota en fila (para ahorrar espacio)
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _descriptionController,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                hintText: "Nota (opcional)",
                                prefixIcon: const Icon(Icons.edit_note_rounded),
                                filled: true,
                                fillColor: Theme.of(context).scaffoldBackgroundColor,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              ),
                              onChanged: (value) => _description = value,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: GestureDetector(
                              onTap: () async {
                                FocusScope.of(context).unfocus(); // Ocultar teclado
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _date,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) setState(() => _date = picked);
                              },
                              child: Container(
                                height: 56, // Misma altura que el input de nota
                                decoration: BoxDecoration(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.calendar_today_rounded, size: 18, color: Theme.of(context).textTheme.bodyLarge?.color),
                                    const SizedBox(width: 6),
                                    Text(
                                      DateFormat('dd MMM').format(_date),
                                      style: AppStyles.label.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      Text(
                        "Opciones Avanzadas",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                      ),
                      const SizedBox(height: 12),
                      


                      // Installments (Solo para gastos)
                      if (_type == TransactionType.expense && widget.transaction == null) ...[
                        _buildAdvancedOptionRow(
                          icon: Icons.credit_score_rounded,
                          title: "¿Es compra en cuotas?",
                          trailing: Switch(
                            value: _isInstallment,
                            activeColor: AppTheme.expenseColor,
                            onChanged: (val) => setState(() => _isInstallment = val),
                          ),
                        ),
                        if (_isInstallment)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 40, bottom: 8),
                            child: Row(
                              children: [
                                Text("Cantidad de cuotas:", style: AppStyles.label),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Slider(
                                    value: _installments.toDouble(),
                                    min: 1,
                                    max: 24,
                                    divisions: 23,
                                    label: "$_installments",
                                    activeColor: AppTheme.expenseColor,
                                    onChanged: (val) => setState(() => _installments = val.toInt()),
                                  ),
                                ),
                                Text("$_installments", style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        const SizedBox(height: 6),
                      ],

                      // Recurrence
                      _buildAdvancedOptionRow(
                        icon: Icons.repeat_rounded,
                        title: "Movimiento Recurrente",
                        trailing: Switch(
                          value: _isRecurring,
                          activeColor: headerColor,
                          onChanged: (val) => setState(() => _isRecurring = val),
                        ),
                      ),
                      if (_isRecurring)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 40, bottom: 8),
                          child: Row(
                            children: [
                              Text("Frecuencia:", style: AppStyles.label),
                              const Spacer(),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _frequency,
                                  isDense: true,
                                  items: const [
                                    DropdownMenuItem(value: 'daily', child: Text("Diaria")),
                                    DropdownMenuItem(value: 'weekly', child: Text("Semanal")),
                                    DropdownMenuItem(value: 'monthly', child: Text("Mensual")),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _frequency = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 100), // Espacio para que el fab no tape contenido
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Botón Gigante y de fácil alcance
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isValid ? () {
              HapticFeedback.mediumImpact();
              _saveTransaction();
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isValid ? headerColor : Theme.of(context).disabledColor.withOpacity(0.2),
              foregroundColor: Colors.white,
              elevation: _isValid ? 4 : 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              "Guardar Movimiento",
              style: AppStyles.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, TransactionType value) {
    final isSelected = _type == value;
    final color = value == TransactionType.expense ? AppTheme.expenseColor : AppTheme.incomeColor;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _type = value;
          _selectedCategoryId = null; // Reiniciar categoría al cambiar
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedOptionRow({
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).disabledColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
          ),
          trailing,
        ],
      ),
    );
  }
}
