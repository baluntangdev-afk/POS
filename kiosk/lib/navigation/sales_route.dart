part of 'router.dart';

@TypedGoRoute<SalesRoute>(path: '/sales')
class SalesRoute extends GoRouteData with $SalesRoute {
  const SalesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ChooseLocationScreen();
  }
}

@TypedGoRoute<OrderingRoute>(path: '/ordering')
class OrderingRoute extends GoRouteData with $OrderingRoute {
  const OrderingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const OrderingScreen();
  }
}

@TypedGoRoute<CartRoute>(path: '/cart')
class CartRoute extends GoRouteData with $CartRoute {
  const CartRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CartScreen();
  }
}
@TypedGoRoute<PaymentRoute>(path: '/payment')
class PaymentRoute extends GoRouteData with $PaymentRoute {
  const PaymentRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const PaymentScreen();
  }
}

@TypedGoRoute<ReceiptRoute>(path: '/receipt/:receiptId')
class ReceiptRoute extends GoRouteData with $ReceiptRoute {
  const ReceiptRoute(this.receiptId);

  final String receiptId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ReceiptScreen(receiptId: receiptId);
  }
}
@TypedGoRoute<DiscountRoute>(path: '/discount')
class DiscountRoute extends GoRouteData with $DiscountRoute {
  const DiscountRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const DiscountScreen();
  }
}
