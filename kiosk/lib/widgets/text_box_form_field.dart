import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../styles/color_set.dart';
import '../theme/pos_design.dart';
import '../utils/physical_keyboard_detector.dart';
import '../utils/windows_touch_keyboard.dart';
import 'onscreen_keyboard/keyboard_suppress.dart';
import 'onscreen_keyboard/onscreen_keyboard.dart';

class TextBoxFormField extends HookWidget {
  const TextBoxFormField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.maxLines,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.showError = true,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.style,
    this.onTap,
  }) : assert(
         initialValue == null || controller == null,
         'Provide only one of either initialValue or controller.',
       );

  const TextBoxFormField.email({
    super.key,
    this.label,
    this.readOnly = false,
    this.controller,
    this.initialValue,
    this.hint,
    this.validator,
    this.onChanged,
    this.maxLength,
    this.inputFormatters,
    this.textInputAction,
    this.showError = true,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.style,

    this.onTap,
  }) : maxLines = 1,
       keyboardType = TextInputType.emailAddress,
       assert(
         initialValue == null || controller == null,
         'Provide only one of either initialValue or controller.',
       ),
       assert(
         maxLength == null || maxLength == -1 || maxLength > 0,
         'Maximum length of characters should be either greater than 0 or -1.',
       );

  const TextBoxFormField.readOnly({
    super.key,
    this.label,
    this.controller,
    this.initialValue,
    this.hint,
    this.validator,
    this.onChanged,
    this.maxLength,
    this.inputFormatters,
    this.textInputAction,
    this.showError = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.style,
    this.readOnly = true,
    this.onTap,

  }) : maxLines = 1,
        keyboardType = TextInputType.emailAddress,
        assert(
        initialValue == null || controller == null,
        'Provide only one of either initialValue or controller.',
        ),
        assert(
        maxLength == null || maxLength == -1 || maxLength > 0,
        'Maximum length of characters should be either greater than 0 or -1.',
        );

  const TextBoxFormField.password({
    super.key,
    this.label,
    this.controller,
    this.initialValue,
    this.hint,
    this.validator,
    this.onChanged,
    this.maxLength,
    this.inputFormatters,
    this.textInputAction,
    this.showError = true,
    this.enabled = true,
    this.prefixIcon,
    this.style,
    this.readOnly = false,
    this.onTap,
  }) : maxLines = 1,
       keyboardType = TextInputType.visiblePassword,
       suffixIcon = null,
       assert(
         initialValue == null || controller == null,
         'Provide only one of either initialValue or controller.',
       ),
       assert(
         maxLength == null || maxLength == -1 || maxLength > 0,
         'Maximum length of characters should be either greater than 0 or -1.',
       );

  const TextBoxFormField.singleLine({
    super.key,
    this.label,
    this.controller,
    this.hint,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.showError = true,
    this.maxLength,
    this.inputFormatters,
    this.textInputAction,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.style,
    this.readOnly = false,
    this.onTap,
  }) : maxLines = 1,
       keyboardType = TextInputType.text,
       assert(
         initialValue == null || controller == null,
         'Provide only one of either initialValue or controller.',
       ),
       assert(
         maxLength == null || maxLength == -1 || maxLength > 0,
         'Maximum length of characters should be either greater than 0 or -1.',
       );

  const TextBoxFormField.multiline({
    super.key,
    this.label,
    this.readOnly = false,
    this.controller,
    this.hint,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.showError = true,
    this.maxLines,
    this.maxLength,
    this.inputFormatters,
    this.textInputAction,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.style,
    this.onTap,
  }) : keyboardType = TextInputType.multiline,
       assert(
         initialValue == null || controller == null,
         'Provide only one of either initialValue or controller.',
       ),
       assert(
         maxLines == null || maxLines > 0,
         'Maximum number of lines should be greater than 0.',
       ),
       assert(
         maxLength == null || maxLength == -1 || maxLength > 0,
         'Maximum length of characters should be either greater than 0 or -1.',
       );

  final String? initialValue;
  final String? label;
  final String? hint;
  final bool readOnly;
  final TextEditingController? controller;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String?>? validator;
  final ValueChanged<String?>? onChanged;
  final bool showError;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextStyle? style;
  final void Function()? onTap;
  @override
  Widget build(BuildContext context) {
    // Assert suffix icon is null when keyboardType is TextInputType.visiblePassword.
    assert(
      keyboardType != TextInputType.visiblePassword || suffixIcon == null,
      'Suffix icon should be null when keyboardType is TextInputType.visiblePassword.',
    );
    final isObscured = useState(keyboardType == TextInputType.visiblePassword);
    final focusNode = useFocusNode();
    final isSubmitted = useState(false);

    // On a touch-only Windows machine this field is driven entirely by the
    // app's own [OnScreenKeyboard] instead of the OS touch keyboard. Marking
    // it read-only is what actually suppresses the OS keyboard: Flutter
    // never opens a text-input connection for a read-only field on Windows,
    // so the OS is never told text input is active and has nothing to
    // auto-invoke against. See [OnScreenKeyboard].
    //
    // That trick is only needed when there's no physical keyboard to fall
    // back on. When [PhysicalKeyboardDetector] finds one attached (a real
    // USB/PS2 keyboard, or a 2-in-1's built-in one), the field is left as a
    // normal editable field so real key presses work directly — [onTap]
    // below still offers [OnScreenKeyboard] too, so both stay usable at
    // once.
    //
    // Fields the *caller* marked read-only (pickers, display-only values) are
    // excluded from all of this — they aren't meant to accept typing at all.
    final isWindowsField = Platform.isWindows && !readOnly && enabled;
    final hasPhysicalKeyboard = useValueListenable(PhysicalKeyboardDetector.attached);
    final suppressOsInputConnection = isWindowsField && !hasPhysicalKeyboard;
    final effectiveReadOnly = readOnly || suppressOsInputConnection;
    return InputDecorationTheme(
      data: InputDecorationThemeData(
        iconColor: WidgetStateColor.resolveWith((states) {
          return POSColors.iconSubtle;
        }),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: WidgetStateColor.resolveWith((states) {
          return states.contains(WidgetState.disabled)
              ? POSColors.surfaceSubtle
              : Colors.white;
        }),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: POSColors.borderDefault),
          borderRadius: BorderRadius.circular(POSRadius.md),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: POSColors.borderSubtle),
          borderRadius: BorderRadius.circular(POSRadius.md),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: ColorSet.primary, width: 1.5),
          borderRadius: BorderRadius.circular(POSRadius.md),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: ColorSet.danger),
          borderRadius: BorderRadius.circular(POSRadius.md),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: ColorSet.danger, width: 1.5),
          borderRadius: BorderRadius.circular(POSRadius.md),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(label!, style: const TextStyle().merge(style)),
            const SizedBox(height: 4.0),
          ],
          TextFormField(
            focusNode: focusNode,
            onTap: () {
              if (isWindowsField) OnScreenKeyboard.show();
              onTap?.call();
            },
            readOnly: effectiveReadOnly,
            // Flutter's built-in selection toolbar omits Cut/Paste for
            // readOnly fields, and this field is only readOnly to the OS (see
            // [suppressOsInputConnection] above) — it's actually editable.
            // Rebuild the toolbar so long-press-to-paste keeps working. Not
            // needed once a physical keyboard makes the field genuinely
            // non-readOnly — the default toolbar already has Paste then.
            contextMenuBuilder: suppressOsInputConnection ? buildSuppressedFieldContextMenu : null,
            enabled: enabled,
            // Deliberately keyed off the caller's [readOnly], not
            // [effectiveReadOnly]: a custom-keyboard field is read-only to the
            // OS but must still be focusable, or it could never be typed into.
            canRequestFocus: !readOnly,
            // Read-only fields hide the caret by default, but this one is
            // actively being typed into, so the caret has to stay visible.
            showCursor: suppressOsInputConnection ? true : null,
            controller: controller,
            initialValue: controller != null ? null : initialValue,
            maxLines: maxLines,
            maxLength: maxLength,
            keyboardType: suppressOsInputConnection ? TextInputType.none : keyboardType,
            inputFormatters: inputFormatters,
            textInputAction: textInputAction,
            validator: (value) {
              isSubmitted.value = true;
              return validator?.call(value);
            },
            autovalidateMode:
                isSubmitted.value ? AutovalidateMode.onUserInteraction : AutovalidateMode.onUnfocus,
            onChanged: onChanged,
            onTapOutside: (_) {
              // The keyboard panel is wrapped in a TextFieldTapRegion, so
              // tapping a key does not reach here — only genuine taps
              // elsewhere in the app do.
              focusNode.unfocus();
              OnScreenKeyboard.hide();
              WindowsTouchKeyboard.dismiss();
            },
            obscureText: isObscured.value,
            style: const TextStyle().merge(style),
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.never,
              hintText: hint,
              errorStyle:
                  showError
                      ? const TextStyle(color: ColorSet.danger).merge(style)
                      : const TextStyle(fontSize: 0.0),
              errorMaxLines: 4,
              prefixIcon: prefixIcon,
              suffixIcon:
                  keyboardType == TextInputType.visiblePassword
                      ? IconButton(
                        icon:
                            isObscured.value
                                ? const Icon(Icons.visibility)
                                : const Icon(Icons.visibility_off),
                        onPressed: () {
                          isObscured.value = !isObscured.value;
                        },
                      )
                      : suffixIcon,
            ),
          ),
        ],
      ),
    );
  }
}


