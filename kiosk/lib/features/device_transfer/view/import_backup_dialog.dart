import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../data/backend_api/schemas/device_transfer_dto.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/physical_keyboard_detector.dart';
import '../../../utils/windows_touch_keyboard.dart';
import '../../../widgets/button.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/onscreen_keyboard/keyboard_suppress.dart';
import '../../../widgets/onscreen_keyboard/onscreen_keyboard.dart';
import '../../../widgets/supervisor_authorization_dialog.dart';
import '../state/device_transfer_notifier.dart';

const _confirmWord = 'REPLACE';

/// One-paragraph note listing what a partial restore left behind, or '' when
/// everything came across.
String _skippedSummary(ImportSkippedDto skipped) {
  if (skipped.isEmpty) return '';

  String list(Iterable<String> names, int total) {
    final shown = names.take(6).join(', ');
    return total > 6 ? '$shown +${total - 6} more' : shown;
  }

  final lines = <String>['Not imported (different app version):'];
  if (skipped.tables.isNotEmpty) {
    lines.add(
      '• ${skipped.tables.length} table(s): '
      '${list(skipped.tables.map((t) => t.name), skipped.tables.length)}',
    );
  }
  if (skipped.columns.isNotEmpty) {
    lines.add(
      '• ${skipped.columns.length} column(s): '
      '${list(skipped.columns.map((c) => '${c.table}.${c.column}'), skipped.columns.length)}',
    );
  }
  return '${lines.join('\n')}\n\n';
}

Future<void> showImportBackupDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const ImportBackupDialog(),
  );
}

class ImportBackupDialog extends HookConsumerWidget {
  const ImportBackupDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final passphrase = useTextEditingController();
    final confirmWord = useTextEditingController();
    final obscure = useState(true);
    final fileName = useState<String?>(null);
    final fileBytes = useState<Uint8List?>(null);
    final error = useState<String?>(null);
    final partialRestore = useState(false);
    final hasPhysicalKeyboard = useValueListenable(PhysicalKeyboardDetector.attached);
    // rebuild when the confirm word changes so the button enables/disables
    useListenable(confirmWord);

    final action = DeviceTransferNotifier.importAction;
    final status = ref.watch(action);
    final isBusy = status is MutationPending;

    final canSubmit = !isBusy &&
        fileBytes.value != null &&
        passphrase.text.length >= 12 &&
        confirmWord.text.trim().toUpperCase() == _confirmWord;

    void runImport({required bool partial}) {
      action.run(ref, (txn) async {
        return txn.get(deviceTransferControllerProvider).import(
              bytes: fileBytes.value!,
              fileName: fileName.value!,
              passphrase: passphrase.text,
              partialRestore: partial,
            );
      }).ignore();
    }

    ref.listen(action, (_, next) {
      if (next case MutationError(:final error)) {
        if (error is DioException && error.response?.statusCode == 409) {
          final data = error.response?.data;
          final serverMessage =
              data is Map ? data['message']?.toString() : null;
          showMessageDialog(
            context,
            type: DialogType.warning,
            title: 'Incompatible Backup',
            message: serverMessage ??
                'This backup was made on an incompatible app version and cannot be '
                    'restored on this device.',
            primaryButtonText: partialRestore.value ? 'OK' : 'Cancel',
            secondaryButtonText: partialRestore.value ? null : 'Partial restore',
            onSecondaryPressed: partialRestore.value
                ? null
                : () {
                    Navigator.of(context, rootNavigator: true).pop();
                    partialRestore.value = true;
                    runImport(partial: true);
                  },
          );
        } else {
          showNetworkErrorDialog(context, error: error);
        }
      }
      if (next case MutationSuccess(:final value)) {
        if (!context.mounted) return;
        // Capture the root navigator while the context is still valid; the
        // Sign Out handler runs after the dialog stack has changed.
        final rootNav = Navigator.of(context, rootNavigator: true);
        showMessageDialog(
          context,
          type: DialogType.success,
          title: 'Restore Complete',
          message:
              '${value.totalRowsRestored} records were restored from the backup '
              '(created ${value.manifest.createdAt.split('T').first}).\n\n'
              '${_skippedSummary(value.skipped)}'
              'You will be signed out now. If anything looks incomplete, restart '
              'the device.',
          primaryButtonText: 'Sign Out',
          onPrimaryPressed: () {
            rootNav.pop(); // close this success dialog
            rootNav.pop(); // close the import dialog
            const LoginRoute().go(rootNav.context);
          },
        );
      }
    });

