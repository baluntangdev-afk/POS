part of 'router.dart';

@TypedGoRoute<ReplenishmentRoute>(path: '/replenishment')
class ReplenishmentRoute extends GoRouteData with $ReplenishmentRoute {
  const ReplenishmentRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ReplenishmentScreen();
  }
}
