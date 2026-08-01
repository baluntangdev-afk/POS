part of 'router.dart';

@TypedGoRoute<StartupRoute>(path: '/')
class StartupRoute extends GoRouteData with $StartupRoute {
  const StartupRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const StartupScreen();
  }
}
