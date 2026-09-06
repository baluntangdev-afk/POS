import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/models/order_event_dto.dart';

enum OrderCardStatus { pending, preparing, ready, cancelled, fulfilled, unknown }

/// Statuses a merchant can move an order to from the card.
/// [cancelled] is a separate confirmed action. [unknown] is not a valid target.
const assignableOrderStatuses = [
  OrderCardStatus.pending,
  OrderCardStatus.preparing,
  OrderCardStatus.ready,
  OrderCardStatus.fulfilled,
];

OrderCardStatus classifyStatus(OrderEventDto event) =>
    switch (event.data.status.toLowerCase()) {
      'pending' => OrderCardStatus.pending,
      'preparing' => OrderCardStatus.preparing,
      'ready' => OrderCardStatus.ready,
      'cancelled' => OrderCardStatus.cancelled,
      'fulfilled' => OrderCardStatus.fulfilled,
      _ => OrderCardStatus.unknown,
    };

(String, Color) statusStyle(OrderCardStatus status) => switch (status) {
      OrderCardStatus.pending => ('Pending', AppColors.warning),
      OrderCardStatus.preparing => ('Preparing', AppColors.warning),
      OrderCardStatus.ready => ('Ready', AppColors.success),
      OrderCardStatus.cancelled => ('Cancelled', AppColors.error),
      OrderCardStatus.fulfilled => ('Fulfilled', AppColors.primary),
      OrderCardStatus.unknown => ('Unknown', AppColors.textSecondary),
    };
