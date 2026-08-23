import 'order_event.dart';

/// Caps how many recent events the feed keeps in memory. Older events fall
/// off — this is a live notification feed, not a source of truth (that's
/// the local `order_events` table / REST order history, once it exists).
const ordersFeedMaxEvents = 100;

enum OrdersFeedConnection { disconnected, connecting, connected, reconnecting }

class OrdersFeedState {
  const OrdersFeedState({
    required this.connection,
    this.events = const [],
    this.storeId,
  });

  final OrdersFeedConnection connection;
  final List<OrderEvent> events;
  final String? storeId;

  OrdersFeedState copyWith({
    OrdersFeedConnection? connection,
    List<OrderEvent>? events,
    String? storeId,
  }) {
    return OrdersFeedState(
      connection: connection ?? this.connection,
      events: events ?? this.events,
      storeId: storeId ?? this.storeId,
    );
  }
}
