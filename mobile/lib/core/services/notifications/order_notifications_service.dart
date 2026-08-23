import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../features/live_orders/entities/order_event.dart';

final orderNotificationsServiceProvider = Provider<OrderNotificationsService>((ref) {
  return OrderNotificationsService();
});

/// One local (device-level) notification per received live-order event —
/// separate from the in-app toast, so a new order is visible even when the
/// app isn't in the foreground. Every call is best-effort: a failure here
/// (permission denied, plugin not initialized) must never affect the live
/// feed itself.
class OrderNotificationsService {
  OrderNotificationsService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'live_orders';
  static const _channelName = 'Live orders';
  static const _channelDescription = 'New and updated orders from your storefront';

  /// Call once, before `runApp` — sets up the Android notification channel
  /// and requests the Android 13+ runtime notification permission.
  Future<void> initialize() async {
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _plugin.initialize(
        settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      );

      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );
      await androidPlugin?.requestNotificationsPermission();
    } catch (_) {
      // Best-effort — a notification-setup failure shouldn't block startup.
    }
  }

  Future<void> notify(OrderEvent event) async {
    final data = event.data;
    final (title, body) = switch (event.type) {
      OrderEventType.created => (
          'New order #${data.id}',
          '${data.items.length} item${data.items.length == 1 ? '' : 's'} · ${data.currency} ${data.total}',
        ),
      OrderEventType.updated => ('Order #${data.id} updated', 'Status: ${data.status}'),
      OrderEventType.cancelled => ('Order #${data.id} cancelled', ''),
    };

    try {
      await _plugin.show(
        id: event.eventId.hashCode,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {
      // Best-effort — never let a notification failure break the live feed.
    }
  }
}
