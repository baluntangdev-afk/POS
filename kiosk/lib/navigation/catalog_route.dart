part of 'router.dart';

@TypedGoRoute<ProductsRoute>(
  path: '/products',
  routes: [TypedGoRoute<ProductVariantsRoute>(path: ':productId/variants')],
)
class ProductsRoute extends GoRouteData with $ProductsRoute {
  const ProductsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CatalogScreen();
  }
}

class ProductVariantsRoute extends GoRouteData with $ProductVariantsRoute {
  const ProductVariantsRoute(this.productId);

  final String productId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ProductVariantsScreen(productId: productId);
  }
}
