part of 'router.dart';

@TypedGoRoute<CartivoRegisterRoute>(path: '/cartivo-register')
class CartivoRegisterRoute extends GoRouteData with $CartivoRegisterRoute {
  const CartivoRegisterRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CartivoRegisterScreen();
  }
}
