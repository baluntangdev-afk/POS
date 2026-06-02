// kiosk/lib/features/reports/state/export_notifier.dart
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../services/report_export_service.dart';

@immutable
class ExportState {
  const ExportState({
    this.isExporting = false,
    this.lastExportPath,
    this.exportError,
  });

  final bool isExporting;
  final String? lastExportPath;
  final String? exportError;

  ExportState copyWith({
    bool? isExporting,
    String? lastExportPath,
    String? exportError,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      lastExportPath: lastExportPath ?? this.lastExportPath,
      exportError: exportError ?? this.exportError,
    );
  }
}

final exportNotifierProvider = NotifierProvider<ExportNotifier, ExportState>(
  ExportNotifier.new,
);

class ExportNotifier extends Notifier<ExportState> {
  @override
  ExportState build() => const ExportState();

  Future<bool> export(DateTime date) async {
    state = const ExportState(isExporting: true);
    try {
      final service = ref.read(reportExportServiceProvider);
      final path = await service.exportDay(date);
      state = ExportState(lastExportPath: path);
      return true;
    } catch (e) {
      state = ExportState(exportError: e.toString());
      return false;
    }
  }
}
