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

  // Webhook auth — exchanges webhook_secret + merchant_id for a short-lived JWT
  static const String authToken = '/auth/token';

  // Device registration
  static const String devicesRegister = '/devices/register';

  // Device token — exchanges device credentials for a short-lived WS bearer JWT
  static const String devicesToken = '/devices/token';

  // Orders — paginated order-event stream for the authenticated merchant
  static const String merchantOrders = '/merchant/orders';

  /// `PATCH /merchant/orders/{orderId}` — update a single order (e.g. status).
  static String merchantOrder(String orderId) =>
      '/merchant/orders/${Uri.encodeComponent(orderId)}';
}
