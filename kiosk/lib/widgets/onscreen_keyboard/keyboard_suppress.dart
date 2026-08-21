import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'onscreen_keyboard.dart';

/// Properties that make a raw [TextField]/[TextFormField] use the app's own
/// [OnScreenKeyboard] instead of the Windows touch keyboard.
///
/// [TextBoxFormField] applies this internally, so fields built on that wrapper
/// need nothing. These helpers are for the call sites that construct a
/// [TextField]/[TextFormField] directly with their own decoration, where
/// switching to the wrapper would mean rewriting the visuals.
///
/// Apply all five at each site, passing the same `hasPhysicalKeyboard` (from
/// `useValueListenable(PhysicalKeyboardDetector.attached)` in the enclosing
/// [HookWidget]/[HookConsumerWidget]) to each call so the field reacts live
/// if a keyboard is plugged/unplugged mid-session:
///
/// ```dart
/// final hasPhysicalKeyboard = useValueListenable(PhysicalKeyboardDetector.attached);
/// TextFormField(
///   readOnly: KeyboardSuppress.readOnly(hasPhysicalKeyboard),
///   showCursor: KeyboardSuppress.showCursor(hasPhysicalKeyboard),
///   keyboardType: KeyboardSuppress.type(TextInputType.text, hasPhysicalKeyboard),
///   contextMenuBuilder: KeyboardSuppress.contextMenuBuilder(hasPhysicalKeyboard),
///   onTap: KeyboardSuppress.onTap,
///   ...
/// )
/// ```
///
/// [readOnly] is the load-bearing one when [suppressed] — see [OnScreenKeyboard]
/// for why it, and not any amount of window-poking, is what actually keeps the
/// OS keyboard away. The others make the field usable once it's read-only: a
/// visible caret, a tap that opens our panel, and (since Flutter's default
/// toolbar hides Cut/Paste on a readOnly field) a rebuilt long-press menu.
///
/// Note there's no `canRequestFocus` here: unlike [TextBoxFormField] (which
/// derives it from its own `readOnly` prop), a raw [TextField] defaults
/// `canRequestFocus` to true regardless of `readOnly`, so a suppressed field can
/// still be focused and typed into.
abstract class KeyboardSuppress {
  /// True when this field should hand input entirely to [OnScreenKeyboard]
  /// instead of a real text-input connection: Windows, and no physical
  /// keyboard currently attached. When a physical keyboard is attached the
  /// field is left as an ordinary editable field so real key presses work
  /// directly — [onTap] still offers [OnScreenKeyboard] too, so both stay
  /// usable at once.
  static bool suppressed(bool hasPhysicalKeyboard) => Platform.isWindows && !hasPhysicalKeyboard;

  static bool readOnly(bool hasPhysicalKeyboard) => suppressed(hasPhysicalKeyboard);

  /// Read-only fields hide the caret by default; a field being typed into
  /// (via [OnScreenKeyboard]) needs it visible. Null when not suppressed, so
  /// the field's own default applies.
  static bool? showCursor(bool hasPhysicalKeyboard) => suppressed(hasPhysicalKeyboard) ? true : null;

  /// Belt-and-braces alongside [readOnly]: signals "no system keyboard" even
  /// where an input connection does get opened (Android, web).
  static TextInputType? type(TextInputType? original, bool hasPhysicalKeyboard) =>
      suppressed(hasPhysicalKeyboard) ? TextInputType.none : original;

  /// Windows always offers the on-screen panel on tap, physical keyboard or
  /// not — so touch input stays available even when real key presses also
  /// work.
  static VoidCallback? get onTap => Platform.isWindows ? OnScreenKeyboard.show : null;

  /// Rebuilds the long-press selection toolbar for a [suppressed] field.
  /// Flutter's default toolbar hides Cut/Paste whenever `readOnly` is true,
  /// but a suppressed field is only readOnly to the OS — it's actually
  /// editable — so without this, long-press-to-paste silently stops working.
  /// Returns null (default toolbar) when not suppressed.
  static EditableTextContextMenuBuilder? contextMenuBuilder(bool hasPhysicalKeyboard) =>
      suppressed(hasPhysicalKeyboard) ? buildSuppressedFieldContextMenu : null;
}

/// Rebuilds the long-press selection toolbar for fields that are `readOnly`
/// only to suppress the Windows OS keyboard (see [KeyboardSuppress.suppressed]).
/// Flutter's default toolbar hides Cut/Paste whenever `readOnly` is true, so
/// this restores them via [EditableTextState.userUpdateTextEditingValue] —
/// the same [OnScreenKeyboard]-safe path used for on-screen key taps.
Widget buildSuppressedFieldContextMenu(BuildContext context, EditableTextState editableTextState) {
  final value = editableTextState.textEditingValue;
  final selection = value.selection;
  final hasSelection = selection.isValid && !selection.isCollapsed;
  final selectedText = hasSelection ? selection.textInside(value.text) : '';

  final buttonItems = <ContextMenuButtonItem>[
    if (hasSelection)
      ContextMenuButtonItem(
        type: ContextMenuButtonType.cut,
        onPressed: () {
          Clipboard.setData(ClipboardData(text: selectedText));
          replaceEditableTextSelection(editableTextState, '');
          editableTextState.hideToolbar();
        },
      ),
    if (hasSelection)
      ContextMenuButtonItem(
        type: ContextMenuButtonType.copy,
        onPressed: () {
          Clipboard.setData(ClipboardData(text: selectedText));
          editableTextState.hideToolbar();
        },
      ),
    ContextMenuButtonItem(
      type: ContextMenuButtonType.paste,
      onPressed: () async {
        final data = await Clipboard.getData(Clipboard.kTextPlain);
        editableTextState.hideToolbar();
        final text = data?.text;
        if (text != null && text.isNotEmpty) replaceEditableTextSelection(editableTextState, text);
      },
    ),
    if (value.text.isNotEmpty &&
        !(selection.baseOffset == 0 && selection.extentOffset == value.text.length))
      ContextMenuButtonItem(
        type: ContextMenuButtonType.selectAll,
        onPressed: () {
          editableTextState.userUpdateTextEditingValue(
            value.copyWith(
              selection: TextSelection(baseOffset: 0, extentOffset: value.text.length),
            ),
            SelectionChangedCause.toolbar,
          );
        },
      ),
  ];

  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: editableTextState.contextMenuAnchors,
    buttonItems: buttonItems,
  );
}

/// Replaces the current selection (or inserts at the caret if collapsed)
/// with [replacement], applying `inputFormatters` and firing `onChanged` via
/// the same [EditableTextState.userUpdateTextEditingValue] path
/// [OnScreenKeyboard] uses.
void replaceEditableTextSelection(EditableTextState state, String replacement) {
  final value = state.textEditingValue;
  final selection =
      value.selection.isValid ? value.selection : TextSelection.collapsed(offset: value.text.length);
  final newText = value.text.replaceRange(selection.start, selection.end, replacement);
  state.userUpdateTextEditingValue(
    TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + replacement.length),
    ),
    SelectionChangedCause.toolbar,
  );
}
