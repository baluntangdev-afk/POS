import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../entities/order_event.dart';

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

/// Display label + color for a status pill. [OrderCardStatus.preparing] is
/// rendered as a dot-progress indicator instead (see `OrderStatusIndicator`),
/// so it has no pill entry here.
(String, Color) orderStatusPillStyle(OrderCardStatus status) => switch (status) {
  OrderCardStatus.pending => ('Pending', ColorSet.warning),
  OrderCardStatus.ready => ('Ready', ColorSet.success),
  OrderCardStatus.cancelled => ('Cancelled', ColorSet.danger),
  OrderCardStatus.preparing => ('Preparing', ColorSet.warning),
  OrderCardStatus.fulfilled => ('Fulfilled', ColorSet.button),
  // Backend sent a status string outside the known set — show it verbatim
  // rather than hiding it, so nothing silently disappears from the board.
  OrderCardStatus.unknown => ('Unknown', ColorSet.text),
};

/// Columns on the orders Kanban board, in board order. Mirrors
/// [OrderCardStatus] one-for-one; kept as a separate enum so the board's
/// column set can diverge from the raw status classification later (e.g.
/// splitting a status into multiple columns) without disturbing
/// [classifyOrderStatus] callers.
enum OrderKanbanColumn { pending, preparing, ready, fulfilled, cancelled, unknown }

OrderKanbanColumn kanbanColumnFor(OrderCardStatus status) => switch (status) {
  OrderCardStatus.pending => OrderKanbanColumn.pending,
  OrderCardStatus.preparing => OrderKanbanColumn.preparing,
  OrderCardStatus.ready => OrderKanbanColumn.ready,
  OrderCardStatus.fulfilled => OrderKanbanColumn.fulfilled,
  OrderCardStatus.cancelled => OrderKanbanColumn.cancelled,
  OrderCardStatus.unknown => OrderKanbanColumn.unknown,
};

/// Display label + accent color for a Kanban column header.
(String, Color) kanbanColumnStyle(OrderKanbanColumn column) => switch (column) {
  OrderKanbanColumn.pending => ('Pending', ColorSet.warning),
  OrderKanbanColumn.preparing => ('Preparing', ColorSet.warning),
  OrderKanbanColumn.ready => ('Ready', ColorSet.success),
  OrderKanbanColumn.fulfilled => ('Fulfilled', ColorSet.button),
  OrderKanbanColumn.cancelled => ('Cancelled', ColorSet.danger),
  OrderKanbanColumn.unknown => ('Unknown', ColorSet.text),
};

/// All columns in board order. [OrderKanbanColumn.unknown] should be dropped
/// by callers when it has no orders — same convention as
/// [OrdersFilter.other] in `order_fulfillment_spec.dart` — so it never shows
/// up in normal operation.
const kOrderKanbanColumns = [
  OrderKanbanColumn.pending,
  OrderKanbanColumn.preparing,
  OrderKanbanColumn.ready,
  OrderKanbanColumn.fulfilled,
  OrderKanbanColumn.cancelled,
  OrderKanbanColumn.unknown,
];
