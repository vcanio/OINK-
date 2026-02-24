import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transactions_provider.dart';
import '../models/category.dart';
import '../models/transaction_type.dart';
import '../theme/app_theme.dart';
import '../utils/app_styles.dart';

class CategoriesConfigScreen extends StatefulWidget {
  const CategoriesConfigScreen({super.key});

  @override
  State<CategoriesConfigScreen> createState() => _CategoriesConfigScreenState();
}

class _CategoriesConfigScreenState extends State<CategoriesConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  IconData _icon = Icons.category_rounded;
  Color _color = AppTheme.primaryColor;
  TransactionType _type = TransactionType.expense;

  void _showAddCategoryDialog() {
    _name = '';
    _icon = Icons.category_rounded;
    _color = AppTheme.primaryColor;
    _type = TransactionType.expense;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
             return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text("Nueva Categoría", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      const SizedBox(height: 24),

                      // Tipo
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeButton(
                              title: "Gasto",
                              type: TransactionType.expense,
                              color: AppTheme.expenseColor,
                              isSelected: _type == TransactionType.expense,
                              onTap: () => setState(() => _type = TransactionType.expense),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTypeButton(
                              title: "Ingreso",
                              type: TransactionType.income,
                              color: AppTheme.incomeColor,
                              isSelected: _type == TransactionType.income,
                              onTap: () => setState(() => _type = TransactionType.income),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Nombre
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: "Nombre",
                          hintText: "Ej. Viajes",
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => v == null || v.isEmpty ? 'Ingresa un nombre' : null,
                        onSaved: (v) => _name = v!,
                      ),
                      const SizedBox(height: 24),

                      // Icono y Color Previsualización
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text("Icono", style: AppStyles.label),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  // Simplified icon picker (could use a package for more)
                                  final selectedIcon = await _showIconPicker();
                                  if (selectedIcon != null) setState(() => _icon = selectedIcon);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle),
                                  child: Icon(_icon, size: 32, color: _color),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text("Color", style: AppStyles.label),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final selectedColor = await _showColorPicker();
                                  if (selectedColor != null) setState(() => _color = selectedColor);
                                },
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(color: _color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      FilledButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            final newCategory = Category.create(
                              name: _name,
                              icon: _icon,
                              color: _color,
                              type: _type,
                            );
                            Provider.of<TransactionsProvider>(context, listen: false).addCustomCategory(newCategory);
                            Navigator.pop(context);
                          }
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: _type == TransactionType.expense ? AppTheme.expenseColor : AppTheme.incomeColor,
                        ),
                        child: const Text("Guardar Categoría", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTypeButton({
    required String title,
    required TransactionType type,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? color : Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<IconData?> _showIconPicker() async {
    final List<IconData> icons = [
      Icons.category_rounded, Icons.shopping_bag_rounded, Icons.flight_rounded,
      Icons.pets_rounded, Icons.directions_car_rounded, Icons.local_dining_rounded,
      Icons.local_cafe_rounded, Icons.fitness_center_rounded, Icons.movie_rounded,
      Icons.child_care_rounded, Icons.house_rounded, Icons.water_drop_rounded,
      Icons.electric_bolt_rounded, Icons.wifi_rounded, Icons.phone_android_rounded,
      Icons.laptop_chromebook_rounded, Icons.menu_book_rounded, Icons.palette_rounded,
      Icons.music_note_rounded, Icons.medication_rounded, Icons.card_giftcard_rounded,
    ];

    return showDialog<IconData>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Seleccionar Icono"),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: icons.length,
            itemBuilder: (context, index) {
              final icon = icons[index];
              return InkWell(
                onTap: () => Navigator.pop(context, icon),
                customBorder: const CircleBorder(),
                child: Icon(icon, size: 32),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<Color?> _showColorPicker() async {
    final List<Color> colors = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
      Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
      Colors.brown, Colors.grey, Colors.blueGrey, Colors.black,
    ];

    return showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Seleccionar Color"),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              return InkWell(
                onTap: () => Navigator.pop(context, color),
                customBorder: const CircleBorder(),
                child: Container(decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Administrar Categorías"),
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 2,
        backgroundColor: AppTheme.primaryColor,
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Consumer<TransactionsProvider>(
        builder: (context, provider, child) {
          final customCategories = provider.customCategories;
          
          if (customCategories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Theme.of(context).disabledColor),
                  const SizedBox(height: 16),
                  Text(
                    "No has creado categorías personalizadas",
                    style: AppStyles.bodyLarge.copyWith(color: Theme.of(context).disabledColor),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: customCategories.length,
            itemBuilder: (context, index) {
              final cat = customCategories[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: AppStyles.getCardDecoration(context),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(cat.colorValue).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(cat.icon, color: Color(cat.colorValue)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat.name, style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                          Text(cat.type == TransactionType.income ? "Ingreso" : "Gasto", style: AppStyles.label),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
                      onPressed: () {
                        // Confirm deletion
                         showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Eliminar Categoría"),
                            content: const Text("¿Estás seguro de que deseas eliminar esta categoría? Los movimientos existentes con esta categoría podrían verse afectados."),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                              TextButton(
                                onPressed: () {
                                  provider.deleteCustomCategory(cat.id);
                                  Navigator.pop(context);
                                },
                                child: const Text("Eliminar", style: TextStyle(color: AppTheme.errorColor)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
