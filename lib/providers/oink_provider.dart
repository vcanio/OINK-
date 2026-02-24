import 'package:flutter/material.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../services/recurrence_service.dart';
import '../services/backup_service.dart';
import 'transactions_provider.dart';
import 'goals_provider.dart';
import 'settings_provider.dart';
import 'budgets_provider.dart';
import 'package:home_widget/home_widget.dart';

class OinkProvider with ChangeNotifier {
  final HiveService _hiveService;
  final NotificationService _notificationService;
  final TransactionsProvider _transactionsProvider;
  final GoalsProvider _goalsProvider;
  final SettingsProvider _settingsProvider;
  final BudgetsProvider _budgetsProvider;

  OinkProvider(
    this._hiveService,
    this._notificationService,
    this._transactionsProvider,
    this._goalsProvider,
    this._settingsProvider,
    this._budgetsProvider,
  );

  bool _isReady = false;
  bool get isReady => _isReady;
  
  final ValueNotifier<bool> routerNotifier = ValueNotifier<bool>(false);

  Future<void> loadData() async {
    await _notificationService.init();
    
    final recurrenceService = RecurrenceService(_hiveService);
    await recurrenceService.checkAndGenerate();
    BackupService.scheduleWeeklyBackup();
    
    await _transactionsProvider.loadTransactions();
    await _goalsProvider.loadSavingsGoals();
    await _budgetsProvider.loadBudgets();
    await _settingsProvider.loadSettings();
    await checkFirstLaunch();
    
    // Configurar HomeWidget
    HomeWidget.setAppGroupId('group.com.example.oink'); 

    // Al tocar el widget si la app estaba cerrada
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_checkForWidgetLaunch);

    // Al tocar el widget con la app en memoria/background
    HomeWidget.widgetClicked.listen(_checkForWidgetLaunch);

    // Artificial delay to show splash screen (optional, but good for UX if load is too fast)
    await Future.delayed(const Duration(milliseconds: 1500));
    
    _isReady = true;
    routerNotifier.value = !routerNotifier.value; // Notify router
    notifyListeners();
  }

  Future<void> wipeData() async {
    await _hiveService.wipeAllData();
    await loadData();
  }

  bool _isFirstLaunch = true;
  bool get isFirstLaunch => _isFirstLaunch;

  Future<void> checkFirstLaunch() async {
    _isFirstLaunch = await _hiveService.isFirstLaunch;
  }

  Future<void> completeOnboarding() async {
    await _hiveService.setFirstLaunch(false);
    _isFirstLaunch = false;
      routerNotifier.value = !routerNotifier.value; // Notify router to redirect from onboarding
      notifyListeners();
    }

    // Ruta de navegación solicitada externamente (ej: por widget)
    String? _requestedRoute;
    String? get requestedRoute => _requestedRoute;

    void _checkForWidgetLaunch(Uri? uri) {
      if (uri != null) {
        if (uri.scheme == 'oink' && uri.host == 'add-transaction') {
            _requestedRoute = '/add-transaction';
            routerNotifier.value = !routerNotifier.value; 
            notifyListeners();
        }
      }
    }
    
    void clearRequestedRoute() {
        _requestedRoute = null;
    }
  }

