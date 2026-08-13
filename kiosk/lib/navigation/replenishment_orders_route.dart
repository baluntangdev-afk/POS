part of 'router.dart';

@TypedGoRoute<ReplenishmentOrdersRoute>(path: '/replenishment/orders')
class ReplenishmentOrdersRoute extends GoRouteData with $ReplenishmentOrdersRoute {
  const ReplenishmentOrdersRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ReplenishmentOrdersScreen();
  }
}
