import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../services/device/device_serial_number.dart';
import '../../../services/history/history_archive_service.dart';
import '../../../services/printer/win32_printer.dart';
import '../entities/receipt.dart';
import '../repositories/receipt_repository.dart';
import '../use_cases/encode_esc_pos_receipt.dart';
import '../use_cases/render_receipt_pdf.dart';

final receiptProvider = AsyncNotifierProvider.autoDispose.family<ReceiptNotifier, Receipt, String>(
  ReceiptNotifier.new,
  name: 'receiptProvider',
);

class ReceiptNotifier extends AsyncNotifier<Receipt> {
  ReceiptNotifier(this.receiptId);

  String receiptId;

  static final printAction = Mutation<void>();

  @override
  Future<Receipt> build() async {
    final repository = ref.watch(receiptRepositoryProvider);
    return repository.getById(receiptId);
  }

  Future<void> print() async {
    if (!state.hasValue) return;
    if (kIsWeb || !Platform.isWindows) return;

    final serialNumber = await ref.read(deviceSerialNumberProvider.future);
    final encodeReceipt = ref.read(encodeEscPosReceiptProvider);
    final data = await encodeReceipt(receipt: state.requireValue, serialNumber: serialNumber);

    final printerTransport = ref.read(win32PrinterTransportProvider);
    await printerTransport.sendData(data);

    await _saveToHistory(receipt: state.requireValue, serialNumber: serialNumber);
  }

  // Archiving must never block printing -- a History write failure (disk full,
  // permissions) is a nice-to-have lookup lost, not a reason to fail the sale.
  Future<void> _saveToHistory({required Receipt receipt, String? serialNumber}) async {
    try {
      final renderPdf = ref.read(renderReceiptPdfProvider);
      final bytes = await renderPdf(receipt: receipt, serialNumber: serialNumber);
      final safeDocNumber = receipt.docNumber.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
      await ref
          .read(historyArchiveServiceProvider)
          .save(fileName: 'receipt_$safeDocNumber.pdf', bytes: bytes, at: receipt.docDate);
    } catch (_) {
      // Non-fatal, see comment above.
    }
  }
}
