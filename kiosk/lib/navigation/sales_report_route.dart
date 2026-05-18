part of 'router.dart';

@TypedGoRoute<SalesReportRoute>(path: '/sales-report')
class SalesReportRoute extends GoRouteData with $SalesReportRoute {
  const SalesReportRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SalesReportScreen();
  }
}
