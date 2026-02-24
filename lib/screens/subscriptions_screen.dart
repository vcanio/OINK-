import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transactions_provider.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';
import '../utils/app_styles.dart';
import '../utils/formatters.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Suscripciones"),
      ),
      body: Consumer<TransactionsProvider>(
        builder: (context, provider, child) {
          final allTransactions = provider.transactions;
          
          // Find all transactions that are recurring and group them to find unique active ones.
          // We look for the most recent transaction of each recurrence series.
          final Map<String, Transaction> activeSubscriptions = {};
          
          for (var tx in allTransactions) {
            if (tx.isRecurring) {
              final seriesKey = tx.recurrenceId ?? "${tx.categoryId}_${tx.amount}_${tx.description}";
              if (!activeSubscriptions.containsKey(seriesKey)) {
                activeSubscriptions[seriesKey] = tx; // Add first (most recent because it's sorted)
              }
            }
          }
          
          final subscriptionsList = activeSubscriptions.values.toList();
          
          if (subscriptionsList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.event_repeat_rounded, size: 64, color: Theme.of(context).disabledColor),
                   const SizedBox(height: 16),
                   Text(
                     "No tienes suscripciones activas",
                     style: AppStyles.bodyLarge.copyWith(color: Theme.of(context).disabledColor),
                   )
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subscriptionsList.length,
            itemBuilder: (context, index) {
              final tx = subscriptionsList[index];
              final category = provider.getCategory(tx.categoryId);
              final formatter = AppFormatters.currency;
              
              String freqStr = "";
              if (tx.frequency == 'daily') freqStr = "Diaria";
              if (tx.frequency == 'weekly') freqStr = "Semanal";
              if (tx.frequency == 'monthly') freqStr = "Mensual";
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
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
                      child: Icon(category.icon, color: Color(category.color)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.description.isNotEmpty ? tx.description : category.name,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold) ?? AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "$freqStr - Cuesta ${formatter.format(tx.amount)}",
                            style: AppStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_rounded, color: AppTheme.errorColor),
                      onPressed: () => _cancelSubscription(context, tx, provider),
                      tooltip: "Cancelar suscripción",
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
  
  void _cancelSubscription(BuildContext context, Transaction tx, TransactionsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Cancelar Suscripción?"),
        content: const Text("Se detendrán los cobros automáticos futuros para esta suscripción. Los pagos anteriores se mantendrán en tu historial."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Volver")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // To cancel, we simply update the most recent transaction to not be recurring
              // so the RecurrenceService stops picking it up.
              final updatedTx = Transaction(
                id: tx.id,
                amount: tx.amount,
                typeString: tx.typeString,
                categoryId: tx.categoryId,
                description: tx.description,
                date: tx.date,
                createdAt: tx.createdAt,
                walletId: tx.walletId,
                isRecurring: false, // Cancelled
                frequency: null,
                groupId: tx.groupId,
                recurrenceId: tx.recurrenceId,
              );
              await provider.updateTransaction(updatedTx);
              if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Suscripción cancelada")));
              }
            }, 
            child: const Text("Cancelar Suscripción", style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
          ),
        ],
      )
    );
  }
}
