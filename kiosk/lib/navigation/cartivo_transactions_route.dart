part of 'router.dart';

@TypedGoRoute<CartivoTransactionsRoute>(path: '/cartivo-transactions')
class CartivoTransactionsRoute extends GoRouteData with $CartivoTransactionsRoute {
  const CartivoTransactionsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CartivoTransactionsScreen();
  }
}
