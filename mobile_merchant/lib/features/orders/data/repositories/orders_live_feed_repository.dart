import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A single WebSocket connection attempt. `ready` resolves once the handshake
/// succeeds (or throws), so callers can distinguish "dead network" from
/// "still connecting" instead of hanging indefinitely.
class OrdersSocketSession {
  OrdersSocketSession(this._channel, this.messages);

  final WebSocketChannel _channel;

  /// Raw string messages arriving on the socket.
  final Stream<String> messages;

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
    final messages = channel.stream
        .where((raw) => raw is String)
        .cast<String>();

    unawaited(
      channel.ready.then(
        (_) => debugPrint('[OrdersFeed] connected (uri: $uri)'),
        onError: (_) {},
      ),
    );

    return OrdersSocketSession(channel, messages);
  }
}
