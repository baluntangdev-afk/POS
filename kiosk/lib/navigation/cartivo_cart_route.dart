part of 'router.dart';

@TypedGoRoute<CartivoCartRoute>(path: '/cartivo-cart')
class CartivoCartRoute extends GoRouteData with $CartivoCartRoute {
  const CartivoCartRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CartivoCartScreen();
  }
}
