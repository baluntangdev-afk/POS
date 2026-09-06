/// All backend endpoint paths, relative to the configured API base URL.
///
/// Add new resource paths here rather than scattering string literals through
/// the datasources.
class ApiEndpoints {
  const ApiEndpoints._();

  // Auth
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';

  // Dashboard (placeholder — wire up when the feature is implemented)
  // static const String dashboardSummary = '/merchant/dashboard';
}
