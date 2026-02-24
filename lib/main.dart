import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'theme/app_theme.dart';
import 'models/transaction.dart';
import 'models/savings_goal.dart';
import 'models/budget.dart';
import 'models/wallet.dart';
import 'models/category.dart';
import 'providers/oink_provider.dart';
import 'providers/transactions_provider.dart';
import 'providers/goals_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/budgets_provider.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'services/backup_service.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await BackupService.init();
  await Hive.initFlutter();
  
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(SavingsGoalAdapter());
  Hive.registerAdapter(BudgetAdapter());
  Hive.registerAdapter(WalletAdapter());
  Hive.registerAdapter(CategoryAdapter());
  
  await initializeDateFormatting('es_CL', null);

  runApp(const OinkApp());
}

// Cambiamos a StatefulWidget para conservar la instancia del Router
class OinkApp extends StatefulWidget {
  const OinkApp({super.key});

  @override
  State<OinkApp> createState() => _OinkAppState();
}

class _OinkAppState extends State<OinkApp> {
  late final HiveService _hiveService;
  late final NotificationService _notificationService;
  late final TransactionsProvider _transactionsProvider;
  late final GoalsProvider _goalsProvider;
  late final SettingsProvider _settingsProvider;
  late final BudgetsProvider _budgetsProvider;
  late final OinkProvider _oinkProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _hiveService = HiveService();
    _notificationService = NotificationService();
    
    _transactionsProvider = TransactionsProvider(_hiveService);
    _goalsProvider = GoalsProvider(_hiveService, _transactionsProvider);
    _settingsProvider = SettingsProvider(_hiveService, _notificationService);
    _budgetsProvider = BudgetsProvider(_hiveService);
    
    // 1. Inicializamos el provider una única vez
    _oinkProvider = OinkProvider(
      _hiveService,
      _notificationService,
      _transactionsProvider,
      _goalsProvider,
      _settingsProvider,
      _budgetsProvider,
    )..loadData();
    // 2. Inicializamos el router una única vez usando ese provider
    _router = createRouter(_oinkProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _transactionsProvider),
        ChangeNotifierProvider.value(value: _goalsProvider),
        ChangeNotifierProvider.value(value: _settingsProvider),
        ChangeNotifierProvider.value(value: _budgetsProvider),
        ChangeNotifierProvider.value(value: _oinkProvider),
      ],
      // Eliminamos el Consumer general. MaterialApp.router se mantendrá estable.
      child: MaterialApp.router(
        title: 'OINK!',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _router, // Pasamos la instancia guardada
      ),
    );
  }
}
