import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/order_event_dto.dart';

const _pingInterval = Duration(seconds: 20);

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

class OrdersSocketSession {
  OrdersSocketSession(this._channel, this.events);

  final WebSocketChannel _channel;

  final Stream<OrderEventDto> events;

  Future<void> get ready => _channel.ready;

  int? get closeCode => _channel.closeCode;

  String? get closeReason => _channel.closeReason;

  Future<void> close() => _channel.sink.close();
}

class OrdersLiveFeedRepository {
  const OrdersLiveFeedRepository(this._wsBaseUrl);

  final String _wsBaseUrl;

  OrdersSocketSession connect(String merchantId, {String? bearerToken}) {
    final uri = Uri.parse(
      '$_wsBaseUrl/ws',
    ).replace(queryParameters: {'merchant_id': merchantId});
    debugPrint(
      '[OrdersFeed] handshake — uri: $uri | bearer: '
      '${bearerToken == null ? 'NONE' : _peekJwt(bearerToken)}',
    );
    final channel = IOWebSocketChannel.connect(
      uri,
      headers: bearerToken == null
          ? null
          : {'Authorization': 'Bearer $bearerToken'},
      pingInterval: _pingInterval,
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

  static String _peekJwt(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return 'len=${jwt.length} (not a JWT)';
      var p = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      p = p.padRight((p.length + 3) & ~3, '=');
      final claims = jsonDecode(utf8.decode(base64.decode(p)));
      return 'len=${jwt.length} claims=$claims';
    } catch (e) {
      return 'len=${jwt.length} (undecodable: $e)';
    }
  }
}
