import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../enums/payment_method.dart';
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

  Future<PosTerminalDto> updateMyTerminal({
    required String legalName,
    required String address,
    required String tinNumber,
    required PaymentMethod paymentMethod,
    String? paymentNumber,
  }) async {
    final response = await _secureClient.patch<dynamic>(
      '/api/v1/pos-terminals/my-terminal',
      data: {
        'legalName': legalName,
        'address': address,
        'tinNumber': tinNumber,
        'paymentMethod': paymentMethod.toValue(),
        'paymentNumber': paymentNumber,
      },
    );
    final json = jsonEncode(response.data);
    return PosTerminalDto.fromJson(json);
  }

  Future<PosTerminalDto> registerMyTerminal({
    required String legalName,
    required String address,
    required String tinNumber,
    required PaymentMethod paymentMethod,
    String? paymentNumber,
  }) async {
    final response = await _secureClient.post<dynamic>(
      '/api/v1/pos-terminals/register',
      data: {
        'legalName': legalName,
        'address': address,
        'tinNumber': tinNumber,
        'paymentMethod': paymentMethod.toValue(),
        if (paymentNumber != null) 'paymentNumber': paymentNumber,
      },
    );
    final json = jsonEncode(response.data);
    return PosTerminalDto.fromJson(json);
  }
}
