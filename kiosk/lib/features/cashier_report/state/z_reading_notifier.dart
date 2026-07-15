import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/sources/pos_terminals_api.dart';
import '../../../services/printer/win32_printer.dart';
import '../entities/z_reading.dart';
import '../repositories/cashier_report_repository.dart';
import '../use_cases/encode_esc_pos_z_reading.dart';

final zReadingNotifierProvider =
    NotifierProvider.autoDispose<ZReadingNotifier, AsyncValue<ZReading?>>(
      ZReadingNotifier.new,
      name: 'zReadingNotifierProvider',
    );

class ZReadingNotifier extends Notifier<AsyncValue<ZReading?>> {
  static final printAction = Mutation<void>();

  @override
  AsyncValue<ZReading?> build() => const AsyncValue.data(null);

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(cashierReportRepositoryProvider);
      final report = await repository.getZReading();
      state = AsyncValue.data(report);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Closes the current store-wide unreported window under the given supervisor/admin
  /// credentials (already verified client-side by [SupervisorAuthorizationDialog]; the backend
  /// re-verifies them before mutating anything) and prints the resulting closed report.
  Future<void> close({required String authorizerId, required String pin}) async {
    final report = state.value;
    if (report == null || report.periodStart == null) return;

    final repository = ref.read(cashierReportRepositoryProvider);
    final closed = await repository.closeZReading(authorizerId: authorizerId, pin: pin);
    state = AsyncValue.data(closed);
    await printReport(closed);
  }

  /// Re-prints an already-closed report (from history) without touching the backend.
  Future<void> reprint(ZReading report) => printReport(report);

  Future<void> printReport(ZReading report) async {
    if (kIsWeb || !Platform.isWindows) return;

    final terminal = await ref.read(posTerminalsApiProvider).getMyTerminal();
    final encode = ref.read(encodeEscPosZReadingProvider);
    final data = await encode(report: report, terminal: terminal);

    final printerTransport = ref.read(win32PrinterTransportProvider);
    await printerTransport.sendData(data);
  }
}
