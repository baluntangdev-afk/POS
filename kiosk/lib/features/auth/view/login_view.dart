import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../exceptions/exception_extension.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../validation/rules/is_required.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/pin_indicator.dart';
import '../../../widgets/pin_pad.dart';
import '../state/login_state_notifier.dart';
import 'username_input.dart';

class LoginView extends HookConsumerWidget {
  const LoginView({super.key, required this.isSmallHeight});

  final bool isSmallHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = useTextEditingController();
    final pin = useState('');
    final selectedButton = useState<int?>(null);
    final usernameError = useState<String?>(null);
    final loginError = useState<String?>(null);
    final isDialogShowing = useRef(false);

    ref.listen(loginStateProvider, (previous, next) {
      if (next.isLoading) {
        isDialogShowing.value = true;
        showDialog<void>(
          barrierDismissible: false,
          context: context,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
        return;
      }

      // Dismiss loading dialog only if we actually showed one
      if (isDialogShowing.value) {
        isDialogShowing.value = false;
        Navigator.of(context, rootNavigator: true).pop();
      }

      next.whenOrNull(
        data: (auth) {
          if (auth != null) {
            loginError.value = null;
            if (auth.isPinChanged) {
              const MenuRoute().go(context);
              return;
            }
            pin.value = '';
            showMessageDialog(
              context,
              message: 'You need to change your pin to proceed.',
              type: DialogType.warning,
              onPrimaryPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                SetupPinRoute(auth).push<void>(context);
              },
            );
          }
        },
        error: (error, stackTrace) {
          loginError.value = 'Login failed: ${error.message}';
          pin.value = '';
        },
      );
    });

    // Add listener to clear error when user starts typing
    useEffect(() {
      void listener() {
        if (usernameController.text.isNotEmpty && usernameError.value != null) {
          usernameError.value = null;
        }
      }

      usernameController.addListener(listener);
      return () => usernameController.removeListener(listener);
    }, [usernameController, usernameError.value]);

    void onNumberPressed(String number) {
      // Validate username before allowing PIN input
      final usernameValidationError = isRequired(message: 'Username is required.');
      if (usernameValidationError(usernameController.text) != null) {
        usernameError.value = usernameValidationError(usernameController.text);
        return;
      }

      // Clear username error if validation passes
      usernameError.value = null;
      loginError.value = null;

      if (pin.value.length < 6) {
        pin.value += number;

        // Auto-login when PIN is complete
        if (pin.value.length == 6 && usernameController.text.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 300), () {
            ref.read(loginStateProvider.notifier).login(usernameController.text, pin.value);
          });
        }
      }
    }

    void onBackspace() {
      if (pin.value.isNotEmpty) {
        loginError.value = null;
        pin.value = pin.value.substring(0, pin.value.length - 1);
      }
    }

    final buttonHeight = context.responsive.value<double>(kiosk: 72, tablet: 60, phone: 52);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: Padding(
              padding: context.responsive.value<EdgeInsets>(
                phone: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                tablet: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                kiosk: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // "Welcome back" heading
                  Text(
                    'Welcome back',
                    style: TextStyle(
                      color: ColorSet.dark,
                      fontSize: context.responsive.value<double>(
                        phone: 22,
                        tablet: 26,
                        kiosk: 28,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Gap(context.responsive.value<double>(phone: 8, tablet: 10, kiosk: 12)),
                  Text(
                    'Enter your username and PIN to continue.',
                    style: TextStyle(
                      color: ColorSet.dark.withValues(alpha: 0.5),
                      fontSize: context.responsive.value<double>(phone: 14, tablet: 16, kiosk: 18),
                    ),
                  ),
                  Gap(context.responsive.value<double>(phone: 20, tablet: 28, kiosk: 36)),
                  // Username field
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          context.responsive.value<double>(kiosk: 64, tablet: 56, phone: 48),
                    ),
                    child: UsernameInput(
                      controller: usernameController,
                      errorText: usernameError.value,
                    ),
                  ),
                  Gap(context.responsive.value<double>(phone: 20, tablet: 28, kiosk: 36)),
                  // PIN label
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth * 0.15,
                    ),
                    child: Text(
                      'PIN',
                      style: TextStyle(
                        color: ColorSet.dark.withValues(alpha: 0.7),
                        fontSize:
                            context.responsive.value<double>(phone: 14, tablet: 16, kiosk: 18),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Gap(context.responsive.value<double>(phone: 8, tablet: 10, kiosk: 12)),
                  PinIndicator(pin: pin.value),
                  Gap(context.responsive.value<double>(phone: 20, tablet: 28, kiosk: 36)),
                  PinPad(
                    onNumberPressed: onNumberPressed,
                    onBackspace: onBackspace,
                    selectedButton: selectedButton,
                  ),
                  // Error banner
                  if (loginError.value != null) ...[
                    Gap(context.responsive.value<double>(phone: 12, tablet: 14, kiosk: 16)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive.value<double>(phone: 16, tablet: 20, kiosk: 24),
                        vertical: context.responsive.value<double>(phone: 10, tablet: 12, kiosk: 14),
                      ),
                      decoration: BoxDecoration(
                        color: ColorSet.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ColorSet.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: ColorSet.danger,
                            size: context.responsive.value<double>(phone: 16, tablet: 18, kiosk: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              loginError.value!,
                              style: TextStyle(
                                color: ColorSet.danger,
                                fontSize: context.responsive.value<double>(
                                  phone: 13,
                                  tablet: 14,
                                  kiosk: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Gap(context.responsive.value<double>(phone: 12, tablet: 16, kiosk: 20)),
                  // Login button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.15),
                    child: SizedBox(
                      height: buttonHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: ColorSet.gradientBg,
                          ),
                          borderRadius: BorderRadius.circular(buttonHeight / 2),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(buttonHeight / 2),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(buttonHeight / 2),
                            onTap: () {
                              if (usernameController.text.isNotEmpty && pin.value.length == 6) {
                                ref.read(loginStateProvider.notifier).login(
                                  usernameController.text,
                                  pin.value,
                                );
                              }
                            },
                            child: Center(
                              child: Text(
                                'Login →',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: context.responsive.value<double>(
                                    phone: 16,
                                    tablet: 18,
                                    kiosk: 20,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Gap(context.responsive.value<double>(phone: 16, tablet: 20, kiosk: 24)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
