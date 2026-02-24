import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/transaction.dart';
import '../screens/dashboard_screen.dart';
import '../screens/history_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/goals_screen.dart';
import '../screens/add_transaction_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/budgets_config_screen.dart';
import '../screens/categories_config_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/subscriptions_screen.dart';
import '../widgets/scaffold_with_nav_bar.dart';
import '../providers/oink_provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

GoRouter createRouter(OinkProvider oinkProvider) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash', // Start at splash
    refreshListenable: oinkProvider.routerNotifier, // Listen to routerNotifier instead of provider
    redirect: (context, state) {
      final isReady = oinkProvider.isReady;
      final isFirstLaunch = oinkProvider.isFirstLaunch;
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';

      // 1. If not ready, stay on splash (or go to splash if not there)
      if (!isReady) {
        return isSplash ? null : '/splash';
      }

      // 2. If ready and on splash:
      if (isSplash) {
        return isFirstLaunch ? '/onboarding' : '/';
      }

      // 3. Normal flows
      if (isFirstLaunch && !isOnboarding) {
        return '/onboarding';
      }

      if (!isFirstLaunch && isOnboarding) {
        return '/';
      }
      
      // 4. Handle Deeplinks from Widget
      final requestedRoute = oinkProvider.requestedRoute;
      if (requestedRoute != null && isReady && !isFirstLaunch) {
          // Clear route to prevent loop, then perform redirection
          Future.microtask(() => oinkProvider.clearRequestedRoute());
          return requestedRoute;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Dashboard (Inicio)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Tab 1: History (Historial)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          // Tab 2: Valid Placeholder for the 'Add' button index
          StatefulShellBranch(
             routes: [
               GoRoute(
                 path: '/placeholder',
                 builder: (context, state) => const SizedBox(), 
               )
             ]
          ),
          // Tab 3: Reports (Reportes)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
          // Tab 4: Goals (Metas)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/goals',
                builder: (context, state) => const GoalsScreen(),
              ),
            ],
          ),
        ],
      ),
      // Top-Level Routes (outside shell)
      GoRoute(
        path: '/add-transaction',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final transaction = state.extra as Transaction?;
          return AddTransactionScreen(transaction: transaction);
        },
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/budgets',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BudgetsConfigScreen(),
      ),
      GoRoute(
        path: '/categories-config',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CategoriesConfigScreen(),
      ),
      GoRoute(
        path: '/subscriptions',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SubscriptionsScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
}
