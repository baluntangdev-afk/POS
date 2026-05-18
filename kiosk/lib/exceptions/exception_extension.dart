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
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final serverMsg = data['message']?.toString() ?? data['error']?.toString();
        if (serverMsg != null && serverMsg.isNotEmpty) return serverMsg;
      }
      return 'An unexpected error occurred.';
    }
    return 'Unexpected error occurred.';
  }
}
