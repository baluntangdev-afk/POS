import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/environment/app_env.dart';
import '../../data/backend_api/sources/health_api.dart';
import '../../gen/assets.gen.dart';
import '../../navigation/router.dart';
import '../../theme/pos_design.dart';

class StartupScreen extends HookConsumerWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsedSeconds = useState(0);
    final lastError = useState<String?>(null);

    final backendUrl = ref.read(appEnvProvider).backendApiBaseUrl;

    useEffect(() {
      var cancelled = false;
      var checking = false;

      Future<void> check() async {
        if (checking || cancelled) return;
        checking = true;
        try {
          final result = await ref.read(healthApiProvider).checkAlive();
          if (cancelled) return;
          if (result.isAlive) {
            if (context.mounted) const LoginRoute().go(context);
          } else {
            lastError.value = result.error;
          }
        } finally {
          checking = false;
        }
      }

      check();

      final timer = Timer.periodic(const Duration(seconds: 3), (_) {
        elapsedSeconds.value += 3;
        check();
      });

      return () {
        cancelled = true;
        timer.cancel();
      };
    }, const []);

    final isSlowStartup = elapsedSeconds.value >= 20;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: POSGradient.header),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Assets.images.png.onboardingLogo.image(
                    height: 56,
                    fit: BoxFit.contain,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'POS Kiosk',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Point of Sale System',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 56),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white.withValues(alpha: 0.85),
                  strokeWidth: 2.5,
                  strokeCap: StrokeCap.round,
                ),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: POSAnimation.slow,
                child: Text(
                  key: ValueKey(isSlowStartup),
                  isSlowStartup
                      ? 'Services are taking a moment to start...'
                      : 'Starting up...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (isSlowStartup) ...[
                const SizedBox(height: 8),
                Text(
                  'Connecting to $backendUrl',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (lastError.value != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      lastError.value!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.40),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'If this persists, run recover-services.bat as administrator\n'
                  r'from C:\POSKiosk\scripts\',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.40),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
