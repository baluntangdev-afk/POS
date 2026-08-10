import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/pos_terminal_dto.dart';
import '../../../data/backend_api/sources/pos_terminals_api.dart';
import '../../../services/device/device_serial_number.dart';
import '../../../services/history/history_archive_service.dart';
import '../../../services/printer/win32_printer.dart';
import '../entities/cashier_daily_report.dart';
import '../repositories/cashier_report_repository.dart';
import '../use_cases/encode_esc_pos_cashier_daily_report.dart';
import '../use_cases/render_cashier_daily_report_pdf.dart';

final cashierDailyReportNotifierProvider =
    NotifierProvider.autoDispose<CashierDailyReportNotifier, AsyncValue<CashierDailyReport?>>(
      CashierDailyReportNotifier.new,
      name: 'cashierDailyReportNotifierProvider',
    );

class CashierDailyReportNotifier extends Notifier<AsyncValue<CashierDailyReport?>> {
  static final printAction = Mutation<void>();

  @override
  AsyncValue<CashierDailyReport?> build() => const AsyncValue.data(null);

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(cashierReportRepositoryProvider);
      final report = await repository.getDailyReport();
      state = AsyncValue.data(report);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Closes the current unreported window (persists a snapshot, marks the covered
  /// transactions as reported) and prints the resulting closed report.
  Future<void> print() async {
    final report = state.value;
    if (report == null || report.periodStart == null) return;

    final repository = ref.read(cashierReportRepositoryProvider);
    final closed = await repository.closeDailyReport();
    state = AsyncValue.data(closed);
    await printReport(closed);
  }

  /// Re-prints an already-closed report (from history) without touching the backend.
  Future<void> reprint(CashierDailyReport report) => printReport(report);

  Future<void> printReport(CashierDailyReport report) async {
    if (kIsWeb || !Platform.isWindows) return;

    final terminal = await ref.read(posTerminalsApiProvider).getMyTerminal();
    final serialNumber = await ref.read(deviceSerialNumberProvider.future);
    final encode = ref.read(encodeEscPosCashierDailyReportProvider);
    final data = await encode(report: report, terminal: terminal, serialNumber: serialNumber);

    final printerTransport = ref.read(win32PrinterTransportProvider);
    await printerTransport.sendData(data);

    await _saveToHistory(report: report, terminal: terminal, serialNumber: serialNumber);
  }

  // Archiving must never block printing -- a History write failure (disk full,
  // permissions) is a nice-to-have lookup lost, not a reason to fail closing the report.
  Future<void> _saveToHistory({
    required CashierDailyReport report,
    required PosTerminalDto terminal,
    String? serialNumber,
  }) async {
    try {
      final renderPdf = ref.read(renderCashierDailyReportPdfProvider);
      final bytes = await renderPdf(report: report, terminal: terminal, serialNumber: serialNumber);
      final timestamp = report.reportGeneratedAt.toLocal().toIso8601String().replaceAll(':', '-');
      await ref
          .read(historyArchiveServiceProvider)
          .save(
            fileName: 'dailyreport_$timestamp.pdf',
            bytes: bytes,
            at: report.reportGeneratedAt,
          );
    } catch (_) {
      // Non-fatal, see comment above.
    }
  }
}
