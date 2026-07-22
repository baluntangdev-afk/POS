import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/state/auth_providers.dart';
import '../../features/auth/state/auth_state.dart';
import '../../features/auth/view/login_screen.dart';
import '../../features/catalog/view/catalog_screen.dart';
import '../../features/dashboard/view/dashboard_screen.dart';
import '../../features/ordering/view/ordering_screen.dart';
import '../../features/ordering/view/payment_screen.dart';
import '../../features/ordering/view/receipt_screen.dart';
import '../../features/reports/view/reports_screen.dart';
import '../../features/settings/view/csv_import_screen.dart';
import '../../features/settings/view/printer_setup_screen.dart';
import '../../features/settings/view/settings_screen.dart';
import '../../features/settings/view/store_info_screen.dart';
import '../../features/users/view/users_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isAuthenticated = authState is AuthAuthenticated;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isAuthenticated && !isOnLogin) return '/login';
      if (isAuthenticated && isOnLogin) return '/dashboard';
      return null;
    },
    refreshListenable: _AuthStateListenable(ref),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/order',
        builder: (context, state) => const OrderingScreen(),
        routes: [
          GoRoute(
            path: 'payment',
            builder: (context, state) => const PaymentScreen(),
          ),
          GoRoute(
            path: 'receipt',
            builder: (context, state) => const ReceiptScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/catalog',
        builder: (context, state) => const CatalogScreen(),
      ),
      GoRoute(
        path: '/users',
        builder: (context, state) => const UsersScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'csv-import',
            builder: (context, state) => const CsvImportScreen(),
          ),
          GoRoute(
            path: 'store-info',
            builder: (context, state) => const StoreInfoScreen(),
          ),
          GoRoute(
            path: 'printer',
            builder: (context, state) => const PrinterSetupScreen(),
          ),
        ],
      ),
    ],
  );
});

class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen(authNotifierProvider, (previous, next) => notifyListeners());
  }
}
