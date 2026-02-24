import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/savings_goal.dart';
import '../models/budget.dart';
import '../models/wallet.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Hive.initFlutter();
      Hive.registerAdapter(TransactionAdapter());
      Hive.registerAdapter(SavingsGoalAdapter());
      Hive.registerAdapter(BudgetAdapter());
      Hive.registerAdapter(WalletAdapter());

      // Open boxes
      final txBox = await Hive.openBox<Transaction>('transactionsBox');
      final walletsBox = await Hive.openBox<Wallet>('walletsBox');

      // Prepare Data
      final txList = txBox.values.map((tx) => {
            'id': tx.id,
            'amount': tx.amount,
            'typeString': tx.typeString,
            'categoryId': tx.categoryId,
            'description': tx.description,
            'date': tx.date.toIso8601String(),
            'createdAt': tx.createdAt.toIso8601String(),
            'isRecurring': tx.isRecurring,
            'frequency': tx.frequency,
            'walletId': tx.walletId,
          }).toList();

      final walletList = walletsBox.values.map((w) => {
            'id': w.id,
            'name': w.name,
            'balance': w.balance,
            'colorValue': w.colorValue,
            'iconCodePoint': w.iconCodePoint,
          }).toList();

      final backupData = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'transactions': txList,
        'wallets': walletList,
      };

      final jsonString = jsonEncode(backupData);

      // Save to external documents folder (visible to user on Android) or application docs
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Documents/oink');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final File file = File('${directory.path}/oink_backup.json');
        await file.writeAsString(jsonString);
        debugPrint("Backup created successfully at: ${file.path}");
      }
      return Future.value(true);
    } catch (e) {
      debugPrint("Backup failed: $e");
      return Future.value(false);
    }
  });
}

class BackupService {
  static Future<void> init() async {
    if (kIsWeb) return;
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  static void scheduleWeeklyBackup() {
    if (kIsWeb) return;
    Workmanager().registerPeriodicTask(
      "oink_weekly_backup_1", // unique name
      "weekly_backup_task",
      frequency: const Duration(days: 7),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: true,
      ),
    );
  }
}
