import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/order_event_dto.dart';

/// Parses one raw WebSocket frame into an [OrderEventDto]. Pure and top-level
/// so it is directly unit-testable. Non-string frames, invalid JSON, a
/// non-object payload, an unrecognized `event_type`, or a malformed `data`
/// object all yield `null` (logged, never thrown) — a bad frame must never
/// break the stream.
OrderEventDto? parseOrderEventFrame(Object? raw) {
  if (raw is! String) {
    debugPrint('[OrdersFeed] dropped non-string frame: $raw');
    return null;
  }
  final Map<String, dynamic> json;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      debugPrint('[OrdersFeed] dropped non-object frame: $raw');
      return null;
    }
    json = decoded;
  } catch (e) {
    debugPrint('[OrdersFeed] failed to decode frame: $raw ($e)');
    return null;
  }
  final event = OrderEventDto.fromWireJson(json);
  if (event == null) {
    debugPrint('[OrdersFeed] dropped unrecognized/unparseable frame: $raw');
  }
  return event;
}

/// A single WebSocket connection attempt. `ready` resolves once the handshake
/// succeeds (or throws), so callers can distinguish "dead network" from
/// "still connecting" instead of hanging indefinitely.
class OrdersSocketSession {
  OrdersSocketSession(this._channel, this.events);

  final WebSocketChannel _channel;

  /// Parsed order events arriving on the socket. Bad frames are already
  /// filtered out by [parseOrderEventFrame].
  final Stream<OrderEventDto> events;

  Future<void> get ready => _channel.ready;

  Future<void> close() => _channel.sink.close();
}

/// Opens a WebSocket connection to the orders feed endpoint. This is a single
/// attempt — the caller owns reconnect / backoff logic.
class OrdersLiveFeedRepository {
  const OrdersLiveFeedRepository(this._wsBaseUrl);

  final String _wsBaseUrl;

  /// Connects to `{wsBaseUrl}/ws?merchant_id={merchantId}` with [bearerToken]
  /// as the `Authorization: Bearer` handshake header.
  OrdersSocketSession connect(String merchantId, {String? bearerToken}) {
    final uri = Uri.parse('$_wsBaseUrl/ws').replace(
      queryParameters: {'merchant_id': merchantId},
    );
    final channel = IOWebSocketChannel.connect(
      uri,
      headers: bearerToken == null
          ? null
          : {'Authorization': 'Bearer $bearerToken'},
    );
    final events = channel.stream
        .map(parseOrderEventFrame)
        .where((e) => e != null)
        .cast<OrderEventDto>();

    unawaited(
      channel.ready.then(
        (_) => debugPrint('[OrdersFeed] connected (uri: $uri)'),
        onError: (_) {},
      ),
    );

    return OrdersSocketSession(channel, events);
  }
}
