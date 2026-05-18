import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../exceptions/exception_extension.dart';
import '../../../gen/assets.gen.dart';
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
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: ${error.message}'),
              backgroundColor: ColorSet.danger,
              duration: const Duration(seconds: 2),
            ),
          );
          // Clear PIN on error
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter username first'),
            backgroundColor: ColorSet.danger,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Clear username error if validation passes
      usernameError.value = null;

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
        pin.value = pin.value.substring(0, pin.value.length - 1);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: Column(
              children: [
                Padding(
                  padding: context.responsive.value<EdgeInsets>(
                    phone: const EdgeInsets.only(left: 100.0, right: 100, top: 80),
                    tablet: const EdgeInsets.only(left: 100.0, right: 100, top: 100),
                    kiosk: const EdgeInsets.only(left: 100.0, right: 100, top: 150),
                  ),
                  child: Assets.images.png.onboardingLogo.image(
                    color: Colors.white,
                    width: context.responsive.scale(400),
                    height: context.responsive.scale(100),
                  ),
                ),
                Gap(context.responsive.value<double>(phone: 30, tablet: 40, kiosk: 50)),
                UsernameInput(controller: usernameController, errorText: usernameError.value),
                Gap(context.responsive.value<double>(phone: 30, tablet: 40, kiosk: 50)),
                PinIndicator(pin: pin.value),
                Gap(context.responsive.value<double>(phone: 30, tablet: 40, kiosk: 50)),
                PinPad(
                  onNumberPressed: onNumberPressed,
                  onBackspace: onBackspace,
                  selectedButton: selectedButton,
                ),
                Gap(context.responsive.value<double>(phone: 20, tablet: 30, kiosk: 40)),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Forget PIN?',
                    style: TextStyle(
                      color: ColorSet.userDetails,
                      fontSize: context.responsive.value<double>(phone: 14, tablet: 18, kiosk: 22),
                      fontWeight: FontWeight.w600,
                    ),
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
