import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../utils/windows_touch_keyboard.dart';

/// Scaffold workaround for keyboard popup bug in Windows.
///
/// After a [TextField] is used, Windows can keep the touch keyboard sticky so
/// that later taps (even on non-text widgets) reopen it. See
/// https://github.com/flutter/flutter/issues/99050#issuecomment-3612241934.
///
/// Fix: keep an invisible [ElevatedButton] in the tree and move focus to it
/// whenever the route is shown / resumed, which retracts the OS keyboard.
class WindowsScaffold extends HookWidget {
  const WindowsScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.persistentFooterButtons,
    this.persistentFooterAlignment = AlignmentDirectional.centerEnd,
    this.drawer,
    this.onDrawerChanged,
    this.endDrawer,
    this.onEndDrawerChanged,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.primary = true,
    this.drawerDragStartBehavior = DragStartBehavior.start,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawerScrimColor,
    this.drawerEdgeDragWidth,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    this.restorationId,
  });

  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  final List<Widget>? persistentFooterButtons;
  final AlignmentDirectional persistentFooterAlignment;
  final Widget? drawer;
  final DrawerCallback? onDrawerChanged;
  final Widget? endDrawer;
  final DrawerCallback? onEndDrawerChanged;
  final Color? drawerScrimColor;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool primary;
  final DragStartBehavior drawerDragStartBehavior;
  final double? drawerEdgeDragWidth;
  final bool drawerEnableOpenDragGesture;
  final bool endDrawerEnableOpenDragGesture;
  final String? restorationId;

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();

    useEffect(() {
      if (!Platform.isWindows) return null;
      WindowsTouchKeyboard.focusSink = focusNode;
      WindowsTouchKeyboard.dismiss();
      return () {
        // This screen is leaving the tree (navigated away from, replaced,
        // popped) — drop any focused field on it now rather than leaving
        // that to the next screen's own mount effect, which only runs
        // after this one's dispose and races the OS keyboard's own
        // show/hide animation in the meantime. Unregister the sink first:
        // dismiss()'s post-frame callback re-focuses whatever sink is
        // registered, and this screen's own [focusNode] is about to be
        // disposed along with the rest of this widget, so it must not
        // still be the registered sink by the time that callback runs.
        WindowsTouchKeyboard.unregisterFocusSink(focusNode);
        WindowsTouchKeyboard.dismiss();
      };
    }, [focusNode]);

    final scaffoldBody =
        Platform.isWindows
            ? Stack(
              children: [
                // Invisible ElevatedButton that can own focus without opening IME.
                // Do not set minimumSize — that breaks this Flutter Windows workaround.
                Positioned(
                  left: 0,
                  top: 0,
                  child: ElevatedButton(
                    focusNode: focusNode,
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      elevation: 0,
                    ),
                    child: const SizedBox.shrink(),
                  ),
                ),
                if (body != null) Positioned.fill(child: body!),
              ],
            )
            : body;

    return Scaffold(
      body: scaffoldBody,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      persistentFooterButtons: persistentFooterButtons,
      persistentFooterAlignment: persistentFooterAlignment,
      drawer: drawer,
      onDrawerChanged: onDrawerChanged,
      endDrawer: endDrawer,
      onEndDrawerChanged: onEndDrawerChanged,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      primary: primary,
      drawerDragStartBehavior: drawerDragStartBehavior,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      drawerScrimColor: drawerScrimColor,
      drawerEdgeDragWidth: drawerEdgeDragWidth,
      drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
      endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
      restorationId: restorationId,
    );
  }
}
