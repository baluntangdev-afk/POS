part of 'router.dart';

@TypedGoRoute<ProductsRoute>(
  path: '/products',
  routes: [
    TypedGoRoute<ProductDetailRoute>(path: ':productId'),
    TypedGoRoute<ProductVariantsRoute>(path: ':productId/variants'),
  ],
)
class ProductsRoute extends GoRouteData with $ProductsRoute {
  const ProductsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CatalogScreen();
  }
}

class ProductDetailRoute extends GoRouteData with $ProductDetailRoute {
  const ProductDetailRoute(this.productId);

  final int productId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ProductDetailScreen(productId: productId);
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
