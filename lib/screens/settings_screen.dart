import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/oink_provider.dart';
import '../providers/transactions_provider.dart';
import '../providers/goals_provider.dart';
import '../providers/settings_provider.dart';
import '../models/transaction.dart';
import '../models/savings_goal.dart';
import '../theme/app_theme.dart';
import '../utils/app_styles.dart';
import '../utils/constants.dart';


import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuración"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, "Personalización"),
          _buildSettingsTile(
            context,
            icon: Icons.account_balance_wallet_rounded,
            title: "Configurar Presupuestos",
            subtitle: "Define límites mensuales para tus categorías",
            onTap: () => context.push('/budgets'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.category_rounded,
            title: "Administrar Categorías",
            subtitle: "Crea y edita tus propias categorías",
            onTap: () => context.push('/categories-config'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.event_repeat_rounded,
            title: "Mis Suscripciones",
            subtitle: "Gestiona tus pagos regulares y recurrentes",
            onTap: () => context.push('/subscriptions'),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, "Notificaciones"),
          Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return Column(
                children: [
                  SwitchListTile(
                    title: Text("Recordatorio Diario", style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Recibe una alerta para registrar tus gastos"),
                    value: settings.dailyReminderEnabled,
                    activeColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusM)),
                    tileColor: Theme.of(context).cardColor,
                    onChanged: (bool value) async {
                      await settings.toggleDailyReminder(value);
                    },
                  ),
                  if (settings.dailyReminderEnabled) ...[
                    const SizedBox(height: 8),
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusM)),
                      tileColor: Theme.of(context).cardColor,
                      leading: const Icon(Icons.access_time_rounded),
                      title: const Text("Hora del recordatorio"),
                      subtitle: Text("${settings.dailyReminderTime.hour.toString().padLeft(2, '0')}:${settings.dailyReminderTime.minute.toString().padLeft(2, '0')}"),
                      onTap: () async {
                        final TimeOfDay? time = await showTimePicker(
                          context: context,
                          initialTime: settings.dailyReminderTime,
                        );
                        if (time != null) {
                          await settings.setDailyReminderTime(time);
                        }
                      },
                    ),
                  ],
                ],
              );
            }
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, "Datos"),
          _buildSettingsTile(
            context,
            icon: Icons.upload_rounded,
            title: "Exportar Copia de Seguridad",
            subtitle: "Guardar tus datos en un archivo JSON",
            onTap: () => _exportData(context),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.download_rounded,
            title: "Importar Copia de Seguridad",
            subtitle: "Restaurar datos desde un archivo JSON",
            onTap: () => _importBackup(context),
          ),

          _buildSettingsTile(
            context,
            icon: Icons.delete_forever_rounded,
            title: "Borrar Todo",
            subtitle: "Eliminar todos los movimientos y metas",
            color: Colors.red,
            onTap: () => _wipeData(context),
          ),
          
          const SizedBox(height: 32),
          
          _buildSectionHeader(context, "Acerca de"),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline_rounded,
            title: "OINK!",
            subtitle: "Versión ${AppConstants.appVersion}",
            onTap: () {},
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              "Hecho por Vicente Canio",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final effectiveColor = color ?? Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.textPrimary;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppStyles.getCardDecoration(context),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: effectiveColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: effectiveColor),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: effectiveColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusM)),
      ),
    );
  }



  Future<void> _exportData(BuildContext context) async {
    try {
      final transactionsProvider = Provider.of<TransactionsProvider>(context, listen: false);
      final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);
      final transactions = transactionsProvider.transactions;
      final goals = goalsProvider.savingsGoals;

      final data = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'transactions': transactions.map((t) => {
          'id': t.id,
          'amount': t.amount,
          'type': t.typeString,
          'categoryId': t.categoryId,
          'description': t.description,
          'date': t.date.toIso8601String(),
          'createdAt': t.createdAt.toIso8601String(),
        }).toList(),
        'savingsGoals': goals.map((g) => {
          'id': g.id,
          'name': g.name,
          'targetAmount': g.targetAmount,
          'savedAmount': g.savedAmount,
          'startDate': g.startDate.toIso8601String(),
          'endDate': g.endDate.toIso8601String(),
          'color': g.color,
        }).toList(),
      };

      final jsonString = jsonEncode(data);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/oink_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles([XFile(file.path)], text: 'Copia de seguridad de OINK!');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al exportar: $e")),
      );
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        String jsonString;
        if (kIsWeb) {
          final bytes = result.files.single.bytes;
          if (bytes != null) {
            jsonString = utf8.decode(bytes);
          } else {
            throw Exception("No se pudieron leer los datos del archivo");
          }
        } else {
          final file = File(result.files.single.path!);
          jsonString = await file.readAsString();
        }
        
        final data = jsonDecode(jsonString);

        if (data['version'] == 1) {
          final provider = Provider.of<OinkProvider>(context, listen: false);
          final transactionsProvider = Provider.of<TransactionsProvider>(context, listen: false);
          final goalsProvider = Provider.of<GoalsProvider>(context, listen: false);
          
          // Clear current data
          await provider.wipeData();

          // Import Transactions
          final transactionsList = data['transactions'] as List;
          for (var item in transactionsList) {
            
            // Limpieza de IDs antiguos
            String rawCatId = item['categoryId'];
            if (rawCatId == 'other_expense') rawCatId = 'otherExpense';
            if (rawCatId == 'other_income') rawCatId = 'otherIncome';
            if (rawCatId == 'gift_expense') rawCatId = 'giftExpense';
            if (rawCatId == 'gift_income') rawCatId = 'giftIncome';

            final tx = Transaction(
              id: item['id'],
              amount: item['amount'],
              typeString: item['type'],
              categoryId: rawCatId, // Usamos el ID limpio
              description: item['description'],
              date: DateTime.parse(item['date']),
              createdAt: DateTime.parse(item['createdAt']),
            );
            await transactionsProvider.addTransaction(tx);
          }

          // Import Goals
          final goalsList = data['savingsGoals'] as List;
          for (var item in goalsList) {
            final goal = SavingsGoal(
              id: item['id'],
              name: item['name'],
              targetAmount: item['targetAmount'],
              savedAmount: item['savedAmount'],
              startDate: DateTime.parse(item['startDate']),
              endDate: DateTime.parse(item['endDate']),
              color: item['color'],
            );
            await goalsProvider.addSavingsGoal(goal);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Datos restaurados correctamente")),
          );
        } else {
             ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Versión de archivo no compatible")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al importar: $e")),
      );
    }
  }

  Future<void> _wipeData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Estás seguro?"),
        content: const Text("Se borrarán TODOS tus datos permanentemente."),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => context.pop(true), 
            child: const Text("Borrar Todo", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Provider.of<OinkProvider>(context, listen: false).wipeData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Datos eliminados")),
      );
    }
  }
}
