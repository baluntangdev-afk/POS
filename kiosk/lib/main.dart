import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'config/environment/env.dart';
import 'customer_display_window_argument.dart';
import 'features/customer_display/state/customer_display_host.dart';
import 'features/customer_display/state/customer_display_receiver.dart';
import 'features/customer_display/view/customer_display_app.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final windowController = await WindowController.fromCurrentEngine();
  if (windowController.arguments == customerDisplayWindowArgument) {
    await _runCustomerDisplay(windowController);
    return;
  }

  final container = await bootstrap(Env());
  CustomerDisplayHost.start(container);
  runApp(UncontrolledProviderScope(
    container: container,
    child: App(container: container),
  ));
}

/// Entrypoint for the customer-display sub-window engine. Positions itself
/// on the non-primary monitor and shows without stealing focus from the
/// cashier window, then starts listening for snapshots pushed by
/// [CustomerDisplayHost] in the cashier engine.
Future<void> _runCustomerDisplay(WindowController windowController) async {
  await windowManager.ensureInitialized();

  final displays = await screenRetriever.getAllDisplays();
  final primary = await screenRetriever.getPrimaryDisplay();
  final target = displays.firstWhere(
    (display) => display.id != primary.id,
    orElse: () => primary,
  );
  final origin = target.visiblePosition ?? Offset.zero;
  final size = target.visibleSize ?? target.size;

  const windowOptions = WindowOptions(
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
    skipTaskbar: true,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setBounds(Rect.fromLTWH(origin.dx, origin.dy, size.width, size.height));
    await windowManager.setFullScreen(true);
    await windowManager.show(inactive: true);
  });

  final container = ProviderContainer();
  CustomerDisplayReceiver(container).attach(windowController);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CustomerDisplayApp(),
    ),
  );
}
