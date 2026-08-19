part of 'router.dart';

@TypedGoRoute<OrdersRoute>(path: '/orders')
class OrdersRoute extends GoRouteData with $OrdersRoute {
  const OrdersRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const OrdersScreen();
  }
}
