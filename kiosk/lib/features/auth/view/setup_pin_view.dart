import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../exceptions/exception_extension.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../styles/type_set.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/numeric_keypad.dart';
import '../../../widgets/pin_indicator.dart';
import '../../../widgets/pin_pad.dart';
import '../entities/auth.dart';
import '../state/change_pin_notifier.dart';

enum PinType { setup, confirm }

class _CustomPageTransition extends StatefulWidget {
  const _CustomPageTransition({required this.child, required this.isSetupPin});

  final Widget child;
  final bool isSetupPin;

  @override
  State<_CustomPageTransition> createState() => _CustomPageTransitionState();
}

class _CustomPageTransitionState extends State<_CustomPageTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Widget? _previousChild;
  bool _isSetupPin = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _isSetupPin = widget.isSetupPin;
    _controller.forward();
  }

  @override
  void didUpdateWidget(_CustomPageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSetupPin != _isSetupPin) {
      _previousChild = oldWidget.child;
      _isSetupPin = widget.isSetupPin;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;

        final Widget currentChild = Transform.translate(
          offset: Offset((1.0 - _animation.value) * (_isSetupPin ? -screenWidth : screenWidth), 0),
          child: Opacity(
            opacity: _animation.value,
            child: Transform.scale(scale: 0.95 + (0.05 * _animation.value), child: widget.child),
          ),
        );

        Widget? previousChild;
        if (_previousChild != null) {
          previousChild = Transform.translate(
            offset: Offset(_animation.value * (_isSetupPin ? screenWidth : -screenWidth), 0),
            child: Opacity(
              opacity: 1.0 - _animation.value,
              child: Transform.scale(scale: 1.0 - (0.05 * _animation.value), child: _previousChild),
            ),
          );
        }

        return Stack(children: [if (previousChild != null) previousChild, currentChild]);
      },
    );
  }
}

class SetupPinView extends HookConsumerWidget {
  const SetupPinView({
    super.key,
    required this.isSmallHeight,
    required this.auth,
    required this.pinTypeNotifier,
  });

  final bool isSmallHeight;
  final Auth auth;
  final ValueNotifier<PinType> pinTypeNotifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useListenable(pinTypeNotifier);

    final pin = useState('');
    final confirmPin = useState('');
    final selectedButton = useState<int?>(null);
    final isDialogShowing = useRef(false);

    void onNumberPressed(String number) {
      final currentPin = pinTypeNotifier.value == PinType.setup ? pin : confirmPin;

      if (currentPin.value.length < 6) {
        currentPin.value += number;

        if (currentPin.value.length == 6) {
          if (pinTypeNotifier.value == PinType.setup) {
            pinTypeNotifier.value = PinType.confirm;
            return;
          }
          if (pin.value != confirmPin.value) {
            showMessageDialog(
              context,
              message: 'Pins do not match',
              type: DialogType.error,
              onPrimaryPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                currentPin.value = '';
              },
            );
            return;
          }
          ref.read(changePinProvider.notifier).changePin(auth.id, pin.value);
        }
      }
    }

    void onBackspace() {
      final currentPin = pinTypeNotifier.value == PinType.setup ? pin : confirmPin;
      if (currentPin.value.isNotEmpty) {
        currentPin.value = currentPin.value.substring(0, currentPin.value.length - 1);
      }
    }

    ref.listen(changePinProvider, (previous, next) {
      if (next.isLoading) {
        isDialogShowing.value = true;
        showDialog<void>(
          barrierDismissible: false,
          context: context,
          builder: (_) => const Center(
          child: CircularProgressIndicator(
            color: ColorSet.primary,
            strokeWidth: 3,
            strokeCap: StrokeCap.round,
          ),
        ),
        );
        return;
      }

      if (isDialogShowing.value) {
        isDialogShowing.value = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
      next.whenOrNull(
        data: (isChanged) {
          if (isChanged) {
            showMessageDialog(
              context,
              message: 'User pin has been updated successfully. Please Login again.',
              type: DialogType.success,
              onPrimaryPressed: () {
                const LoginRoute().go(context);
              },
            );
          }
        },
        error: (error, stackTrace) {
          showMessageDialog(context, message: error.message, type: DialogType.error);
        },
      );
    });

    final isAndroid = context.breakpoint.isAndroid;

    Widget buildKeypad() {
      if (isAndroid) {
        return NumericKeypad(onKeyPressed: onNumberPressed, onBackspace: onBackspace);
      }
      return PinPad(
        onNumberPressed: onNumberPressed,
        onBackspace: onBackspace,
        selectedButton: selectedButton,
      );
    }

    Widget setUpPinView() {
      return Column(
        children: [
          Text(
            'Create your pin',
            style: TypeSet.h5.copyWith(
              fontSize: context.responsive.value<double>(phone: 18, tablet: 26, kiosk: 28),
            ),
          ),
          Gap(context.responsive.value<double>(phone: 10, tablet: 15, kiosk: 20)),
          Text(
            'Set your personal 6-digit pin to protect your account. It will be used for fast and secure login',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.responsive.value<double>(phone: 14, tablet: 18, kiosk: 20),
              color: POSColors.textTertiary,
            ),
          ),
          Gap(context.responsive.value<double>(phone: 30, tablet: 40, kiosk: 50)),
          PinIndicator(pin: pin.value, color: ColorSet.primary),
          Gap(context.responsive.value<double>(phone: 30, tablet: 40, kiosk: 50)),
          buildKeypad(),
          Gap(context.responsive.value<double>(phone: 20, tablet: 30, kiosk: 40)),
        ],
      );
    }

    Widget confirmPinView() {
      return Column(
        children: [
          Text(
            'Confirm your pin',
            style: TypeSet.h5.copyWith(
              fontSize: context.responsive.value<double>(phone: 18, tablet: 26, kiosk: 28),
            ),
          ),
          Gap(context.responsive.value<double>(phone: 10, tablet: 15, kiosk: 20)),
          Text(
            'Make sure to enter the same pin you set earlier.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.responsive.value<double>(phone: 14, tablet: 18, kiosk: 20),
              color: POSColors.textTertiary,
            ),
          ),
          Gap(context.responsive.value<double>(phone: 30, tablet: 40, kiosk: 50)),
          PinIndicator(pin: confirmPin.value, color: ColorSet.primary),
          Gap(context.responsive.value<double>(phone: 30, tablet: 40, kiosk: 50)),
          buildKeypad(),
          Gap(context.responsive.value<double>(phone: 20, tablet: 30, kiosk: 40)),
        ],
      );
    }

    Widget wrapWithPopScope(Widget child) {
      if (!isAndroid) return child;
      return PopScope(
        canPop: pinTypeNotifier.value == PinType.setup,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && pinTypeNotifier.value == PinType.confirm) {
            pinTypeNotifier.value = PinType.setup;
          }
        },
        child: child,
      );
    }

    return wrapWithPopScope(
      LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: context.responsive.value<EdgeInsets>(
                  phone: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  tablet: const EdgeInsets.symmetric(horizontal: 60, vertical: 60),
                  kiosk: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CustomPageTransition(
                      isSetupPin: pinTypeNotifier.value == PinType.setup,
                      child: ColoredBox(
                        color: Colors.white,
                        key: ValueKey<PinType>(pinTypeNotifier.value),
                        child: pinTypeNotifier.value == PinType.setup
                            ? setUpPinView()
                            : confirmPinView(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
