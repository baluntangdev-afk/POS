/// All route paths as constants. Path params (`/order/:id`) are parsed in the
/// route builder.
class AppRoutes {
  const AppRoutes._();

  static const String dashboard = '/';

  /// Reserved for the auth feature — not wired into the router yet.
  static const String login = '/login';
}
