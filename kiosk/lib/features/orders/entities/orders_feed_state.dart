import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import 'order_event.dart';

part 'orders_feed_state.mapper.dart';

/// Caps how many recent events the feed keeps in memory. Older events fall
/// off — this is a live notification feed, not a source of truth (that's
/// still the REST order history, once it exists).
const ordersFeedMaxEvents = 100;

@MappableEnum()
enum OrdersFeedConnection { disconnected, connecting, connected, reconnecting }

@MappableClass()
class OrdersFeedState with OrdersFeedStateMappable {
  const OrdersFeedState({
    required this.connection,
    this.events = const IList.empty(),
  });

  final OrdersFeedConnection connection;
  final IList<OrderEvent> events;
}
