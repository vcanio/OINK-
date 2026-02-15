import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/oink_provider.dart';
import '../models/transaction.dart';
import '../models/savings_goal.dart';


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
          _buildSectionHeader("Datos"),
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
          
          _buildSectionHeader("Acerca de"),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline_rounded,
            title: "OINK!",
            subtitle: "Versión 1.0.0",
            onTap: () {},
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              "Hecho con 🐷 y Flutter",
              style: GoogleFonts.nunito(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.nunito(color: Colors.grey.shade500),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final provider = Provider.of<OinkProvider>(context, listen: false);
      final transactions = provider.transactions;
      final goals = provider.savingsGoals;

      final data = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'transactions': transactions.map((t) => {
          'id': t.id,
          'amount': t.amount,
          'type': t.type,
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
          
          // Clear current data
          await provider.wipeData();

          // Import Transactions
          final transactionsList = data['transactions'] as List;
          for (var item in transactionsList) {
            final tx = Transaction(
              id: item['id'],
              amount: item['amount'],
              type: item['type'],
              categoryId: item['categoryId'],
              description: item['description'],
              date: DateTime.parse(item['date']),
              createdAt: DateTime.parse(item['createdAt']),
            );
            await provider.addTransaction(tx);
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
            await provider.addSavingsGoal(goal);
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
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
