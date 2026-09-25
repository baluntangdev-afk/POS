import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'config/environment/env.dart';
import 'customer_display_window_argument.dart';
import 'features/customer_display/state/customer_display_host.dart';
import 'features/customer_display/state/customer_display_log.dart';
import 'features/customer_display/state/customer_display_placement.dart';
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

  final log = CustomerDisplayLog('customer-display-receiver.log');

  const windowOptions = WindowOptions(
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
    skipTaskbar: true,
  );

  try {
    await windowManager.waitUntilReadyToShow(windowOptions, () => placeOnCustomerMonitor(log));
  } catch (e, s) {
    unawaited(log.write('init: FAILED: $e\n$s'));
  }

  final container = ProviderContainer();
  CustomerDisplayReceiver(container).attach(windowController);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CustomerDisplayApp(),
    ),
  );
}
