part of 'router.dart';

@TypedGoRoute<CashierDailyReportRoute>(path: '/cashier-daily-report')
class CashierDailyReportRoute extends GoRouteData with $CashierDailyReportRoute {
  const CashierDailyReportRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CashierDailyReportScreen();
  }
}

@TypedGoRoute<CashierDailyReportHistoryDetailRoute>(path: '/cashier-daily-report/history/:id')
class CashierDailyReportHistoryDetailRoute extends GoRouteData
    with $CashierDailyReportHistoryDetailRoute {
  const CashierDailyReportHistoryDetailRoute(this.id);

  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CashierDailyReportScreen(historyId: id);
  }
}
