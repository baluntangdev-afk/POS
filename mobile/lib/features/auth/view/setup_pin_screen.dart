import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../users/state/users_notifier.dart';
import '../state/auth_providers.dart';
import '../state/auth_state.dart';
import 'widgets/auth_card.dart';
import 'widgets/pin_dots.dart';
import 'widgets/pin_keypad.dart';

/// Forces a PIN change when the logged-in user is still using the seeded
/// default PIN (see `core/seeder/admin_seeder.dart`). Reachable only via the
/// router's redirect when `AuthAuthenticated.mustChangePin` is true — there
/// is no way to dismiss it and reach the dashboard with the default PIN
/// still active.
///
/// Two-step keypad flow (enter new PIN, then confirm it) using the same
/// PinDots/PinKeypad as the login screen, so PIN entry feels identical
/// everywhere staff type one.
class SetupPinScreen extends HookConsumerWidget {
  const SetupPinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = useState(0); // 0 = enter new PIN, 1 = confirm it
    final newPin = useState('');
    final confirmPin = useState('');
    final loading = useState(false);
    final errorText = useState<String?>(null);

    final authState = ref.watch(authNotifierProvider);
    final userId = authState is AuthAuthenticated ? authState.user.id : null;

    void resetToFirstStep({String? error}) {
      step.value = 0;
      newPin.value = '';
      confirmPin.value = '';
      errorText.value = error;
    }

    Future<void> submit(String pin) async {
      if (userId == null) return;
      loading.value = true;
      try {
        await ref
            .read(usersProvider.notifier)
            .completeOwnPinSetup(userId: userId, newPin: pin);
        ref.read(authNotifierProvider.notifier).completePinSetup();
      } finally {
        loading.value = false;
      }
    }

    void appendDigit(String digit) {
      if (step.value == 0) {
        if (newPin.value.length >= 6) return;
        errorText.value = null;
        newPin.value += digit;
        if (newPin.value.length == 6) {
          if (newPin.value == '000000') {
            resetToFirstStep(error: 'Choose a PIN other than the default');
            return;
          }
          step.value = 1;
        }
      } else {
        if (confirmPin.value.length >= 6) return;
        errorText.value = null;
        confirmPin.value += digit;
        if (confirmPin.value.length == 6) {
          if (confirmPin.value != newPin.value) {
            resetToFirstStep(error: 'PINs do not match');
            return;
          }
          submit(confirmPin.value);
        }
      }
    }

    void deleteDigit() {
      if (step.value == 0) {
        if (newPin.value.isEmpty) return;
        newPin.value = newPin.value.substring(0, newPin.value.length - 1);
      } else {
        if (confirmPin.value.isEmpty) return;
        confirmPin.value = confirmPin.value.substring(
          0,
          confirmPin.value.length - 1,
        );
      }
      errorText.value = null;
    }

    final isConfirmStep = step.value == 1;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AuthCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child:
                                isConfirmStep
                                    ? IconButton(
                                      padding: EdgeInsets.zero,
                                      onPressed:
                                          () => resetToFirstStep(),
                                      icon: const Icon(
                                        Icons.arrow_back,
                                        size: 20,
                                      ),
                                      tooltip: 'Back',
                                    )
                                    : null,
                          ),
                          const Expanded(child: SizedBox()),
                          const SizedBox(width: 40),
                        ],
                      ),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isConfirmStep
                              ? Icons.check_circle_outline_rounded
                              : Icons.lock_reset_rounded,
                          color: AppColors.primary,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          final offsetAnimation = Tween<Offset>(
                            begin: Offset(
                              child.key == const ValueKey('enter-step')
                                  ? -0.08
                                  : 0.08,
                              0,
                            ),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          key: ValueKey(
                            isConfirmStep ? 'confirm-step' : 'enter-step',
                          ),
                          children: [
                            Text(
                              isConfirmStep
                                  ? 'Confirm Your PIN'
                                  : 'Set Your PIN',
                              style: AppTextStyles.headingLg,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              isConfirmStep
                                  ? 'Re-enter the PIN to confirm.'
                                  : 'This account is still using the default '
                                      'PIN. Choose a new 6-digit PIN to '
                                      'continue.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            PinDots(
                              length:
                                  isConfirmStep
                                      ? confirmPin.value.length
                                      : newPin.value.length,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (errorText.value != null)
                              Text(
                                errorText.value!,
                                style: AppTextStyles.bodyMd.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            const SizedBox(height: AppSpacing.lg),
                            PinKeypad(
                              onDigit: appendDigit,
                              onDelete: deleteDigit,
                              disabled: loading.value,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
