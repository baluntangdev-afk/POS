part of 'router.dart';

@TypedGoRoute<CashierReportsRoute>(path: '/cashier-reports')
class CashierReportsRoute extends GoRouteData with $CashierReportsRoute {
  const CashierReportsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CashierReportsScreen();
  }
}
