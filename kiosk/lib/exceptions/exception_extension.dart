import 'dart:convert';

import 'package:dio/dio.dart';

import 'app_exception.dart';

extension ExceptionExtension on Object {
  String get message {
    if (this is AppException) {
      final msg = (this as AppException).message;
      if (msg.isNotEmpty) return msg;
    }
    if (this is DioException) {
      final e = this as DioException;
      if (e.type == DioExceptionType.connectionError) {
        return 'No internet connection.';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return 'Request timed out. Please try again.';
      }

      // Try to extract backend message from response body.
      final fromResponse = _extractBackendMessage(e.response?.data);
      if (fromResponse != null) return fromResponse;

      // If interceptor swallowed the response (e.g. 401 token refresh flow),
      // the original error may be nested — try that too.
      final nested = e.error;
      if (nested is DioException) {
        final fromNested = _extractBackendMessage(nested.response?.data);
        if (fromNested != null) return fromNested;
      }

      return 'Something went wrong. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}

String? _extractBackendMessage(dynamic data) {
  Map<String, dynamic>? map;

  if (data is Map<String, dynamic>) {
    map = data;
  } else if (data is String && data.isNotEmpty) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) map = decoded;
    } catch (_) {}
  }

  if (map == null) return null;
  final msg = map['message']?.toString();
  if (msg != null && msg.isNotEmpty) return msg;
  final err = map['error']?.toString();
  if (err != null && err.isNotEmpty) return err;
  return null;
}
