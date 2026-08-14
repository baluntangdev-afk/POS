import 'package:flutter/widgets.dart';

import '../utils/windows_touch_keyboard.dart';

/// Retracts the Windows on-screen touch keyboard on every route change.
///
/// Works around a Flutter Windows bug ([flutter#99050]) where the OS touch
/// keyboard stays "stuck" after a focused [TextField] is closed (e.g. a
/// dialog with a text field is popped) so it reopens on the next unrelated
/// tap. [WindowsScaffold] already dismisses on screen mount, but that leaves
/// dialogs and other overlay routes uncovered — this observer catches those
/// too since [showDialog] pushes onto the same root [Navigator] that GoRouter
/// manages.
///
/// [flutter#99050]: https://github.com/flutter/flutter/issues/99050
class WindowsTouchKeyboardObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    WindowsTouchKeyboard.dismiss();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    WindowsTouchKeyboard.dismiss();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    WindowsTouchKeyboard.dismiss();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    WindowsTouchKeyboard.dismiss();
  }
}
