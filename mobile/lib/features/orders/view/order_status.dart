import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../live_orders/entities/order_event.dart';

enum OrderCardStatus { pending, preparing, ready, cancelled, fulfilled, unknown }

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
