import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'navigation/router.dart';
import 'styles/color_set.dart';
import 'styles/fallback_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: fallbackTheme,
      builder: (context, child) {
        if (!kIsWeb && Platform.isWindows) {
          return _WindowCloseGuard(child: child ?? const SizedBox.shrink());
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

class _WindowCloseGuard extends StatefulWidget {
  const _WindowCloseGuard({required this.child});
  final Widget child;

  @override
  State<_WindowCloseGuard> createState() => _WindowCloseGuardState();
}

class _WindowCloseGuardState extends State<_WindowCloseGuard> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    final confirmed = await _showExitDialog();
    if (confirmed ?? false) {
      await windowManager.destroy();
    }
  }

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Exit Application',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Are you sure you want to close POS Kiosk?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: ColorSet.danger),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
