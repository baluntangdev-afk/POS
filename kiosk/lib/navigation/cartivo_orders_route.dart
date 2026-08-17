part of 'router.dart';

@TypedGoRoute<CartivoOrdersRoute>(path: '/cartivo-orders')
class CartivoOrdersRoute extends GoRouteData with $CartivoOrdersRoute {
  const CartivoOrdersRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CartivoOrdersScreen();
  }
}