    Future<void> pickFile() async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['posbackup'],
        withData: true,
      );
      final file = result?.files.single;
      if (file?.bytes == null) return;
      fileName.value = file!.name;
      fileBytes.value = file.bytes;
    }

    Future<void> submit() async {
      error.value = null;
      final authorized = await SupervisorAuthorizationDialog.show(
        context,
        title: 'Authorize Restore',
        warningMessage:
            'Restoring a backup permanently replaces all data on this device and '
            'requires admin or supervisor authorization.',
        ctaLabel: 'Authorize Restore',
        ctaIcon: Icons.settings_backup_restore_rounded,
      );
      if (authorized == null) return;

      runImport(partial: partialRestore.value);
    }

    return Dialog(
      backgroundColor: ColorSet.light,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.value(kiosk: 28.0, tablet: 22.0, phone: 16.0)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: r.value(kiosk: 540.0, tablet: 460.0, phone: 360.0),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(r.value(kiosk: 28, tablet: 22, phone: 16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Import & Restore',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: r.value(kiosk: 24.0, tablet: 20.0, phone: 17.0),
                  fontWeight: FontWeight.w800,
                  color: POSColors.textPrimary,
                ),
              ),
              const Gap(16),
              Container(
                padding: EdgeInsets.all(r.value(kiosk: 14, tablet: 12, phone: 10)),
                decoration: BoxDecoration(
                  color: ColorSet.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(POSRadius.md),
                  border: Border.all(color: ColorSet.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_rounded, color: ColorSet.danger, size: 20),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        'This permanently replaces ALL data on this device — every user, '
                        'transaction, product, report and setting. The current data cannot '
                        'be recovered afterwards.',
                        style: TextStyle(
                          fontSize: r.value(kiosk: 12.0, tablet: 11.0, phone: 10.0),
                          color: ColorSet.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(18),
              Button.outlined(
                foregroundColor: POSColors.textPrimary,
                leading: const Icon(Icons.attach_file_rounded),
                onPressed: isBusy ? null : pickFile,
                label: Text(fileName.value ?? 'Choose backup file (.posbackup)'),
              ),
              const Gap(12),
              TextField(
                controller: passphrase,
                obscureText: obscure.value,
                enabled: !isBusy,
                autocorrect: false,
                enableSuggestions: false,
                readOnly: KeyboardSuppress.readOnly(hasPhysicalKeyboard),
                showCursor: KeyboardSuppress.showCursor(hasPhysicalKeyboard),
                keyboardType: KeyboardSuppress.type(null, hasPhysicalKeyboard),
                contextMenuBuilder: KeyboardSuppress.contextMenuBuilder(hasPhysicalKeyboard),
                onTap: KeyboardSuppress.onTap,
                onTapOutside: (_) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  OnScreenKeyboard.hide();
                  WindowsTouchKeyboard.dismiss();
                },
                decoration: InputDecoration(
                  labelText: 'Backup passphrase',
                  filled: true,
                  fillColor: POSColors.surfaceSubtle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(POSRadius.md),
                    borderSide: const BorderSide(color: POSColors.borderDefault),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => obscure.value = !obscure.value,
                    icon: Icon(obscure.value
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded),
                  ),
                ),
              ),
              const Gap(12),
              TextField(
                controller: confirmWord,
                enabled: !isBusy,
                textCapitalization: TextCapitalization.characters,
                readOnly: KeyboardSuppress.readOnly(hasPhysicalKeyboard),
                showCursor: KeyboardSuppress.showCursor(hasPhysicalKeyboard),
                keyboardType: KeyboardSuppress.type(null, hasPhysicalKeyboard),
                contextMenuBuilder: KeyboardSuppress.contextMenuBuilder(hasPhysicalKeyboard),
                onTap: KeyboardSuppress.onTap,
                onTapOutside: (_) {
                  FocusManager.instance.primaryFocus?.unfocus();
                  OnScreenKeyboard.hide();
                  WindowsTouchKeyboard.dismiss();
                },
                decoration: InputDecoration(
                  labelText: 'Type $_confirmWord to confirm',
                  filled: true,
                  fillColor: POSColors.surfaceSubtle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(POSRadius.md),
                    borderSide: const BorderSide(color: POSColors.borderDefault),
                  ),
                ),
              ),
              const Gap(12),
              Container(
                padding: EdgeInsets.all(r.value(kiosk: 14, tablet: 12, phone: 10)),
                decoration: BoxDecoration(
                  color: POSColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(POSRadius.md),
                  border: Border.all(color: POSColors.borderDefault),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Partial restore',
                            style: TextStyle(
                              fontSize: r.value(kiosk: 14.0, tablet: 13.0, phone: 12.0),
                              fontWeight: FontWeight.w700,
                              color: POSColors.textPrimary,
                            ),
                          ),
                          const Gap(2),
                          Text(
                            'Import only the data both devices have in common. Use '
                            'when the backup is from a different app version.',
                            style: TextStyle(
                              fontSize: r.value(kiosk: 11.0, tablet: 10.5, phone: 10.0),
                              color: POSColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(8),
                    Switch(
                      value: partialRestore.value,
                      onChanged: isBusy ? null : (v) => partialRestore.value = v,
                      activeThumbColor: ColorSet.primary,
                    ),
                  ],
                ),
              ),
              if (isBusy) ...[
                const Gap(16),
                Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        'Restoring — do not close the app…',
                        style: TextStyle(
                          fontSize: r.value(kiosk: 13.0, tablet: 12.0, phone: 11.0),
                          color: POSColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const Gap(22),
              Row(
                children: [
                  Expanded(
                    child: Button.outlined(
                      foregroundColor: POSColors.textSecondary,
                      onPressed: isBusy ? null : () => Navigator.of(context).pop(),
                      label: const Text('Cancel'),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Button(
                      backgroundColor: ColorSet.danger,
                      foregroundColor: ColorSet.light,
                      onPressed: canSubmit ? submit : null,
                      label: Text(isBusy ? 'Restoring…' : 'Replace All Data'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
