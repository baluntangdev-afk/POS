import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../widgets/button.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/network_error_dialog.dart';
import '../state/inventory_products_notifier.dart';

/// Exports every product to a CSV (same format as the Import CSV template) and
/// saves it where the user chooses. Renders icon-only when [compact] is true.
class ExportProductsCsvButton extends ConsumerWidget {
  const ExportProductsCsvButton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportAction = InventoryProductsNotifier.exportCsvAction;
    final isExporting = ref.watch(exportAction) is MutationPending;

    ref.listen(exportAction, (prev, next) {
      if (!context.mounted) return;
      if (next case MutationError(:final error)) {
        showNetworkErrorDialog(context, error: error);
      }
      if (next case MutationSuccess(value: final String path)) {
        showMessageDialog(
          context,
          title: 'Export Complete',
          message: 'Products were exported to:\n$path',
          type: DialogType.success,
        );
      }
    });

    void runExport() {
      exportAction.run(ref, (txn) async {
        final stamp = DateTime.now().toIso8601String().substring(0, 10);
        final path = await FilePicker.platform.saveFile(
          dialogTitle: 'Export products CSV',
          fileName: 'products-export-$stamp.csv',
          type: FileType.custom,
          allowedExtensions: ['csv'],
        );
        if (path == null) return null;
        final bytes = await txn.get(inventoryProductsProvider.notifier).exportCsv();
        await File(path).writeAsBytes(bytes);
        return path;
      }).ignore();
    }

    final onPressed = isExporting ? null : runExport;

    if (compact) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: EdgeInsets.zero,
        ),
        child: isExporting
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download_rounded, size: 20),
      );
    }

    return Button.outlined(
      label: Text(isExporting ? 'Exporting...' : 'Export CSV'),
      leading: const Icon(Icons.download_rounded),
      onPressed: onPressed,
    );
  }
}
