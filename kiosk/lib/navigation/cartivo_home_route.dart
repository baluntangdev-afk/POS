part of 'router.dart';

@TypedGoRoute<CartivoHomeRoute>(path: '/cartivo-home')
class CartivoHomeRoute extends GoRouteData with $CartivoHomeRoute {
  const CartivoHomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CartivoHomeScreen();
  }
}
