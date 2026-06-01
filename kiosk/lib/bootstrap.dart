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
      fullScreen: !env.isDev,
      size: !env.isDev ? const Size(1536, 864) : const Size(600, 736),
      minimumSize: const Size(600, 736),
      // Set to transparent to avoid white flash
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      // Essential for native buttons
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setResizable(kDebugMode);
      await windowManager.setMinimizable(kDebugMode);
      await windowManager.setPreventClose(true);
      await windowManager.show();
      await windowManager.focus();
    });
  }

  return ProviderContainer(
    overrides: [appEnvProvider.overrideWithValue(env)],
    retry: (retryCount, error) => null,
  );
}
