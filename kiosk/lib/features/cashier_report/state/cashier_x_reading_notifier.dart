import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/pos_terminal_dto.dart';
import '../../../data/backend_api/sources/pos_terminals_api.dart';
import '../../../services/printer/win32_printer.dart';
import '../entities/cashier_x_reading.dart';
import '../repositories/cashier_report_repository.dart';
import '../use_cases/encode_esc_pos_cashier_report.dart';

final cashierReportPosTerminalProvider = FutureProvider.autoDispose<PosTerminalDto>((ref) {
  return ref.watch(posTerminalsApiProvider).getMyTerminal();
}, name: 'cashierReportPosTerminalProvider');

final cashierXReadingNotifierProvider =
    NotifierProvider.autoDispose<CashierXReadingNotifier, AsyncValue<CashierXReading?>>(
      CashierXReadingNotifier.new,
      name: 'cashierXReadingNotifierProvider',
    );

class CashierXReadingNotifier extends Notifier<AsyncValue<CashierXReading?>> {
  static final printAction = Mutation<void>();

  @override
  AsyncValue<CashierXReading?> build() => const AsyncValue.data(null);

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(cashierReportRepositoryProvider);
      final report = await repository.getXReading();
      state = AsyncValue.data(report);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> print() async {
    final report = state.value;
    if (report == null) return;
    if (kIsWeb || !Platform.isWindows) return;

    final terminal = await ref.read(posTerminalsApiProvider).getMyTerminal();
    final encode = ref.read(encodeEscPosCashierReportProvider);
    final data = await encode(report: report, terminal: terminal);

    final printerTransport = ref.read(win32PrinterTransportProvider);
    await printerTransport.sendData(data);
  }
}
