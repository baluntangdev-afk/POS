import 'package:flutter/material.dart';

/// Drives text input for the app's own on-screen keyboard, replacing the
/// Windows touch keyboard entirely.
///
/// ## Why this exists
///
/// Windows' own touch keyboard (`TabTip.exe` on older builds,
/// `TextInputHost.exe` on Windows 10 1903+) cannot be reliably controlled by a
/// Flutter Windows app. Flutter's engine doesn't integrate with the Text
/// Services Framework the way native Win32/WinRT controls do, so the OS
/// guesses when to show and hide the keyboard from incomplete signals — and it
/// guesses wrong, popping up on screens with no text field at all. Every
/// attempt to suppress it after the fact (`ShowWindow`/`SW_HIDE`, then
/// `WM_SYSCOMMAND`/`SC_CLOSE`, then a polling watcher in
/// `windows/runner/touch_keyboard_guard.cpp`) is racing a heuristic we don't
/// control, against a window we can't even identify unambiguously — on Windows
/// 11 the keyboard is one of several unnamed `CoreWindow`s owned by
/// `TextInputHost.exe`, which also hosts the emoji panel and clipboard
/// history. See [flutter#99050](https://github.com/flutter/flutter/issues/99050).
///
/// ## How this fixes it structurally
///
/// Rather than suppress the OS keyboard, we remove every reason for it to
/// appear. Fields that use this keyboard are marked `readOnly: true`, and
/// Flutter's [EditableText] never opens a text-input connection for a
/// read-only field on Windows:
///
/// ```dart
/// // flutter/lib/src/widgets/editable_text.dart
/// bool get _shouldCreateInputConnection =>
///     kIsWeb || defaultTargetPlatform == TargetPlatform.macOS || !widget.readOnly;
/// ```
///
/// No input connection means the OS is never told that text input is active,
/// so TSF is never engaged and there is nothing for the keyboard to react to.
/// That's a structural guarantee, not a heuristic we're racing.
///
/// ## Preserving validation
///
/// Input is applied through [EditableTextState.userUpdateTextEditingValue]
/// rather than by assigning to the [TextEditingController] directly. That
/// matters: the controller path skips `inputFormatters` and never fires
/// `onChanged`, which would silently break every validator and formatter in
/// the app. `userUpdateTextEditingValue` routes into
/// `EditableTextState._formatAndSetValue`, which applies `widget
/// .inputFormatters` and calls `widget.onChanged` — and it explicitly handles
/// the `readOnly` case, so it is the supported way to drive a field like this.
class OnScreenKeyboard {
  OnScreenKeyboard._();

  /// Whether the docked keyboard panel is currently on screen.
  /// [OnScreenKeyboardScope] listens to this to show/hide the panel.
  static final ValueNotifier<bool> visible = ValueNotifier<bool>(false);

  static bool _attached = false;

  /// Starts auto-hiding the panel whenever focus leaves a text field, so it
  /// never lingers over a screen with nothing to type into. Called by
  /// [OnScreenKeyboardScope]; safe to call more than once.
  static void attach() {
    if (_attached) return;
    _attached = true;
    FocusManager.instance.addListener(_handleFocusChange);
  }

  static void _handleFocusChange() {
    if (_target == null) hide();
  }

  static void show() => visible.value = true;

  static void hide() => visible.value = false;

  /// The focused field's [EditableTextState], or null when focus isn't on a
  /// text field. The primary focus node's context sits inside the
  /// [EditableText] subtree, so the state is found by walking up from it.
  static EditableTextState? get _target =>
      FocusManager.instance.primaryFocus?.context?.findAncestorStateOfType<EditableTextState>();

  /// Selection to edit against. A field that has never been tapped can report
  /// an invalid (offset -1) selection, in which case input appends at the end
  /// rather than being silently dropped.
  static TextSelection _selectionOf(TextEditingValue value) {
    return value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
  }

  static void _apply(EditableTextState state, String text, TextSelection selection) {
    state.userUpdateTextEditingValue(
      TextEditingValue(text: text, selection: selection),
      SelectionChangedCause.keyboard,
    );
  }

  /// Inserts [text] at the caret, replacing the selection if there is one.
  static void insert(String text) {
    final state = _target;
    if (state == null) return;

    final value = state.textEditingValue;
    final selection = _selectionOf(value);
    _apply(
      state,
      value.text.replaceRange(selection.start, selection.end, text),
      TextSelection.collapsed(offset: selection.start + text.length),
    );
  }

  /// Deletes the selection, or the character before the caret.
  static void backspace() {
    final state = _target;
    if (state == null) return;

    final value = state.textEditingValue;
    final selection = _selectionOf(value);

    if (!selection.isCollapsed) {
      _apply(
        state,
        value.text.replaceRange(selection.start, selection.end, ''),
        TextSelection.collapsed(offset: selection.start),
      );
      return;
    }

    if (selection.start == 0) return;

    // Delete a whole user-perceived character: an emoji or other astral-plane
    // character is a surrogate pair in Dart's UTF-16 string, and removing one
    // code unit of a pair would leave a broken half behind.
    var removeCount = 1;
    final previousUnit = value.text.codeUnitAt(selection.start - 1);
    if (selection.start >= 2 && previousUnit >= 0xDC00 && previousUnit <= 0xDFFF) {
      removeCount = 2;
    }
    final start = selection.start - removeCount;
    _apply(
      state,
      value.text.replaceRange(start, selection.start, ''),
      TextSelection.collapsed(offset: start),
    );
  }

  /// Moves the caret by [delta] characters, clamped to the text bounds.
  static void moveCaret(int delta) {
    final state = _target;
    if (state == null) return;

    final value = state.textEditingValue;
    final selection = _selectionOf(value);
    final offset = (selection.baseOffset + delta).clamp(0, value.text.length);
    state.userUpdateTextEditingValue(
      value.copyWith(selection: TextSelection.collapsed(offset: offset)),
      SelectionChangedCause.keyboard,
    );
  }

  /// Runs the focused field's `onFieldSubmitted`/`onSubmitted` action, then
  /// dismisses the panel — the "Done"/Enter key.
  static void submit() {
    final state = _target;
    if (state != null && state.widget.maxLines != 1) {
      // Multiline field: Enter should insert a newline rather than dismiss.
      insert('\n');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    hide();
  }
}
