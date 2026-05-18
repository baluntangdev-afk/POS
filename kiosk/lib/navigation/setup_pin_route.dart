part of 'router.dart';

@TypedGoRoute<SetupPinRoute>(path: '/set-pin')
class SetupPinRoute extends GoRouteData with $SetupPinRoute {
  const SetupPinRoute(this.$extra);

  final Auth $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    if (state.extra != null) {
      return SetupPinScreen(auth: $extra);
    }
    return const Scaffold(body: Center(child: Text('Something went wrong')));
  }
}
