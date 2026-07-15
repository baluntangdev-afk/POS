part of 'router.dart';

@TypedGoRoute<ZReadingRoute>(path: '/z-reading')
class ZReadingRoute extends GoRouteData with $ZReadingRoute {
  const ZReadingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CashierZReadingScreen();
  }
}

@TypedGoRoute<ZReadingHistoryDetailRoute>(path: '/z-reading/history/:id')
class ZReadingHistoryDetailRoute extends GoRouteData with $ZReadingHistoryDetailRoute {
  const ZReadingHistoryDetailRoute(this.id);

  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return CashierZReadingScreen(historyId: id);
  }
}
