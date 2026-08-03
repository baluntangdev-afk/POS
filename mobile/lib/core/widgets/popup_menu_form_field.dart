import 'package:flutter/material.dart';

/// A single selectable entry for [PopupMenuFormField].
class PopupMenuFormFieldItem<T> {
  const PopupMenuFormFieldItem({required this.value, required this.child});

  final T value;
  final Widget child;
}

/// Drop-in replacement for [DropdownButtonFormField] that opens a
/// [PopupMenuButton]-style menu instead of the native dropdown, while still
/// integrating with [Form] validation via [FormField].
class PopupMenuFormField<T> extends FormField<T> {
  PopupMenuFormField({
    super.key,
    required List<PopupMenuFormFieldItem<T>> items,
    super.initialValue,
    super.onSaved,
    super.validator,
    super.autovalidateMode,
    InputDecoration decoration = const InputDecoration(),
    Widget? hint,
    ValueChanged<T?>? onChanged,
    bool enabled = true,
  }) : super(
          builder: (field) {
            final matches = items.where((i) => i.value == field.value);
            final effectiveDecoration = decoration
                .applyDefaults(Theme.of(field.context).inputDecorationTheme)
                .copyWith(errorText: field.errorText, enabled: enabled);

            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: enabled ? () => _openMenu<T>(field, items, onChanged) : null,
              child: InputDecorator(
                decoration: effectiveDecoration,
                isEmpty: field.value == null,
                child: Row(
                  children: [
                    Expanded(
                      child:
                          matches.isNotEmpty ? matches.first.child : (hint ?? const SizedBox.shrink()),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: enabled ? null : Theme.of(field.context).disabledColor,
                    ),
                  ],
                ),
              ),
            );
          },
        );

  static Future<void> _openMenu<T>(
    FormFieldState<T> field,
    List<PopupMenuFormFieldItem<T>> items,
    ValueChanged<T?>? onChanged,
  ) async {
    final button = field.context.findRenderObject() as RenderBox;
    final overlay = Navigator.of(field.context).overlay!.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(button.size.bottomLeft(Offset.zero), ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<T>(
      context: field.context,
      position: position,
      constraints: BoxConstraints(minWidth: button.size.width),
      items: items.map((i) => PopupMenuItem<T>(value: i.value, child: i.child)).toList(),
    );

    if (selected != null) {
      field.didChange(selected);
      onChanged?.call(selected);
    }
  }
}
