part of 'router.dart';

@TypedGoRoute<CashierReportRoute>(path: '/cashier-report')
class CashierReportRoute extends GoRouteData with $CashierReportRoute {
  const CashierReportRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CashierReportPreviewScreen();
  }
}
