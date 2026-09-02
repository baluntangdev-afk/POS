import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../api_clients.dart';
import '../schemas/device_transfer_dto.dart';

final deviceTransferApiProvider = Provider<DeviceTransferApi>((ref) {
  return DeviceTransferApi(ref.watch(secureApiClientProvider));
});

/// Talks to the backend `device-transfer` module: export streams an encrypted
/// `.posbackup` archive; import uploads one and returns a restore summary.
class DeviceTransferApi {
  const DeviceTransferApi(this._client);

  final Dio _client;

  Future<Uint8List> export({required String passphrase}) async {
    final response = await _client.post<List<int>>(
      '/api/v1/device-transfer/export',
      data: {'passphrase': passphrase},
      options: Options(
        responseType: ResponseType.bytes,
        // Reading every table can take a while on a large store.
        receiveTimeout: const Duration(minutes: 10),
        sendTimeout: const Duration(minutes: 2),
      ),
    );
    return Uint8List.fromList(response.data ?? const <int>[]);
  }

  Future<DeviceImportSummaryDto> import({
    required Uint8List archiveBytes,
    required String fileName,
    required String passphrase,
    bool partialRestore = false,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(archiveBytes, filename: fileName),
      'passphrase': passphrase,
      'confirmReplace': 'true',
      'partialRestore': partialRestore ? 'true' : 'false',
    });
    final response = await _client.post<dynamic>(
      '/api/v1/device-transfer/import',
      data: formData,
      options: Options(
        receiveTimeout: const Duration(minutes: 10),
        sendTimeout: const Duration(minutes: 10),
      ),
    );
    return DeviceImportSummaryDto.fromJson(jsonEncode(response.data));
  }
}
