part of 'router.dart';

@TypedGoRoute<CashierReportRoute>(path: '/cashier-report')
class CashierReportRoute extends GoRouteData with $CashierReportRoute {
  const CashierReportRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CashierReportPreviewScreen();
  }
}

@TypedGoRoute<CashierReportHistoryDetailRoute>(path: '/cashier-report/history/:id')
class CashierReportHistoryDetailRoute extends GoRouteData with $CashierReportHistoryDetailRoute {
  const CashierReportHistoryDetailRoute(this.id);

  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CashierReportPreviewScreen(historyId: id);
  }
}
