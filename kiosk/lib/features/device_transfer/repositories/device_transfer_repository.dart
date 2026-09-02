import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/device_transfer_dto.dart';
import '../../../data/backend_api/sources/device_transfer_api.dart';

final deviceTransferRepositoryProvider = Provider<DeviceTransferRepository>((ref) {
  return DeviceTransferRepository(ref.watch(deviceTransferApiProvider));
});

/// Thin wrapper over [DeviceTransferApi] so the view layer never touches the
/// HTTP source directly (matches the other feature repositories).
class DeviceTransferRepository {
  const DeviceTransferRepository(this._api);

  final DeviceTransferApi _api;

  Future<Uint8List> exportArchive(String passphrase) =>
      _api.export(passphrase: passphrase);

  Future<DeviceImportSummaryDto> importArchive({
    required Uint8List bytes,
    required String fileName,
    required String passphrase,
    bool partialRestore = false,
  }) =>
      _api.import(
        archiveBytes: bytes,
        fileName: fileName,
        passphrase: passphrase,
        partialRestore: partialRestore,
      );
}
