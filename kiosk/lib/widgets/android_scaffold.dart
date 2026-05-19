import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../styles/color_set.dart';

/// Scaffold for Android that configures system-UI chrome.
///
/// Sets the status bar to transparent (edge-to-edge) and adjusts icon
/// brightness to match the content behind it. Does NOT auto-wrap [body] in
/// SafeArea — each screen is responsible for its own insets so gradient
/// backgrounds can extend behind the status bar.
///
/// See Section 2 of the design spec: SAFE AREA & SYSTEM UI.
class AndroidScaffold extends StatelessWidget {
  const AndroidScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
    // Light icons (white) suit dark/gradient backgrounds; dark icons suit
    // light (#F3F1ED) backgrounds.
    this.statusBarIconBrightness = Brightness.dark,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;
  final bool extendBody;
  final Brightness statusBarIconBrightness;

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: statusBarIconBrightness,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      extendBody: extendBody || bottomNavigationBar != null,
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      backgroundColor: backgroundColor ?? ColorSet.background,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
