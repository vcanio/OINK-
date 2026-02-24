import '../models/transaction.dart';
import 'hive_service.dart';

class RecurrenceService {
  final HiveService _hiveService;

  RecurrenceService(this._hiveService);

  Future<void> checkAndGenerate() async {
    final transactions = await _hiveService.getTransactions();
    bool recurrenceAdded = false;
    final Set<String> processedSeries = {};
    
    transactions.sort((a, b) => b.date.compareTo(a.date));
    final now = DateTime.now();
    
    for (var tx in transactions) {
      if (!tx.isRecurring) continue;
      
      final seriesKey = "${tx.categoryId}_${tx.amount}_${tx.description}";
      if (processedSeries.contains(seriesKey)) continue;
      processedSeries.add(seriesKey);
      
      // Assure there is a recurrenceId. If not, generate one for this run.
      // (Older transactions won't have it, but they will be grouped by generating it here,
      // and newer transactions will propagate it).
      final String currentRecurrenceId = tx.recurrenceId ?? seriesKey; 
      
      DateTime nextDate = tx.date;
      
      while (true) {
        if (tx.frequency == 'monthly') {
          nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
        } else if (tx.frequency == 'weekly') {
          nextDate = nextDate.add(const Duration(days: 7));
        } else if (tx.frequency == 'daily') {
          nextDate = nextDate.add(const Duration(days: 1));
        } else {
          break;
        }
        
        // We only generate up to today (inclusive)
        if (nextDate.isAfter(now) && !(nextDate.year == now.year && nextDate.month == now.month && nextDate.day == now.day)) {
           break;
        }
        
        final newTx = Transaction.create(
          amount: tx.amount,
          type: tx.type,
          categoryId: tx.categoryId,
          description: tx.description,
          date: nextDate,
          isRecurring: true,
          frequency: tx.frequency,
          walletId: tx.walletId,
          recurrenceId: currentRecurrenceId, // Link to the same recurrence series
        );
        
        await _hiveService.addTransaction(newTx);
        recurrenceAdded = true;
      }
    }
  }
}
