import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/state/auth_providers.dart';
import '../../features/auth/state/auth_state.dart';
import '../../features/auth/view/login_screen.dart';
import '../../features/auth/view/setup_pin_screen.dart';
import '../../features/cashier_accounting/daily_report/view/daily_report_history_screen.dart';
import '../../features/cashier_accounting/daily_report/view/daily_report_screen.dart';
import '../../features/cashier_accounting/view/cashier_accounting_hub_screen.dart';
import '../../features/cashier_accounting/x_reading/view/x_reading_history_screen.dart';
import '../../features/cashier_accounting/x_reading/view/x_reading_screen.dart';
import '../../features/cashier_accounting/z_reading/view/z_reading_history_screen.dart';
import '../../features/cashier_accounting/z_reading/view/z_reading_screen.dart';
import '../../features/inventory/view/inventory_screen.dart';
import '../../features/inventory/view/modifier_groups_screen.dart';
import '../../features/dashboard/view/dashboard_screen.dart';
import '../../features/orders/view/orders_screen.dart';
import '../../features/ordering/view/discount_screen.dart';
import '../../features/ordering/view/ordering_screen.dart';
import '../../features/ordering/view/payment_screen.dart';
import '../../features/ordering/view/receipt_screen.dart';
import '../../features/reports/view/reports_screen.dart';
import '../../features/settings/view/backup_screen.dart';
import '../../features/settings/view/csv_export_key_screen.dart';
import '../../features/settings/view/csv_import_screen.dart';
import '../../features/settings/view/printer_setup_screen.dart';
import '../../features/settings/view/settings_screen.dart';
import '../../features/settings/view/store_info_screen.dart';
import '../../features/transactions/view/transactions_screen.dart';
import '../../features/users/view/users_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isAuthenticated = authState is AuthAuthenticated;
      final isOnLogin = state.matchedLocation == '/login';
      final isOnSetupPin = state.matchedLocation == '/setup-pin';
      final mustChangePin =
          authState is AuthAuthenticated && authState.mustChangePin;

      if (!isAuthenticated && !isOnLogin) return '/login';
      if (isAuthenticated && mustChangePin && !isOnSetupPin) {
        return '/setup-pin';
      }
      if (isAuthenticated && !mustChangePin && isOnSetupPin) {
        return '/dashboard';
      }
      if (isAuthenticated && isOnLogin) return '/dashboard';

      const cashierRestrictedPrefixes = [
        '/inventory',
        '/users',
        '/settings/csv-import',
        '/settings/backup',
        '/settings/store-info',
      ];
      if (isAuthenticated &&
          !authState.user.isAdminOrSupervisor &&
          cashierRestrictedPrefixes
              .any((prefix) => state.matchedLocation.startsWith(prefix))) {
        return '/dashboard';
      }

      return null;
    },
    refreshListenable: _AuthStateListenable(ref),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/setup-pin',
        builder: (context, state) => const SetupPinScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DashboardScreen(),
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 180),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/order',
        builder: (context, state) => const OrderingScreen(),
        routes: [
          GoRoute(
            path: 'discount',
            builder: (context, state) => const DiscountScreen(),
          ),
          GoRoute(
            path: 'payment',
            builder: (context, state) => const PaymentScreen(),
          ),
          GoRoute(
            path: 'receipt/:id',
            builder:
                (context, state) => ReceiptScreen(
                  saleId: int.parse(state.pathParameters['id']!),
                  type: ReceiptType.order,
                ),
          ),
        ],
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/transactions',
        builder: (context, state) => const TransactionsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder:
                (context, state) => ReceiptScreen(
                  saleId: int.parse(state.pathParameters['id']!),
                  type: ReceiptType.transaction,
                ),
          ),
        ],
      ),
      GoRoute(
        path: '/cashier-accounting',
        builder: (context, state) => const CashierAccountingHubScreen(),
        routes: [
          GoRoute(
            path: 'x-reading',
            builder: (context, state) => const XReadingScreen(),
            routes: [
              GoRoute(
                path: 'history',
                builder: (context, state) => const XReadingHistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder:
                        (context, state) => XReadingReprintScreen(
                          historyId: int.parse(state.pathParameters['id']!),
                        ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'daily-report',
            builder: (context, state) => const DailyReportScreen(),
            routes: [
              GoRoute(
                path: 'history',
                builder: (context, state) => const DailyReportHistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder:
                        (context, state) => DailyReportReprintScreen(
                          historyId: int.parse(state.pathParameters['id']!),
                        ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'z-reading',
            builder: (context, state) => const ZReadingScreen(),
            routes: [
              GoRoute(
                path: 'history',
                builder: (context, state) => const ZReadingHistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder:
                        (context, state) => ZReadingReprintScreen(
                          historyId: int.parse(state.pathParameters['id']!),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const InventoryScreen(),
        routes: [
          GoRoute(
            path: 'products/:id/modifiers',
            builder:
                (context, state) => ModifierGroupsScreen(
                  productId: int.parse(state.pathParameters['id']!),
                ),
          ),
        ],
      ),
      GoRoute(path: '/users', builder: (context, state) => const UsersScreen()),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'csv-import',
            builder: (context, state) => const CsvImportScreen(),
          ),
          GoRoute(
            path: 'backup',
            builder: (context, state) => const BackupScreen(),
          ),
          GoRoute(
            path: 'store-info',
            builder: (context, state) => const StoreInfoScreen(),
          ),
          GoRoute(
            path: 'printer',
            builder: (context, state) => const PrinterSetupScreen(),
          ),
          GoRoute(
            path: 'csv-export-key',
            builder: (context, state) => const CsvExportKeyScreen(),
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
