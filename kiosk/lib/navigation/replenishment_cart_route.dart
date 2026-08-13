part of 'router.dart';

@TypedGoRoute<ReplenishmentCartRoute>(path: '/replenishment/cart')
class ReplenishmentCartRoute extends GoRouteData with $ReplenishmentCartRoute {
  const ReplenishmentCartRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ReplenishmentCartScreen();
  }
}
