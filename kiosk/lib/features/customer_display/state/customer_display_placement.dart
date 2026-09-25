import 'dart:async';

import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'customer_display_log.dart';

/// Moves the current (customer-display) window onto the non-primary monitor,
/// fullscreen, and shows it without stealing focus from the cashier window.
/// Runs in the customer-display engine — `window_manager` is engine-scoped,
/// so this only ever affects the customer-display window. Called once at
/// startup and again by [CustomerDisplayReceiver] whenever the host asks for
/// a re-show after the second monitor comes back.
Future<void> placeOnCustomerMonitor(CustomerDisplayLog log) async {
  try {
    final displays = await screenRetriever.getAllDisplays();
    final primary = await screenRetriever.getPrimaryDisplay();

    // Some hardware (e.g. laptop built-in panels) reports an empty-string id
    // from EnumDisplayDevices. When both the primary and secondary ids are ""
    // the id comparison is always false, so we fall back to comparing the
    // visible position, which is always populated on Windows.
    final target = displays.firstWhere(
      (d) {
        if (d.id.isNotEmpty && primary.id.isNotEmpty) return d.id != primary.id;
        final dp = d.visiblePosition;
        final pp = primary.visiblePosition;
        return dp != null && pp != null && (dp.dx != pp.dx || dp.dy != pp.dy);
      },
      orElse: () => primary,
    );

    unawaited(log.write(
      'place: ${displays.length} displays found, '
      'primary="${primary.id}" pos=${primary.visiblePosition}, '
      'target="${target.id}" pos=${target.visiblePosition} size=${target.size}',
    ));

    // Use the full monitor size (not just the work area) so the window covers
    // the entire secondary display including any taskbar area.
    final origin = target.visiblePosition ?? Offset.zero;
    final size = target.size;

    // Leave fullscreen first — Windows ignores setBounds on a fullscreen
    // window, which would pin it to whatever monitor it was last on.
    if (await windowManager.isFullScreen()) {
      await windowManager.setFullScreen(false);
    }
    await windowManager.setBounds(Rect.fromLTWH(origin.dx, origin.dy, size.width, size.height));
    await windowManager.setFullScreen(true);
    await windowManager.show(inactive: true);
  } catch (e, s) {
    unawaited(log.write('place: FAILED: $e\n$s'));
  }
}
