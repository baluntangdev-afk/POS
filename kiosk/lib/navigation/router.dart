import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features/auth/entities/auth.dart';
import '../features/auth/view/cartivo_cart_screen.dart';
import '../features/auth/view/cartivo_home_screen.dart';
import '../features/auth/view/cartivo_login_screen.dart';
import '../features/auth/view/cartivo_orders_screen.dart';
import '../features/auth/view/cartivo_products_screen.dart';
import '../features/auth/view/cartivo_register_screen.dart';
import '../features/auth/view/cartivo_transactions_screen.dart';
import '../features/auth/view/login_screen.dart';
import '../features/auth/view/setup_pin_screen.dart';
import '../features/cashier_report/view/cashier_daily_report_screen.dart';
import '../features/cashier_report/view/cashier_report_preview_screen.dart';
import '../features/cashier_report/view/cashier_reports_screen.dart';
import '../features/cashier_report/view/cashier_z_reading_screen.dart';
import '../features/inventory/view/inventory_screen.dart';
import '../features/menu/view/menu_screen.dart';
import '../features/order_source/view/order_source_screen.dart';
import '../features/replenishment/view/replenishment_cart_screen.dart';
import '../features/replenishment/view/replenishment_orders_screen.dart';
import '../features/replenishment/view/replenishment_screen.dart';
import '../features/sales/view/cart_screen.dart';
import '../features/sales/view/choose_location_screen.dart';
import '../features/sales/view/discount_screen.dart';
import '../features/sales/view/ordering_screen.dart';
import '../features/sales/view/payment_screen.dart';
import '../features/sales/view/receipt_screen.dart';
import '../features/sales/view/refund_screen.dart';
import '../features/sales/view/transactions_screen.dart';
import '../features/startup/startup_screen.dart';
import '../features/users/view/user_management_screen.dart';
import 'windows_touch_keyboard_observer.dart';

part 'cartivo_cart_route.dart';
part 'cartivo_home_route.dart';
part 'cartivo_login_route.dart';
part 'cartivo_orders_route.dart';
part 'cartivo_products_route.dart';
part 'cartivo_register_route.dart';
part 'cartivo_transactions_route.dart';
part 'cashier_daily_report_route.dart';
part 'cashier_report_route.dart';
part 'cashier_reports_route.dart';
part 'inventory_route.dart';
part 'login_route.dart';
part 'menu_route.dart';
part 'order_source_route.dart';
part 'replenishment_cart_route.dart';
part 'replenishment_orders_route.dart';
part 'replenishment_route.dart';
part 'router.g.dart';
part 'sales_route.dart';
part 'setup_pin_route.dart';
part 'startup_route.dart';
part 'transactions_route.dart';
part 'user_management_route.dart';
part 'z_reading_route.dart';

final routerProvider = Provider((ref) {
  final router = GoRouter(
    initialLocation: const StartupRoute().location,
    routes: $appRoutes,
    observers: [WindowsTouchKeyboardObserver()],
  );
  return router;
});
