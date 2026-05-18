import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../styles/color_set.dart';

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
    this.style,
  }) : assert(
         initialValue == null || controller == null,
         'Provide only one of either initialValue or controller.',
       );

  const TextBoxFormField.email({
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
    this.suffixIcon,
    this.style,
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
    return InputDecorationTheme(
      data: InputDecorationThemeData(
        iconColor: WidgetStateColor.resolveWith((states) {
          return const Color(0xffa9a9a9);
        }),
        contentPadding: const EdgeInsets.all(12.0),
        filled: true,
        fillColor: WidgetStateColor.resolveWith((states) {
          return states.contains(WidgetState.disabled)
              ? const Color(0x0a000000)
              : const Color(0xffffffff);
        }),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xffa9a9a9)),
          borderRadius: BorderRadius.circular(8.0),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xffa9a9a9)),
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xffa9a9a9)),
          borderRadius: BorderRadius.circular(8.0),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xffa9a9a9)),
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xffa9a9a9)),
          borderRadius: BorderRadius.circular(8.0),
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
            enabled: enabled,
            controller: controller,
            initialValue: controller != null ? null : initialValue,
            maxLines: maxLines,
            maxLength: maxLength,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textInputAction: textInputAction,
            validator: (value) {
              isSubmitted.value = true;
              return validator?.call(value);
            },
            autovalidateMode:
                isSubmitted.value ? AutovalidateMode.onUserInteraction : AutovalidateMode.onUnfocus,
            onChanged: onChanged,
            onTapOutside: (_) => focusNode.unfocus(),
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
