import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../entities/order_event.dart';

/// The board's visual status categories. Cancellation is read from
/// [OrderEventType], not [OrderData.status] — the local DAO's pending-count
/// query (see `order_events_dao.dart`) already treats "latest event is a
/// cancellation" as the source of truth for cancelled, independently of
/// whatever the free-text `status` field says.
enum OrderCardStatus { pending, preparing, ready, completed, cancelled, unknown }

OrderCardStatus classifyOrderStatus(OrderEvent event) {
  if (event.type == OrderEventType.cancelled) return OrderCardStatus.cancelled;
  switch (event.data.status.toLowerCase()) {
    case 'pending':
      return OrderCardStatus.pending;
    case 'preparing':
      return OrderCardStatus.preparing;
    case 'ready':
      return OrderCardStatus.ready;
    case 'completed':
      return OrderCardStatus.completed;
    default:
      return OrderCardStatus.unknown;
  }
}

/// Display label + color for a status pill. [OrderCardStatus.preparing] is
/// rendered as a dot-progress indicator instead (see `OrderStatusIndicator`),
/// so it has no pill entry here.
(String, Color) orderStatusPillStyle(OrderCardStatus status) => switch (status) {
  OrderCardStatus.pending => ('Pending', ColorSet.warning),
  OrderCardStatus.ready => ('Ready', ColorSet.success),
  OrderCardStatus.completed => ('Completed', ColorSet.success),
  OrderCardStatus.cancelled => ('Cancelled', ColorSet.danger),
  OrderCardStatus.preparing => ('Preparing', ColorSet.warning),
  // Backend sent a status string outside the known set — show it verbatim
  // rather than hiding it, so nothing silently disappears from the board.
  OrderCardStatus.unknown => ('Unknown', ColorSet.text),
};
