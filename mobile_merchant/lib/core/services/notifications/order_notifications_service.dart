import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

import '../../../features/orders/data/models/order_event_dto.dart';

/// The title / body shown for one live order event — shared by the OS
/// notification and the in-app toast so the two never drift apart.
({String title, String body}) orderNotificationText(OrderEventDto event) {
  final d = event.data;
  return switch (event.eventType) {
    'order.created' => (
        title: 'New order #${d.id}',
        body:
            '${d.items.length} item${d.items.length == 1 ? '' : 's'} · ${d.currency} ${d.total.toStringAsFixed(2)}',
      ),
    'order.cancelled' => (title: 'Order #${d.id} cancelled', body: ''),
    _ => (title: 'Order #${d.id} updated', body: 'Status: ${d.status}'),
  };
}

/// One local (device-level) notification per received live-order event —
/// separate from the in-app toast, so a new order is visible even when the app
/// isn't in the foreground. Every call is best-effort: a failure here
/// (permission denied, plugin not initialized) must never affect the live feed.
@lazySingleton
class OrderNotificationsService {
  OrderNotificationsService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'live_orders';
  static const _channelName = 'Live orders';
  static const _channelDescription =
      'New and updated orders from your storefront';

  /// Call once from `bootstrap()` before `runApp` — sets up the Android
  /// notification channel and requests the Android 13+ runtime permission.
  Future<void> initialize() async {
    try {
      const androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        ),
      );

      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
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

  /// Shows one notification for [event]. Best-effort; never throws.
  Future<void> notify(OrderEventDto event) async {
    final (:title, :body) = orderNotificationText(event);
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
