part of 'router.dart';

@TypedGoRoute<CartivoLoginRoute>(path: '/cartivo-login')
class CartivoLoginRoute extends GoRouteData with $CartivoLoginRoute {
  const CartivoLoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CartivoLoginScreen();
  }
}
