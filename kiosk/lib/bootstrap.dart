import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'config/environment/app_env.dart';

Future<ProviderContainer> bootstrap(AppEnv env) async {
  WidgetsFlutterBinding.ensureInitialized();

  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final message = details.exceptionAsString();
    if (message.contains('!_pressedKeys.containsKey(event.physicalKey)')) {
      return;
    }
    originalOnError?.call(details);
  };

  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    final windowOptions = WindowOptions(
      // fullScreen: !env.isDev,
      windowButtonVisibility: true,
      size: !env.isDev ? const Size(1200, 80) : const Size(600, 736),
      minimumSize: const Size(600, 736),
      // Set to transparent to avoid white flash
      backgroundColor: Colors.transparent,
      skipTaskbar: false,

      // Essential for native buttons
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setResizable(true);
      await windowManager.setMinimizable(true);
      await windowManager.setClosable(true);
      await windowManager.setPreventClose(false);

      // Cover the entire screen (including over the taskbar) while keeping
      // the title bar, so minimize/close remain available.
      final display = PlatformDispatcher.instance.views.first;
      final screenSize = display.physicalSize / display.devicePixelRatio;
      await windowManager.setBounds(
        Rect.fromLTWH(0, 0, screenSize.width, screenSize.height),
      );

      await windowManager.show();
      await windowManager.focus();
    });
  }

  return ProviderContainer(
    overrides: [appEnvProvider.overrideWithValue(env)],
    retry: (retryCount, error) => null,
  );
}
