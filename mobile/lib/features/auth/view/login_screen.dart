import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../entities/user_entity.dart';
import '../state/auth_providers.dart';
import '../state/auth_state.dart';
import 'widgets/auth_card.dart';
import 'widgets/pin_dots.dart';
import 'widgets/pin_keypad.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = useState<List<UserEntity>>([]);
    final selectedUser = useState<UserEntity?>(null);
    final pinDigits = useState<String>('');
    final isLoading = useState(false);
    final errorMsg = useState<String?>(null);

    final authNotifier = ref.read(authNotifierProvider.notifier);

    useEffect(() {
      authNotifier.loadUsers().then((list) => users.value = list);
      return null;
    }, []);

    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next is AuthAuthenticated) {
        context.go('/dashboard');
      } else if (next is AuthError) {
        errorMsg.value = next.message;
        pinDigits.value = '';
        isLoading.value = false;
        authNotifier.clearError();
      }
    });

    void appendDigit(String digit) {
      if (pinDigits.value.length >= 6) return;
      pinDigits.value += digit;
      if (pinDigits.value.length == 6 && selectedUser.value != null) {
        isLoading.value = true;
        authNotifier.login(selectedUser.value!.id, pinDigits.value);
      }
    }

    void deleteDigit() {
      if (pinDigits.value.isEmpty) return;
      pinDigits.value = pinDigits.value.substring(
        0,
        pinDigits.value.length - 1,
      );
      errorMsg.value = null;
    }

    void backToUserSelection() {
      selectedUser.value = null;
      pinDigits.value = '';
      errorMsg.value = null;
    }

    return PopScope(
      canPop: selectedUser.value == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        backToUserSelection();
      },
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
                                selectedUser.value != null
                                    ? IconButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: backToUserSelection,
                                      icon: const Icon(
                                        Icons.arrow_back,
                                        size: 20,
                                      ),
                                      tooltip: 'Back',
                                    )
                                    : null,
                          ),
                          Expanded(
                            child: Text(
                              'Mobile POS',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.headingLg.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          final offsetAnimation = Tween<Offset>(
                            begin: Offset(
                              child.key == const ValueKey('user-selection')
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
                        child:
                            selectedUser.value == null
                                ? Column(
                                  key: const ValueKey('user-selection'),
                                  children: [
                                    Text(
                                      'Select your account',
                                      style: AppTextStyles.headingMd,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    _UserGrid(
                                      users: users.value,
                                      onSelect: (u) {
                                        selectedUser.value = u;
                                        errorMsg.value = null;
                                        pinDigits.value = '';
                                      },
                                    ),
                                  ],
                                )
                                : Column(
                                  key: const ValueKey('pin-input'),
                                  children: [
                                    Text(
                                      selectedUser.value!.name,
                                      style: AppTextStyles.headingLg,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    PinDots(length: pinDigits.value.length),
                                    const SizedBox(height: AppSpacing.sm),
                                    if (errorMsg.value != null)
                                      Text(
                                        errorMsg.value!,
                                        style: AppTextStyles.bodyMd.copyWith(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    const SizedBox(height: AppSpacing.lg),
                                    PinKeypad(
                                      onDigit: appendDigit,
                                      onDelete: deleteDigit,
                                      disabled: isLoading.value,
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

class _UserGrid extends StatelessWidget {
  final List<UserEntity> users;
  final ValueChanged<UserEntity> onSelect;

  const _UserGrid({required this.users, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const CircularProgressIndicator();
    }
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.0,
      ),
      itemCount: users.length,
      itemBuilder: (_, i) {
        final user = users[i];
        return InkWell(
          onTap: () => onSelect(user),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.primary,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: AppTextStyles.headingLg.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  user.name,
                  style: AppTextStyles.labelLg,
                  textAlign: TextAlign.center,
                ),
                Text(
                  user.role,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
