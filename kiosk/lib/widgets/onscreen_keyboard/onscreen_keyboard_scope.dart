import 'dart:io';

import 'package:flutter/material.dart';

import 'onscreen_keyboard.dart';
import 'onscreen_keyboard_panel.dart';

/// Docks [OnScreenKeyboardPanel] to the bottom of the app and reflows the app
/// content into the space above it.
///
/// Wrap the whole app with this once (see `app.dart`'s `MaterialApp.router`
/// builder). Windows only — Android has a working system soft keyboard and
/// should keep using it.
///
/// The content is placed in an [Expanded] above the panel rather than having
/// the panel float over it, so a focused field is never hidden behind the
/// keyboard: the app simply gets a shorter viewport and every [Scaffold],
/// scroll view and centred dialog re-lays-out inside it. [MediaQuery]'s size is
/// overridden to match that shorter viewport, because screens that size
/// themselves from `MediaQuery.of(context).size` would otherwise still believe
/// they have the full window height and overflow behind the panel.
class OnScreenKeyboardScope extends StatelessWidget {
  const OnScreenKeyboardScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) return child;

    OnScreenKeyboard.attach();

    return ValueListenableBuilder<bool>(
      valueListenable: OnScreenKeyboard.visible,
      builder: (context, isVisible, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // ~38% of the display, bounded so keys stay touch-sized on a short
            // 1366x768 kiosk panel without eating a 1080p screen.
            final keyboardHeight = isVisible
                ? (constraints.maxHeight * 0.38).clamp(220.0, 420.0)
                : 0.0;
            final mediaQuery = MediaQuery.of(context);

            return Column(
              children: [
                Expanded(
                  child: MediaQuery(
                    data: mediaQuery.copyWith(
                      size: Size(
                        constraints.maxWidth,
                        constraints.maxHeight - keyboardHeight,
                      ),
                    ),
                    child: child,
                  ),
                ),
                // TextFieldTapRegion marks the panel as belonging to the text
                // field for hit-testing purposes, so tapping a key does not
                // fire the focused field's onTapOutside (which would unfocus
                // it and dismiss this panel on the first keypress).
                TextFieldTapRegion(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    alignment: Alignment.topCenter,
                    child: _PanelSlot(height: keyboardHeight),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Separate widget so [AnimatedSize] sees a child whose size changes between
/// zero and the panel height, giving the slide-in/out transition.
///
/// [height] is the exact space the scope reserved above, so the panel can never
/// end up taller than the gap left for it (which would overflow the [Column]).
class _PanelSlot extends StatelessWidget {
  const _PanelSlot({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    if (height == 0) return const SizedBox(width: double.infinity);
    return SizedBox(
      width: double.infinity,
      height: height,
      child: const OnScreenKeyboardPanel(),
    );
  }
}
