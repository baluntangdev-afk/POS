import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../config/environment/app_env.dart';
import '../entities/order_event.dart';

final ordersLiveFeedRepositoryProvider = Provider<OrdersLiveFeedRepository>((ref) {
  final env = ref.watch(appEnvProvider);
  return OrdersLiveFeedRepositoryImpl(env.ordersLiveFeedWsUrl);
});

/// One connection attempt to the webhook-receiver's WS endpoint. `ready`
/// resolves once the socket is actually open (or throws), so callers can
/// tell a dead network apart from "still connecting" instead of hanging.
class OrdersSocketSession {
  OrdersSocketSession(this._channel, this.events);

  final WebSocketChannel _channel;
  final Stream<OrderEvent> events;

  Future<void> get ready => _channel.ready;

  Future<void> close() => _channel.sink.close();
}

abstract class OrdersLiveFeedRepository {
  /// Opens one WS connection scoped to [storeId] (sent as `merchant_id`).
  /// The caller owns reconnect/backoff — this is a single attempt.
  OrdersSocketSession connect(String storeId);
}

class OrdersLiveFeedRepositoryImpl implements OrdersLiveFeedRepository {
  const OrdersLiveFeedRepositoryImpl(this._baseUrl);

  final String _baseUrl;

  @override
  OrdersSocketSession connect(String storeId) {
    final uri = Uri.parse('${_wsUrl(_baseUrl)}/ws').replace(queryParameters: {'merchant_id': storeId});
    final channel = WebSocketChannel.connect(uri);
    final events = channel.stream
        .map((raw) => _parse(raw))
        .where((event) => event != null)
        .cast<OrderEvent>();
    final session = OrdersSocketSession(channel, events);
    unawaited(
      session.ready.then(
        (_) => debugPrint('[OrdersFeed] connected to $_baseUrl (uri: $uri)'),
        // The caller (OrdersFeedNotifier) already awaits `session.ready`
        // itself and handles the same failure via its try/catch — this
        // second listener exists only for the success-path debug log, so a
        // rejection here must be swallowed rather than left unhandled.
        onError: (_) {},
      ),
    );
    return session;
  }

  /// Accepts a base URL configured as `http(s)://` (e.g. copied straight
  /// from a browser/dashboard) or `ws(s)://` and normalizes it to a scheme
  /// `WebSocketChannel.connect` actually accepts — it throws on anything
  /// else, including plain `https:`.
  String _wsUrl(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    final scheme = switch (uri.scheme) {
      'https' => 'wss',
      'http' => 'ws',
      _ => uri.scheme,
    };
    return uri.replace(scheme: scheme).toString();
  }

  OrderEvent? _parse(Object? raw) {
    if (raw is! String) {
      debugPrint('[OrdersFeed] dropped non-string WS message: $raw');
      return null;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final type = OrderEventType.fromWire(json['event_type'] as String);
      if (type == null) {
        debugPrint('[OrdersFeed] dropped unrecognized event_type: ${json['event_type']}');
        return null;
      }
      return OrderEvent(
        eventId: json['event_id'] as String,
        type: type,
        data: OrderData.fromJson(json['data'] as Map<String, dynamic>),
      );
    } catch (e, st) {
      debugPrint('[OrdersFeed] failed to parse WS message: $raw\nerror: $e\n$st');
      return null;
    }
  }
}
