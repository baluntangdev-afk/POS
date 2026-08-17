part of 'router.dart';

@TypedGoRoute<CartivoProductsRoute>(path: '/cartivo-products')
class CartivoProductsRoute extends GoRouteData with $CartivoProductsRoute {
  const CartivoProductsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CartivoProductsScreen();
  }
}
