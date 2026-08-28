import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../live_orders/entities/order_event.dart';

enum OrderCardStatus { pending, preparing, ready, cancelled, fulfilled, unknown }

/// Statuses staff can move an order to directly from a card. `cancelled` is
/// deliberately excluded — cancelling is a separate, confirmed action — as is
/// `unknown`, which isn't a real target.
const assignableOrderStatuses = [
  OrderCardStatus.pending,
  OrderCardStatus.preparing,
  OrderCardStatus.ready,
  OrderCardStatus.fulfilled,
];

extension OrderCardStatusWire on OrderCardStatus {
  /// The raw status string the webhook-receiver expects in an `updates`
  /// payload — the inverse of the switch in [classifyOrderStatus].
  String get rawValue => name;
}

OrderCardStatus classifyOrderStatus(OrderEvent event) {
  if (event.type == OrderEventType.cancelled) return OrderCardStatus.cancelled;
  switch (event.data.status.toLowerCase()) {
    case 'pending':
      return OrderCardStatus.pending;
    case 'preparing':
      return OrderCardStatus.preparing;
    case 'cancelled':
      return OrderCardStatus.cancelled;
    case 'ready':
      return OrderCardStatus.ready;
    case 'fulfilled':
      return OrderCardStatus.fulfilled;
    default:
      return OrderCardStatus.unknown;
  }
}

/// Display label + color for a status badge. Mirrors the kiosk app's
/// `orderStatusPillStyle` so status colors read consistently across both
/// apps.
(String, Color) orderStatusPillStyle(OrderCardStatus status) => switch (status) {
  OrderCardStatus.pending => ('Pending', AppColors.warning),
  OrderCardStatus.ready => ('Ready', AppColors.success),
  OrderCardStatus.cancelled => ('Cancelled', AppColors.error),
  OrderCardStatus.preparing => ('Preparing', AppColors.warning),
  OrderCardStatus.fulfilled => ('Fulfilled', AppColors.primary),
  // Backend sent a status string outside the known set — show it verbatim
  // rather than hiding it, so nothing silently disappears from the screen.
  OrderCardStatus.unknown => ('Unknown', AppColors.textSecondary),
};
