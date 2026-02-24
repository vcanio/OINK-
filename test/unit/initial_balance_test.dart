import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:oink/services/hive_service.dart';
import 'package:oink/services/notification_service.dart';
import 'package:oink/providers/oink_provider.dart';
import 'package:oink/providers/transactions_provider.dart';
import 'package:oink/providers/goals_provider.dart';
import 'package:oink/providers/settings_provider.dart';
import 'package:oink/providers/budgets_provider.dart';
import 'package:oink/models/transaction.dart';
import 'package:oink/models/savings_goal.dart';
import 'dart:io';

class MockNotificationService implements NotificationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> init() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Initial Balance Feature Tests', () {
    late HiveService hiveService;
    late NotificationService notificationService;
    late TransactionsProvider transactionsProvider;
    late GoalsProvider goalsProvider;
    late SettingsProvider settingsProvider;
    late BudgetsProvider budgetsProvider;
    late OinkProvider provider;
    late Directory tempDir;

    setUp(() async {
      // Create a temporary directory for Hive
      tempDir = await Directory.systemTemp.createTemp();
      Hive.init(tempDir.path);
      
      // Register Adapters if needed (mocking them or using real ones if simple)
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TransactionAdapter());
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SavingsGoalAdapter());

      // Initialize provider
      hiveService = HiveService();
      notificationService = MockNotificationService();
      
      transactionsProvider = TransactionsProvider(hiveService);
      goalsProvider = GoalsProvider(hiveService, transactionsProvider);
      settingsProvider = SettingsProvider(hiveService, notificationService);
      budgetsProvider = BudgetsProvider(hiveService);

      provider = OinkProvider(
        hiveService,
        notificationService,
        transactionsProvider,
        goalsProvider,
        settingsProvider,
        budgetsProvider,
      );
      // We need to await loadData so it initializes everything
      await provider.loadData();
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      await tempDir.delete(recursive: true);
    });

    test('First launch should be true by default', () async {
      // We need to re-check because loadData calls checkFirstLaunch
      await provider.checkFirstLaunch();
      expect(provider.isFirstLaunch, true);
    });

    test('Setting initial balance should create transaction and set first launch to false', () async {
      double initialAmount = 15000;
      await transactionsProvider.setInitialBalance(initialAmount);
      await provider.completeOnboarding();

      expect(provider.isFirstLaunch, false);
      expect(transactionsProvider.transactions.length, 1);
      expect(transactionsProvider.transactions.first.amount, initialAmount);
      expect(transactionsProvider.transactions.first.description, 'Saldo Inicial');
    });

    test('Setting initial balance with 0 should not create transaction but set first launch to false', () async {
      double initialAmount = 0;
      await transactionsProvider.setInitialBalance(initialAmount);
      await provider.completeOnboarding();

      expect(provider.isFirstLaunch, false);
      expect(transactionsProvider.transactions.length, 0);
    });
  });
}

