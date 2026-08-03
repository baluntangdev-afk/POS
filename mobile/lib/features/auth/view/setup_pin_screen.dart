import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../users/state/users_notifier.dart';
import '../state/auth_providers.dart';
import '../state/auth_state.dart';

/// Forces a PIN change when the logged-in user is still using the seeded
/// default PIN (see `core/seeder/admin_seeder.dart`). Reachable only via the
/// router's redirect when `AuthAuthenticated.mustChangePin` is true — there
/// is no way to dismiss it and reach the dashboard with the default PIN
/// still active.
class SetupPinScreen extends HookConsumerWidget {
  const SetupPinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinCtrl = useTextEditingController();
    final confirmCtrl = useTextEditingController();
    final loading = useState(false);
    final errorText = useState<String?>(null);

    final authState = ref.watch(authNotifierProvider);
    final userId = authState is AuthAuthenticated ? authState.user.id : null;

    Future<void> submit() async {
      if (userId == null) return;
      if (pinCtrl.text.length != 6 || int.tryParse(pinCtrl.text) == null) {
        errorText.value = 'PIN must be exactly 6 digits';
        return;
      }
      if (pinCtrl.text == '000000') {
        errorText.value = 'Choose a PIN other than the default';
        return;
      }
      if (pinCtrl.text != confirmCtrl.text) {
        errorText.value = 'PINs do not match';
        return;
      }
      errorText.value = null;
      loading.value = true;
      try {
        await ref.read(usersProvider.notifier).completeOwnPinSetup(userId: userId, newPin: pinCtrl.text);
        ref.read(authNotifierProvider.notifier).completePinSetup();
      } finally {
        loading.value = false;
      }
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 36),
                    ),
                    const Gap(AppSpacing.lg),
                    Text('Set Your PIN', style: AppTextStyles.headingLg),
                    const Gap(AppSpacing.sm),
                    Text(
                      'This account is still using the default PIN. Choose a new one to continue.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
                    ),
                    const Gap(AppSpacing.xl),
                    TextField(
                      controller: pinCtrl,
                      decoration: InputDecoration(
                        labelText: 'New 6-Digit PIN',
                        errorText: errorText.value,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                    ),
                    const Gap(AppSpacing.md),
                    TextField(
                      controller: confirmCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Confirm PIN',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                    ),
                    const Gap(AppSpacing.lg),
                    FilledButton(
                      onPressed: loading.value ? null : submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, AppSpacing.touchPreferred),
                      ),
                      child: loading.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Set PIN'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
