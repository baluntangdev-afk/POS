import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import 'app_routes.dart';
import 'route_guards.dart';

part 'app_router.g.dart';

/// Global navigator key — lets non-widget code (e.g. the session-expiry
/// listener) drive navigation.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Global scaffold-messenger key — lets non-widget code (e.g. the live-orders
/// feed) show a snackbar without a `BuildContext`.
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

@riverpod
GoRouter appRouter(Ref ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: appNavigatorKey,
    initialLocation: AppRoutes.dashboard,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
}
