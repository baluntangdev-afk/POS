part of 'router.dart';

@TypedGoRoute<UserManagementRoute>(path: '/user-management')
class UserManagementRoute extends GoRouteData with $UserManagementRoute {
  const UserManagementRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const UserManagementScreen();
  }
}
