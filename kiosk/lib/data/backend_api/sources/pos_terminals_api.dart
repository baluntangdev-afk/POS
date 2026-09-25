import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../enums/payment_method.dart';
import '../schemas/payment_method_entry_dto.dart';
import '../schemas/pos_terminal_dto.dart';

final posTerminalsApiProvider = Provider<PosTerminalsApi>((ref) {
  final secureClient = ref.watch(secureApiClientProvider);
  return PosTerminalsApi(secureClient);
});

class PosTerminalsApi {
  const PosTerminalsApi(this._secureClient);

  final Dio _secureClient;

  Future<PosTerminalDto> getMyTerminal() async {
    final response = await _secureClient.get<dynamic>('/api/v1/pos-terminals/my-terminal');
    final json = jsonEncode(response.data);
    return PosTerminalDto.fromJson(json);
  }

  /// Partial update — only the fields passed are sent.
  Future<PosTerminalDto> updateMyTerminal({
    String? legalName,
    String? address,
    String? tinNumber,
    String? kioskId,
  }) async {
    final response = await _secureClient.patch<dynamic>(
      '/api/v1/pos-terminals/my-terminal',
      data: {
        if (kioskId != null) 'kioskId': kioskId,
        if (legalName != null) 'legalName': legalName,
        if (address != null) 'address': address,
        if (tinNumber != null) 'tinNumber': tinNumber,
      },
    );
    final json = jsonEncode(response.data);
    return PosTerminalDto.fromJson(json);
  }

  Future<PosTerminalDto> registerMyTerminal({
    required String kioskId,
    required String legalName,
    required String address,
    required String tinNumber,
  }) async {
    final response = await _secureClient.post<dynamic>(
      '/api/v1/pos-terminals/register',
      data: {
        'kioskId': kioskId,
        'legalName': legalName,
        'address': address,
        'tinNumber': tinNumber,
      },
    );
    final json = jsonEncode(response.data);
    return PosTerminalDto.fromJson(json);
  }

  Future<PaymentMethodEntryDto> addPaymentMethod({
    required PaymentMethod paymentMethod,
    String? paymentMethodName,
    String? paymentNumber,
  }) async {
    final response = await _secureClient.post<dynamic>(
      '/api/v1/pos-terminals/my-terminal/payment-methods',
      data: {
        'paymentMethod': paymentMethod.toValue(),
        if (paymentMethodName != null) 'paymentMethodName': paymentMethodName,
        if (paymentNumber != null) 'paymentNumber': paymentNumber,
      },
    );
    final json = jsonEncode(response.data);
    return PaymentMethodEntryDto.fromJson(json);
  }

  Future<PaymentMethodEntryDto> updatePaymentMethod(
    int id, {
    PaymentMethod? paymentMethod,
    String? paymentMethodName,
    String? paymentNumber,
  }) async {
    final response = await _secureClient.patch<dynamic>(
      '/api/v1/pos-terminals/my-terminal/payment-methods/$id',
      data: {
        if (paymentMethod != null) 'paymentMethod': paymentMethod.toValue(),
        'paymentMethodName': paymentMethodName,
        'paymentNumber': paymentNumber,
      },
    );
    final json = jsonEncode(response.data);
    return PaymentMethodEntryDto.fromJson(json);
  }

  Future<void> removePaymentMethod(int id) async {
    await _secureClient.delete<void>(
      '/api/v1/pos-terminals/my-terminal/payment-methods/$id',
    );
  }
}
