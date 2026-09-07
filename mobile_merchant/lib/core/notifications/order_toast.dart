import 'package:flutter/material.dart';

import '../../features/orders/data/models/order_event_dto.dart';
import '../router/app_router.dart';
import '../services/notifications/order_notifications_service.dart';

/// Shows an in-app snackbar for one live order event, via the global
/// [appScaffoldMessengerKey]. Best-effort: if no messenger is mounted yet
/// (app still starting, or mid route-rebuild) this silently does nothing —
/// the OS notification still fires and the list still updates.
void showOrderToast(OrderEventDto event) {
  final messenger = appScaffoldMessengerKey.currentState;
  if (messenger == null) return;

  final (:title, :body) = orderNotificationText(event);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(body.isEmpty ? title : '$title · $body'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
}
