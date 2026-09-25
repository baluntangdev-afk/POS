import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../styles/color_set.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/physical_keyboard_detector.dart';
import '../../../utils/windows_touch_keyboard.dart';
import '../../../widgets/onscreen_keyboard/keyboard_suppress.dart';
import '../../../widgets/onscreen_keyboard/onscreen_keyboard.dart';

/// Required Kiosk ID input with a copy button, shared by the POS terminal
/// details dialog and the first-run terminal registration dialog.
class KioskIdField extends HookWidget {
  const KioskIdField({super.key, required this.controller, this.hint});

  final TextEditingController controller;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final justCopied = useState(false);

    useEffect(() {
      if (!justCopied.value) return null;
      final timer = Timer(const Duration(seconds: 2), () {
        justCopied.value = false;
      });
      return timer.cancel;
    }, [justCopied.value]);

    Future<void> onCopy() async {
      await Clipboard.setData(ClipboardData(text: controller.text));
      justCopied.value = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.fingerprint_rounded, size: 14, color: POSColors.textTertiary),
            SizedBox(width: 6),
            Text(
              'Kiosk ID',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: POSColors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<bool>(
          valueListenable: PhysicalKeyboardDetector.attached,
          builder: (context, hasPhysicalKeyboard, _) => TextFormField(
            controller: controller,
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
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: POSColors.textSecondary),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Kiosk ID is required' : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: POSColors.textTertiary.withValues(alpha: 0.6)),
              filled: true,
              fillColor: POSColors.surfaceSubtle,
              suffixIcon: IconButton(
                icon: Icon(
                  justCopied.value ? Icons.check_rounded : Icons.copy_rounded,
                  size: 16,
                  color: justCopied.value ? ColorSet.primary : POSColors.textTertiary,
                ),
                tooltip: 'Copy Kiosk ID',
                onPressed: onCopy,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(POSRadius.md),
                borderSide: const BorderSide(color: POSColors.borderDefault),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(POSRadius.md),
                borderSide: const BorderSide(color: POSColors.borderDefault),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(POSRadius.md),
                borderSide: const BorderSide(color: ColorSet.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(POSRadius.md),
                borderSide: const BorderSide(color: ColorSet.danger),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
