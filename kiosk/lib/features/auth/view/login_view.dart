import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../gen/assets.gen.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../validation/rules/is_required.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/numeric_keypad.dart';
import '../../../widgets/pin_indicator.dart';
import '../../../widgets/pin_pad.dart';
import '../state/login_state_notifier.dart';
import 'username_input.dart';

/// Login screen content.
///
/// Renders one of three layouts based on the device form factor:
///   [K] Split panel — 420 px left gradient brand panel + white login card.
///   [W] Single column — top gradient banner (120 px) + white rounded card.
///   [A] Same as [W] with SafeArea, Android safe-area bottom inset,
///       and [NumericKeypad] (Material ripple) instead of [PinPad].
class LoginView extends HookConsumerWidget {
  const LoginView({super.key, required this.isSmallHeight});

  final bool isSmallHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ─── State ────────────────────────────────────────────────────────────────
    final usernameController = useTextEditingController();
    final pin = useState('');
    final selectedButton = useState<int?>(null);
    final usernameError = useState<String?>(null);
    final isDialogShowing = useRef(false);

    // ─── Auth listener ────────────────────────────────────────────────────────
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

      if (isDialogShowing.value) {
        isDialogShowing.value = false;
        Navigator.of(context, rootNavigator: true).pop();
      }

      next.whenOrNull(
        data: (auth) {
          if (auth != null) {
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
          showNetworkErrorDialog(context, error: error);
          pin.value = '';
        },
      );
    });

    // Clear username error as the user types.
    useEffect(() {
      void listener() {
        if (usernameController.text.isNotEmpty && usernameError.value != null) {
          usernameError.value = null;
        }
      }

      usernameController.addListener(listener);
      return () => usernameController.removeListener(listener);
    }, [usernameController, usernameError.value]);

    // ─── Callbacks ────────────────────────────────────────────────────────────
    void onNumberPressed(String number) {
      final validate = isRequired(message: 'Username is required.');
      if (validate(usernameController.text) != null) {
        usernameError.value = validate(usernameController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter username first'),
            backgroundColor: ColorSet.danger,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      usernameError.value = null;

      if (pin.value.length < 6) {
        pin.value += number;
        if (pin.value.length == 6 && usernameController.text.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 300), () {
            ref
                .read(loginStateProvider.notifier)
                .login(usernameController.text, pin.value);
          });
        }
      }
    }

    void onBackspace() {
      if (pin.value.isNotEmpty) {
        pin.value = pin.value.substring(0, pin.value.length - 1);
      }
    }

    void onLoginTap() {
      if (pin.value.length == 6 && usernameController.text.isNotEmpty) {
        ref
            .read(loginStateProvider.notifier)
            .login(usernameController.text, pin.value);
      }
    }

    // ─── Form-factor routing ──────────────────────────────────────────────────
    final bp = context.breakpoint;

    if (bp.isKiosk) {
      return _KioskLoginContent(
        usernameController: usernameController,
        pin: pin.value,
        selectedButton: selectedButton,
        usernameError: usernameError.value,
        onNumberPressed: onNumberPressed,
        onBackspace: onBackspace,
        onLoginTap: onLoginTap,
      );
    }

    if (bp.isAndroid) {
      return _AndroidLoginContent(
        usernameController: usernameController,
        pin: pin.value,
        usernameError: usernameError.value,
        onNumberPressed: onNumberPressed,
        onBackspace: onBackspace,
        onLoginTap: onLoginTap,
        isSmallHeight: isSmallHeight,
      );
    }

    // Windows tablet (default).
    return _TabletLoginContent(
      usernameController: usernameController,
      pin: pin.value,
      selectedButton: selectedButton,
      usernameError: usernameError.value,
      onNumberPressed: onNumberPressed,
      onBackspace: onBackspace,
      isSmallHeight: isSmallHeight,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kiosk — left gradient brand panel (420 px) + right white login card
// ─────────────────────────────────────────────────────────────────────────────

class _KioskLoginContent extends StatelessWidget {
  const _KioskLoginContent({
    required this.usernameController,
    required this.pin,
    required this.selectedButton,
    required this.usernameError,
    required this.onNumberPressed,
    required this.onBackspace,
    required this.onLoginTap,
  });

  final TextEditingController usernameController;
  final String pin;
  final ValueNotifier<int?> selectedButton;
  final String? usernameError;
  final void Function(String) onNumberPressed;
  final VoidCallback onBackspace;
  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Row(
      children: [
        // ── Left brand panel ──────────────────────────────────────────────────
        Container(
          width: 420,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: ColorSet.gradientBg,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Assets.images.png.onboardingLogo.image(
              color: Colors.white,
              width: 300,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
        ),

        // ── Right login card ──────────────────────────────────────────────────
        Expanded(
          child: ColoredBox(
            color: Colors.white,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: r.spacingXl,
                    horizontal: r.spacingXl,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Login to your account',
                        style: TextStyle(
                          fontSize: r.fontHeading,
                          fontWeight: FontWeight.w700,
                          color: ColorSet.welcomeText,
                        ),
                      ),
                      Gap(r.spacingXl),
                      UsernameInput(
                        controller: usernameController,
                        errorText: usernameError,
                      ),
                      Gap(r.spacingLg),
                      PinIndicator(pin: pin),
                      Gap(r.spacingLg),
                      PinPad(
                        onNumberPressed: onNumberPressed,
                        onBackspace: onBackspace,
                        selectedButton: selectedButton,
                      ),
                      Gap(r.spacingLg),
                      _LoginButton(
                        height: r.primaryBtnHeight,
                        enabled: pin.length == 6,
                        onTap: onLoginTap,
                      ),
                      Gap(r.spacingMd),
                      _ForgotPinButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Windows tablet — top gradient banner + white rounded card
// ─────────────────────────────────────────────────────────────────────────────

class _TabletLoginContent extends StatelessWidget {
  const _TabletLoginContent({
    required this.usernameController,
    required this.pin,
    required this.selectedButton,
    required this.usernameError,
    required this.onNumberPressed,
    required this.onBackspace,
    required this.isSmallHeight,
  });

  final TextEditingController usernameController;
  final String pin;
  final ValueNotifier<int?> selectedButton;
  final String? usernameError;
  final void Function(String) onNumberPressed;
  final VoidCallback onBackspace;
  final bool isSmallHeight;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return SizedBox.expand(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: ColorSet.gradientBg,
          ),
        ),
        child: Column(
          children: [
            // Top banner — logo centred in 120 dp area.
            SizedBox(
              height: isSmallHeight ? 80 : 120,
              child: Center(
                child: Assets.images.png.onboardingLogo.image(
                  color: Colors.white,
                  height: isSmallHeight ? 44 : 60,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // White card that fills remaining space.
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    vertical: r.spacingLg,
                    horizontal: r.hPagePadding,
                  ),
                  child: Column(
                    children: [
                      UsernameInput(
                        controller: usernameController,
                        errorText: usernameError,
                      ),
                      Gap(r.spacingLg),
                      PinIndicator(pin: pin),
                      Gap(r.spacingLg),
                      PinPad(
                        onNumberPressed: onNumberPressed,
                        onBackspace: onBackspace,
                        selectedButton: selectedButton,
                      ),
                      Gap(r.spacingMd),
                      _ForgotPinButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Android tablet — top gradient banner + white card + SafeArea + NumericKeypad
// ─────────────────────────────────────────────────────────────────────────────

class _AndroidLoginContent extends StatelessWidget {
  const _AndroidLoginContent({
    required this.usernameController,
    required this.pin,
    required this.usernameError,
    required this.onNumberPressed,
    required this.onBackspace,
    required this.onLoginTap,
    required this.isSmallHeight,
  });

  final TextEditingController usernameController;
  final String pin;
  final String? usernameError;
  final void Function(String) onNumberPressed;
  final VoidCallback onBackspace;
  final VoidCallback onLoginTap;
  final bool isSmallHeight;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return SizedBox.expand(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: ColorSet.gradientBg,
          ),
        ),
        child: Column(
          children: [
            // Top banner — respects status-bar inset so logo stays below it.
            SafeArea(
              bottom: false,
              child: SizedBox(
                height: isSmallHeight ? 60 : 100,
                child: Center(
                  child: Assets.images.png.onboardingLogo.image(
                    color: Colors.white,
                    height: isSmallHeight ? 36 : 52,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // White card.
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  // resizeToAvoidBottomInset handles keyboard from username field.
                  padding: EdgeInsets.fromLTRB(
                    24,
                    r.spacingLg,
                    24,
                    24 + bottomInset,
                  ),
                  child: Column(
                    children: [
                      // Username — system keyboard opens here.
                      UsernameInput(
                        controller: usernameController,
                        errorText: usernameError,
                      ),
                      Gap(r.spacingLg),
                      // PIN dots — driven by NumericKeypad, no system keyboard.
                      PinIndicator(pin: pin),
                      Gap(r.spacingLg),
                      // Material ripple keypad; backing is not a TextField so
                      // the Android system keyboard never appears for PIN input.
                      NumericKeypad(
                        onKeyPressed: onNumberPressed,
                        onBackspace: onBackspace,
                      ),
                      Gap(r.spacingLg),
                      _LoginButton(
                        height: 60,
                        enabled: pin.length == 6,
                        onTap: onLoginTap,
                      ),
                      Gap(r.spacingMd),
                      _ForgotPinButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.height,
    required this.enabled,
    required this.onTap,
  });

  final double height;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = enabled;
    return GestureDetector(
      onTap: active ? onTap : null,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(colors: ColorSet.gradientBg)
              : null,
          color: active ? null : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Center(
          child: Text(
            'Login',
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF9E9E9E),
              fontSize: context.responsive.fontBody,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ForgotPinButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {},
      child: Text(
        'Forgot PIN?',
        style: TextStyle(
          color: ColorSet.userDetails,
          fontSize: context.responsive.value<double>(phone: 14, tablet: 18, kiosk: 22),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
