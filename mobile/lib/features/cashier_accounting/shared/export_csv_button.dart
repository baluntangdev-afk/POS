import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../config/environment/app_env.dart';
import '../../../core/csv/report_csv_exporter.dart';

/// Reusable AppBar action that triggers a CSV export.
/// When [AppEnv.csvExportPassword] is non-empty a password dialog is shown
/// before the download proceeds.
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
              final requiredPassword = ref.read(appEnvProvider).csvExportPassword;

              if (requiredPassword.isNotEmpty) {
                final granted = await showExportPasswordDialog(context, requiredPassword);
                if (!granted) return;
              }

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

Future<bool> showExportPasswordDialog(BuildContext context, String requiredPassword) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _PasswordDialog(requiredPassword: requiredPassword),
      ) ??
      false;
}

class _PasswordDialog extends HookWidget {
  const _PasswordDialog({required this.requiredPassword});

  final String requiredPassword;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final obscure = useState(true);
    final error = useState<String?>(null);

    void submit() {
      if (controller.text == requiredPassword) {
        Navigator.of(context).pop(true);
      } else {
        error.value = 'Incorrect password';
      }
    }

    return AlertDialog(
      title: const Text('Enter Export Password'),
      content: TextField(
        controller: controller,
        obscureText: obscure.value,
        autofocus: true,
        onSubmitted: (_) => submit(),
        decoration: InputDecoration(
          labelText: 'Password',
          errorText: error.value,
          suffixIcon: IconButton(
            icon: Icon(obscure.value ? Icons.visibility : Icons.visibility_off),
            onPressed: () => obscure.value = !obscure.value,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: submit,
          child: const Text('Export'),
        ),
      ],
    );
  }
}
