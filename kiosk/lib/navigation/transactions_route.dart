part of 'router.dart';

@TypedGoRoute<TransactionsRoute>(
  path: '/transactions',
  routes: [TypedGoRoute<RefundRoute>(path: 'refund/:receiptId')],
)
class TransactionsRoute extends GoRouteData with $TransactionsRoute {
  const TransactionsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const TransactionsScreen();
  }
}

class RefundRoute extends GoRouteData with $RefundRoute {
  const RefundRoute(this.receiptId);

  final String receiptId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return RefundScreen(receiptId: receiptId);
  }
}
