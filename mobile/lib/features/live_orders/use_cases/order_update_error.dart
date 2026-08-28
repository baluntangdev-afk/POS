import 'package:dio/dio.dart';

/// Why a manual `PATCH /merchant/orders/{id}` attempt failed, in terms the
/// Orders screen can show the user. Kept separate from the app-wide
/// [AppError] hierarchy — this is a feature-local concern with its own
/// HTTP-status mapping.
enum OrderUpdateError { invalidUpdates, unknownOrder, unauthorized, rateLimited, network, unknown }

/// Maps a failed update attempt to a UI-facing reason. A [DioException]
/// carrying one of the documented status codes maps directly; a transport
/// failure (no response at all) is [OrderUpdateError.network]; anything else
/// is [OrderUpdateError.unknown].
OrderUpdateError orderUpdateErrorFrom(Object error) {
  if (error is DioException) {
    switch (error.response?.statusCode) {
      case 400:
        return OrderUpdateError.invalidUpdates;
      case 401:
        return OrderUpdateError.unauthorized;
      case 404:
        return OrderUpdateError.unknownOrder;
      case 429:
        return OrderUpdateError.rateLimited;
    }
    if (error.response == null) return OrderUpdateError.network;
  }
  return OrderUpdateError.unknown;
}

extension OrderUpdateErrorMessage on OrderUpdateError {
  String get message => switch (this) {
    OrderUpdateError.invalidUpdates => 'That update isn\'t valid for this order.',
    OrderUpdateError.unknownOrder => 'This order is no longer available.',
    OrderUpdateError.unauthorized => 'Your session expired. Sign in again.',
    OrderUpdateError.rateLimited => 'Too many updates — wait a moment and try again.',
    OrderUpdateError.network => 'No connection. Check your network and try again.',
    OrderUpdateError.unknown => 'Couldn\'t update the order. Try again.',
  };
}
