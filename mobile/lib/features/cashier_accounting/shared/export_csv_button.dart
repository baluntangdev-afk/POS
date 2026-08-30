import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/csv/report_csv_exporter.dart';

/// Reusable AppBar action that triggers an encrypted CSV export.
/// Hidden when [periodStart] is null (no transactions in period yet).
class ExportCsvButton extends HookConsumerWidget {
  const ExportCsvButton({
    super.key,
    required this.periodStart,
    required this.onExport,
  });

  final DateTime? periodStart;

  /// Called with the exporter; must return the saved filename on success.
  final Future<String> Function(ReportCsvExporter exporter) onExport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (periodStart == null) return const SizedBox.shrink();

    final isExporting = useState(false);

    return IconButton(
      icon: isExporting.value
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download),
      tooltip: 'Export CSV',
      onPressed: isExporting.value
          ? null
          : () async {
              isExporting.value = true;
              try {
                final exporter = ref.read(reportCsvExporterProvider);
                final filename = await onExport(exporter);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved to Downloads/$filename')),
                  );
                }
              } on Exception {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export failed — check storage space'),
                    ),
                  );
                }
              } finally {
                isExporting.value = false;
              }
            },
    );
  }
}
