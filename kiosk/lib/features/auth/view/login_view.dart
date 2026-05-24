import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../exceptions/exception_extension.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
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
          builder: (_) => _LoginLoadingDialog(),
        );
        return;
      }

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
              message: 'You need to change your PIN to continue.',
              type: DialogType.warning,
              primaryButtonText: 'Change PIN',
              onPrimaryPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                SetupPinRoute(auth).push<void>(context);
              },
            );
          }
        },
        error: (error, stackTrace) {
          loginError.value = error.message;
          pin.value = '';
        },
      );
    });

    useEffect(() {
      void listener() {
        if (usernameController.text.isNotEmpty && usernameError.value != null) {
          usernameError.value = null;
        }
      }

      usernameController.addListener(listener);
      return () => usernameController.removeListener(listener);
    }, [usernameController, usernameError.value]);

    void attemptLogin() {
      if (usernameController.text.isNotEmpty && pin.value.length == 6) {
        ref.read(loginStateProvider.notifier).login(usernameController.text, pin.value);
      }
    }

    void onNumberPressed(String number) {
      final usernameValidationError = isRequired(message: 'Username is required.');
      if (usernameValidationError(usernameController.text) != null) {
        usernameError.value = usernameValidationError(usernameController.text);
        return;
      }

      usernameError.value = null;
      loginError.value = null;

      if (pin.value.length < 6) {
        pin.value += number;

        if (pin.value.length == 6 && usernameController.text.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 300), attemptLogin);
        }
      }
    }

    void onBackspace() {
      if (pin.value.isNotEmpty) {
        loginError.value = null;
        pin.value = pin.value.substring(0, pin.value.length - 1);
      }
    }

    final hPad = context.responsive.value<double>(phone: 28, tablet: 36, kiosk: 48);
    final vPad = context.responsive.value<double>(phone: 24, tablet: 28, kiosk: 36);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sign In',
            style: TextStyle(
              color: POSColors.textPrimary,
              fontSize: context.responsive.value<double>(phone: 26, tablet: 30, kiosk: 34),
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your username and 6-digit PIN',
            style: TextStyle(
              color: POSColors.textTertiary,
              fontSize: context.responsive.value<double>(phone: 13, tablet: 14, kiosk: 15),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          Gap(context.responsive.value<double>(phone: 28, tablet: 32, kiosk: 36)),
          UsernameInput(
            controller: usernameController,
            errorText: usernameError.value,
          ),
          Gap(context.responsive.value<double>(phone: 24, tablet: 28, kiosk: 32)),
          _PinSection(pin: pin.value),
          Gap(context.responsive.value<double>(phone: 24, tablet: 28, kiosk: 32)),
          PinPad(
            onNumberPressed: onNumberPressed,
            onBackspace: onBackspace,
            onConfirm: attemptLogin,
            selectedButton: selectedButton,
          ),
          if (loginError.value != null) ...[
            Gap(context.responsive.value<double>(phone: 16, tablet: 18, kiosk: 20)),
            _ErrorBanner(message: loginError.value!),
          ],
          Gap(context.responsive.value<double>(phone: 16, tablet: 20, kiosk: 24)),
        ],
      ),
    );
  }
}

class _PinSection extends StatelessWidget {
  const _PinSection({required this.pin});

  final String pin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'PIN',
          style: TextStyle(
            fontSize: context.responsive.value<double>(phone: 11, tablet: 12, kiosk: 13),
            fontWeight: FontWeight.w600,
            color: POSColors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        PinIndicator(pin: pin, color: ColorSet.primary),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: POSAnimation.normal,
      opacity: 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: ColorSet.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(POSRadius.md),
          border: Border.all(color: ColorSet.danger.withValues(alpha: 0.25), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ColorSet.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded, color: ColorSet.danger, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: ColorSet.danger,
                  fontSize: context.responsive.value<double>(phone: 13, tablet: 14, kiosk: 15),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginLoadingDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(POSRadius.xl),
          boxShadow: POSShadow.elevated,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: ColorSet.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: ColorSet.primary,
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Signing in...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: POSColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
