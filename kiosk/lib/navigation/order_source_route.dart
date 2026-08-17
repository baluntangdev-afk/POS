part of 'router.dart';

@TypedGoRoute<OrderSourceRoute>(path: '/order-source')
class OrderSourceRoute extends GoRouteData with $OrderSourceRoute {
  const OrderSourceRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const OrderSourceScreen();
  }
}
