import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../entities/order_event.dart';

/// Pickup accent, darkened from [ColorSet.secondary] — the raw brand olive
/// (0xFFBCBE68) is too light to use as text/icon color at AA contrast.
const pickupAccent = Color(0xFF8E9143);

/// Delivery accent, darkened from [ColorSet.tertiary] for the same reason.
const deliveryAccent = Color(0xFF2E8FA1);

/// Accent for orders with no fulfillment type set (test/API orders only —
/// see [FulfillmentType] doc comment). Neutral so it doesn't compete with
/// the other fulfillment types.
const otherAccent = Color(0xFF7A7666);

/// Sidebar/filter selection for the Orders screen. Distinct from
/// [FulfillmentType] because it adds the "All" option and folds
/// [FulfillmentType.other] (and orders with no fulfillment type at all —
/// `/api/test/*` orders, see [FulfillmentType] doc comment) into a single
/// [other] bucket.
enum OrdersFilter { all, onSite, pickup, delivery, other }

bool orderMatchesFilter(OrdersFilter filter, FulfillmentType? type) {
  final normalized = type == FulfillmentType.other ? null : type;
  return switch (filter) {
    OrdersFilter.all => true,
    OrdersFilter.onSite => normalized == FulfillmentType.onSite,
    OrdersFilter.pickup => normalized == FulfillmentType.pickup,
    OrdersFilter.delivery => normalized == FulfillmentType.delivery,
    OrdersFilter.other => normalized == null,
  };
}

class OrderFulfillmentSpec {
  const OrderFulfillmentSpec({required this.filter, required this.label, required this.icon, required this.accentColor});

  final OrdersFilter filter;
  final String label;
  final IconData icon;
  final Color accentColor;
}

/// All specs in nav order. [OrdersFilter.other] is included unconditionally
/// here — callers building the visible nav list should drop it when its
/// count is zero, so it never shows up in normal operation.
const kOrderFulfillmentSpecs = [
  OrderFulfillmentSpec(filter: OrdersFilter.all, label: 'All', icon: Icons.grid_view_rounded, accentColor: ColorSet.primary),
  OrderFulfillmentSpec(
    filter: OrdersFilter.onSite,
    label: 'On-Site',
    icon: Icons.storefront_rounded,
    accentColor: ColorSet.primary,
  ),
  OrderFulfillmentSpec(filter: OrdersFilter.pickup, label: 'Pickup', icon: Icons.shopping_bag_rounded, accentColor: pickupAccent),
  OrderFulfillmentSpec(
    filter: OrdersFilter.delivery,
    label: 'Delivery',
    icon: Icons.delivery_dining_rounded,
    accentColor: deliveryAccent,
  ),
  OrderFulfillmentSpec(filter: OrdersFilter.other, label: 'Other', icon: Icons.help_outline_rounded, accentColor: otherAccent),
];
