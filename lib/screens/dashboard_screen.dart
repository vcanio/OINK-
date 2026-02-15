import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/oink_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';

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
          final formatter = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF85A2), Color(0xFFFFC107)], // Pink to Gold
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF85A2).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Balance Total",
                      style: GoogleFonts.nunito(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatter.format(balance),
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 24),
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
              
              const SizedBox(height: 32),
              
              // Recent Transactions Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Últimos movimientos",
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: onSeeAllPressed,
                    child: Text(
                      "Ver todo",
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
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
                      const SizedBox(height: 16),
                      Text(
                        "No hay movimientos aún",
                        style: GoogleFonts.nunito(
                          color: Colors.grey.shade400,
                          fontSize: 16,
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
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              if (tx.description.isNotEmpty)
                                Text(
                                  tx.description,
                                  style: GoogleFonts.nunito(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                  ),
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
                              "${tx.type == 'expense' ? '-' : '+'}${formatter.format(tx.amount)}",
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: tx.type == 'expense' ? const Color(0xFFE57373) : const Color(0xFF81C784),
                              ),
                            ),
                            Text(
                              DateFormat.MMMd('es_CL').format(tx.date),
                              style: GoogleFonts.nunito(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
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
              style: GoogleFonts.nunito(
                color: textColor.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              amount,
              style: GoogleFonts.nunito(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
