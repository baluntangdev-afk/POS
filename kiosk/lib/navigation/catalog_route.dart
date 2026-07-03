part of 'router.dart';

@TypedGoRoute<ProductsRoute>(path: '/products')
class ProductsRoute extends GoRouteData with $ProductsRoute {
  const ProductsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const CatalogScreen();
  }
}
