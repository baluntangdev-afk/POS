import 'dart:typed_data';

import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/device_transfer_dto.dart';
import '../repositories/device_transfer_repository.dart';

/// Mutation handles the export/import dialogs watch for pending/error/success.
class DeviceTransferNotifier {
  const DeviceTransferNotifier._();

  static final exportAction = Mutation<Uint8List>();
  static final importAction = Mutation<DeviceImportSummaryDto>();
}

final deviceTransferControllerProvider = Provider<DeviceTransferController>((ref) {
  return DeviceTransferController(ref.watch(deviceTransferRepositoryProvider));
});

/// Retrieved inside a [Mutation] via `txn.get(deviceTransferControllerProvider)`.
class DeviceTransferController {
  const DeviceTransferController(this._repository);

  final DeviceTransferRepository _repository;

  Future<Uint8List> export(String passphrase) =>
      _repository.exportArchive(passphrase);

  Future<DeviceImportSummaryDto> import({
    required Uint8List bytes,
    required String fileName,
    required String passphrase,
    bool partialRestore = false,
  }) =>
      _repository.importArchive(
        bytes: bytes,
        fileName: fileName,
        passphrase: passphrase,
        partialRestore: partialRestore,
      );
}
