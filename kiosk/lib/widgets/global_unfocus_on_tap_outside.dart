import 'dart:io';

import 'package:flutter/material.dart';

import '../utils/windows_touch_keyboard.dart';

/// Unfocuses whatever input field is currently focused the instant a tap
/// lands anywhere outside it — other fields, buttons, empty space, all of
/// it — across every screen and dialog in the app, without each individual
/// [TextField]/[TextFormField] needing its own `onTapOutside` wiring.
///
/// [Listener.onPointerDown] is used instead of a [GestureDetector]: pointer
/// events are delivered to every [Listener] along the hit-test path
/// regardless of which descendant's gesture recognizer ends up "winning"
/// the tap, whereas an ancestor `GestureDetector.onTap` is routinely
/// starved by descendants (buttons, other fields) that claim the gesture
/// first — the exact reason the old approach of wiring `onTapOutside`
/// field-by-field kept missing screens.
///
/// Wrap the whole app with this once (see [App]'s `MaterialApp.router`
/// `builder`) rather than per field.
class GlobalUnfocusOnTapOutside extends StatelessWidget {
  const GlobalUnfocusOnTapOutside({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) return child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      child: child,
    );
  }

  static void _handlePointerDown(PointerDownEvent event) {
    final focus = FocusManager.instance.primaryFocus;
    final focusContext = focus?.context;
    if (focus == null || focusContext == null) return;
    if (focusContext.findAncestorStateOfType<EditableTextState>() == null) {
      // Focus isn't on a text field (e.g. the invisible focus sink, a
      // button) — nothing to unfocus.
      return;
    }

    final renderObject = focusContext.findRenderObject();
    if (renderObject is RenderBox && renderObject.attached) {
      final topLeft = renderObject.localToGlobal(Offset.zero);
      if ((topLeft & renderObject.size).contains(event.position)) {
        // Tap landed inside the focused field itself — e.g. repositioning
        // the cursor. Leave it focused.
        return;
      }
    }

    focus.unfocus();
    WindowsTouchKeyboard.dismiss();
  }
}
