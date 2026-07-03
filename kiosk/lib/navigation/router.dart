import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features/auth/entities/auth.dart';
import '../features/auth/view/login_screen.dart';
import '../features/auth/view/setup_pin_screen.dart';
import '../features/catalog/view/catalog_screen.dart';
import '../features/menu/view/menu_screen.dart';
import '../features/onboarding/view/onboarding_screen.dart';
import '../features/reports/view/sales_report_screen.dart';
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

part 'catalog_route.dart';
part 'login_route.dart';
part 'menu_route.dart';
part 'onboarding_route.dart';
part 'router.g.dart';
part 'sales_report_route.dart';
part 'sales_route.dart';
part 'setup_pin_route.dart';
part 'startup_route.dart';
part 'transactions_route.dart';
part 'user_management_route.dart';

final routerProvider = Provider((ref) {
  final router = GoRouter(initialLocation: const StartupRoute().location, routes: $appRoutes);
  return router;
});
