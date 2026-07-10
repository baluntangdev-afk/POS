part of 'router.dart';

@TypedGoRoute<CashierDailyReportRoute>(path: '/cashier-daily-report')
class CashierDailyReportRoute extends GoRouteData with $CashierDailyReportRoute {
  const CashierDailyReportRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CashierDailyReportScreen();
  }
}
