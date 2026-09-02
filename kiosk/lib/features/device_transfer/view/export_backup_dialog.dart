import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

const _minPassphraseLength = 12;

Future<void> showExportBackupDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const ExportBackupDialog(),
  );
}

class ExportBackupDialog extends HookConsumerWidget {
  const ExportBackupDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final passphrase = useTextEditingController();
    final confirm = useTextEditingController();
    final obscure = useState(true);
    final error = useState<String?>(null);
    final hasPhysicalKeyboard = useValueListenable(PhysicalKeyboardDetector.attached);

    final action = DeviceTransferNotifier.exportAction;
    final status = ref.watch(action);
    final isBusy = status is MutationPending;

    Future<void> saveArchive(List<int> bytes) async {
      final now = DateTime.now();
      final stamp =
          '${now.year}${_two(now.month)}${_two(now.day)}-${_two(now.hour)}${_two(now.minute)}';
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save device backup',
        fileName: 'pos-kiosk-backup-$stamp.posbackup',
      );
      if (path == null) return; // user cancelled the save dialog
      await File(path).writeAsBytes(bytes);
      if (!context.mounted) return;
      // Show the confirmation on top of this dialog, then close this dialog —
      // so `context` stays valid throughout (popping it first would unmount it).
      await showMessageDialog(
        context,
        type: DialogType.success,
        title: 'Backup Saved',
        message:
            'The encrypted backup was saved to:\n$path\n\nKeep this file and its '
            'passphrase somewhere safe.',
      );
      if (!context.mounted) return;
      Navigator.of(context).pop();
    }

    ref.listen(action, (_, next) {
      if (next case MutationError(:final error)) {
        showNetworkErrorDialog(context, error: error);
      }
      if (next case MutationSuccess(:final value)) {
        saveArchive(value);
      }
    });

    Future<void> submit() async {
      error.value = null;
      final pass = passphrase.text;
      if (pass.length < _minPassphraseLength) {
        error.value = 'Passphrase must be at least $_minPassphraseLength characters.';
        return;
      }
      if (pass != confirm.text) {
        error.value = 'The two passphrases do not match.';
        return;
      }

      final authorized = await SupervisorAuthorizationDialog.show(
        context,
        title: 'Authorize Backup Export',
        warningMessage:
            'Exporting the full device dataset requires admin or supervisor authorization.',
        ctaLabel: 'Authorize Export',
        ctaIcon: Icons.download_rounded,
      );
      if (authorized == null) return;

      action.run(ref, (txn) async {
        return txn.get(deviceTransferControllerProvider).export(pass);
      }).ignore();
    }

    return Dialog(
      backgroundColor: ColorSet.light,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(r.value(kiosk: 28.0, tablet: 22.0, phone: 16.0)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: r.value(kiosk: 520.0, tablet: 460.0, phone: 360.0),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(r.value(kiosk: 28, tablet: 22, phone: 16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Export Device Backup',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: r.value(kiosk: 24.0, tablet: 20.0, phone: 17.0),
                  fontWeight: FontWeight.w800,
                  color: POSColors.textPrimary,
                ),
              ),
              const Gap(8),
              Text(
                'Choose a passphrase to encrypt the backup. You will need the exact '
                'same passphrase to restore it on another device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: r.value(kiosk: 13.0, tablet: 12.0, phone: 11.0),
                  color: POSColors.textSecondary,
                ),
              ),
              const Gap(20),
              _PassphraseField(
                controller: passphrase,
                label: 'Passphrase',
                obscure: obscure.value,
                onToggle: () => obscure.value = !obscure.value,
                enabled: !isBusy,
                hasPhysicalKeyboard: hasPhysicalKeyboard,
              ),
              const Gap(12),
              _PassphraseField(
                controller: confirm,
                label: 'Confirm passphrase',
                obscure: obscure.value,
                onToggle: () => obscure.value = !obscure.value,
                enabled: !isBusy,
                hasPhysicalKeyboard: hasPhysicalKeyboard,
              ),
              if (error.value != null) ...[
                const Gap(10),
                Text(
                  error.value!,
                  style: TextStyle(
                    color: ColorSet.danger,
                    fontSize: r.value(kiosk: 12.0, tablet: 11.0, phone: 10.0),
                    fontWeight: FontWeight.w600,
                  ),
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
                      backgroundColor: ColorSet.primary,
                      foregroundColor: ColorSet.light,
                      onPressed: isBusy ? null : submit,
                      label: Text(isBusy ? 'Exporting…' : 'Export'),
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

String _two(int n) => n.toString().padLeft(2, '0');

class _PassphraseField extends StatelessWidget {
  const _PassphraseField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    required this.enabled,
    required this.hasPhysicalKeyboard,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final bool enabled;
  final bool hasPhysicalKeyboard;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
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
        labelText: label,
        filled: true,
        fillColor: POSColors.surfaceSubtle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(POSRadius.md),
          borderSide: const BorderSide(color: POSColors.borderDefault),
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
        ),
      ),
    );
  }
}
