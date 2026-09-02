part of 'router.dart';

@TypedGoRoute<DeviceTransferRoute>(path: '/device-transfer')
class DeviceTransferRoute extends GoRouteData with $DeviceTransferRoute {
  const DeviceTransferRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const DeviceTransferScreen();
  }
}
