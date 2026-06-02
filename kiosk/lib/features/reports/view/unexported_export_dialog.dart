// kiosk/lib/features/reports/view/unexported_export_dialog.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../styles/color_set.dart';
import '../../../theme/pos_design.dart';
import '../state/export_notifier.dart';

class UnexportedExportDialog extends ConsumerWidget {
  const UnexportedExportDialog({
    super.key,
    required this.date,
    required this.count,
  });

  final DateTime date;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(exportNotifierProvider);

    ref.listen<ExportState>(exportNotifierProvider, (prev, next) {
      if ((prev?.isExporting ?? false) && !next.isExporting && next.exportError == null) {
        Navigator.of(context).pop();
      }
    });

    final dateLabel = DateFormat('MMM d').format(date);
    final isExporting = exportState.isExporting;
    final hasError = exportState.exportError != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(POSRadius.xl),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorSet.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(POSRadius.sm),
            ),
            child: Icon(Icons.warning_amber_rounded, color: ColorSet.danger, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            'Unexported Transactions',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$dateLabel has $count transaction${count == 1 ? '' : 's'} that '
            'have not been exported yet.',
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 8),
          const Text(
            'You must export yesterday\'s report before accessing the Reports screen.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          if (hasError) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ColorSet.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(POSRadius.sm),
              ),
              child: Text(
                'Export failed: ${exportState.exportError}',
                style: TextStyle(color: ColorSet.danger, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
      actions: [
        FilledButton.icon(
          onPressed: isExporting
              ? null
              : () => ref.read(exportNotifierProvider.notifier).export(date),
          icon: isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.file_download_outlined),
          label: Text(
            isExporting
                ? 'Exporting…'
                : (hasError ? 'Retry Export' : 'Export Now'),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: ColorSet.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(POSRadius.md),
            ),
          ),
        ),
      ],
    );
  }
}
