import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../providers/oink_provider.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

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
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<OinkProvider>(
        builder: (context, provider, child) {
          final goals = provider.savingsGoals;
          final formatter = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("🎯", style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    "No tienes metas aún",
                    style: GoogleFonts.nunito(
                      color: Colors.grey.shade400,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "¡Crea una para empezar a ahorrar!",
                    style: GoogleFonts.nunito(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
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
              final progress = goal.savedAmount / goal.targetAmount;
              final isCompleted = progress >= 1.0;

              return Dismissible(
                key: Key(goal.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.red.shade100,
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("¿Borrar meta?"),
                      content: const Text("Esta acción no se puede deshacer"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true), 
                          child: const Text("Borrar", style: TextStyle(color: Colors.red)),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
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
                            child: const Icon(Icons.savings_rounded, color: Colors.orange), // Could be custom icon
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  goal.name,
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "Meta: ${formatter.format(goal.targetAmount)}",
                                  style: GoogleFonts.nunito(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isCompleted)
                            const Text("🎉", style: TextStyle(fontSize: 24)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(goal.color)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatter.format(goal.savedAmount),
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              color: Color(goal.color),
                            ),
                          ),
                          Text(
                            "${(progress * 100).toStringAsFixed(0)}%",
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
                              borderRadius: BorderRadius.circular(12),
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
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    Color selectedColor = Colors.blue;
    // Define a list of vibrant colors for goals
    final List<Color> goalColors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.redAccent,
      Colors.indigo,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    "Nueva Meta de Ahorro",
                    style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Define tu objetivo y empieza a ahorrar",
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // Name Input
                  Text("Nombre", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: "Ej. Viaje a Japón",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.stars_rounded, color: Colors.grey),
                    ),
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 24),

                  // Amount Input
                  Text("Monto Objetivo", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      ThousandsSeparatorInputFormatter(),
                    ],
                    decoration: InputDecoration(
                      hintText: "0",
                      prefixText: "\$ ",
                      prefixStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18),
                  ),

                  const SizedBox(height: 24),

                  // Color Picker
                  Text("Color", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: goalColors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final color = goalColors[index];
                        final isSelected = selectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedColor = color;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),

                  const Spacer(),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            "Cancelar",
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            final name = nameController.text.trim();
                            final amountString = amountController.text.replaceAll('.', '');
                            final amount = double.tryParse(amountString) ?? 0;
                            
                            if (name.isNotEmpty && amount > 0) {
                              final newGoal = SavingsGoal.create(
                                name: name,
                                targetAmount: amount,
                                startDate: DateTime.now(),
                                endDate: DateTime.now().add(const Duration(days: 365)),
                                color: selectedColor.value,
                              );
                              Provider.of<OinkProvider>(context, listen: false).addSavingsGoal(newGoal);
                              Navigator.pop(context);
                               ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("¡Meta '$name' creada con éxito! 🚀"),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            } else {
                               // Show simple validation error
                               ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text("Por favor ingresa un nombre y un monto válido"),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            "Crear Meta",
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddFundsDialog(BuildContext context, SavingsGoal goal, OinkProvider provider) {
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
              onPressed: () => Navigator.pop(context),
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

  void _addFunds(BuildContext context, SavingsGoal goal, OinkProvider provider, double amount) {
     final updatedGoal = goal.copyWith(
      savedAmount: goal.savedAmount + amount,
    );
    provider.updateSavingsGoal(updatedGoal);

    // Create expense transaction for the savings
    final transaction = Transaction.create(
      amount: amount,
      type: 'expense',
      categoryId: 'savings', // Defined in category.dart
      description: 'Abono a meta: ${goal.name}',
      date: DateTime.now(),
    );
    provider.addTransaction(transaction);

    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("¡Abonado \$${amount.toStringAsFixed(0)} a ${goal.name}!")),
    );
  }
}
