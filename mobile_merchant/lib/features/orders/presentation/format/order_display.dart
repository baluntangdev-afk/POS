import '../../data/models/order_data_dto.dart';

/// The `Guest · On-site · Conference Meeting Hall` line shown under the order
/// number. Segments that don't apply are dropped rather than shown blank.
String orderSubtitle(OrderDataDto data) {
  final customer = (data.customerName?.isNotEmpty ?? false)
      ? data.customerName!
      : 'Guest';

  final fulfillment = switch (data.fulfillmentType) {
    FulfillmentType.onSite => (data.facilityName?.isNotEmpty ?? false)
        ? 'On-site · ${data.facilityName}'
        : 'On-site',
    FulfillmentType.pickup => 'Pickup',
    FulfillmentType.delivery => 'Delivery',
    FulfillmentType.other => null,
  };

  return [customer, fulfillment].whereType<String>().join(' · ');
}

/// A coarse `2m ago` / `3h ago` / `just now` relative timestamp.
String relativeOrderTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.isNegative || diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
