import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:web_socket_channel/io.dart';
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
  /// Opens one WS connection scoped to [kioskId] (sent as `merchant_id`),
  /// authenticated with the `/devices/token` [bearerToken] when given.
  /// The caller owns reconnect/backoff — this is a single attempt.
  OrdersSocketSession connect(String kioskId, {String? bearerToken});
}

class OrdersLiveFeedRepositoryImpl implements OrdersLiveFeedRepository {
  const OrdersLiveFeedRepositoryImpl(this._baseUrl);

  final String _baseUrl;

  @override
  OrdersSocketSession connect(String kioskId, {String? bearerToken}) {
    final uri = Uri.parse('${_wsUrl(_baseUrl)}/ws').replace(queryParameters: {'merchant_id': kioskId});
    // IOWebSocketChannel (not WebSocketChannel.connect) so the device bearer
    // can ride on the handshake as a header.
    final channel = IOWebSocketChannel.connect(
      uri,
      headers: bearerToken == null ? null : {'Authorization': 'Bearer $bearerToken'},
    );
    final events = channel.stream
        .map((raw) => _parse(raw))
        .where((event) => event != null)
        .cast<OrderEvent>();
    final session = OrdersSocketSession(channel, events);
    unawaited(
      session.ready.then(
        (_) => debugPrint('[OrdersFeed] connected to ORDERS_LIVE_FEED_WS_URL: $_baseUrl (uri: $uri)'),
        // The caller (OrdersFeedNotifier) already awaits `session.ready` and
        // handles the failure — this listener only exists for the success log,
        // so a rejection here must be swallowed rather than left unhandled.
        onError: (_) {},
      ),
    );
    return session;
  }

  /// Accepts a base URL configured as `http(s)://` or `ws(s)://` and
  /// normalizes it to a scheme the WS client accepts — it throws on anything
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
    Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
    } catch (e, st) {
      debugPrint('[OrdersFeed] failed to decode WS message: $raw\nerror: $e\n$st');
      return null;
    }
    final event = OrderEvent.fromWireJson(json);
    if (event == null) {
      debugPrint('[OrdersFeed] dropped unparseable/unrecognized WS message: $raw');
      return null;
    }
    debugPrint('RECEIVED LIVE DATA ${jsonEncode(json['data'])}');
    return event;
  }
}
