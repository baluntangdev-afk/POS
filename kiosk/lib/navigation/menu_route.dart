part of 'router.dart';

@TypedGoRoute<MenuRoute>(path: '/menu')
class MenuRoute extends GoRouteData with $MenuRoute {
  const MenuRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const MenuScreen();
  }
}
