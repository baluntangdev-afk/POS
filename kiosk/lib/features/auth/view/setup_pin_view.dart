import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../exceptions/exception_extension.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../styles/type_set.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/pin_indicator.dart';
import '../../../widgets/pin_pad.dart';
import '../../../widgets/top_app_bar.dart';
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

        // Current child animation
        final Widget currentChild = Transform.translate(
          offset: Offset((1.0 - _animation.value) * (_isSetupPin ? -screenWidth : screenWidth), 0),
          child: Opacity(
            opacity: _animation.value,
            child: Transform.scale(scale: 0.95 + (0.05 * _animation.value), child: widget.child),
          ),
        );

        // Previous child animation (exit)
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
  const SetupPinView({super.key, required this.isSmallHeight, required this.auth});

  final bool isSmallHeight;
  final Auth auth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pin = useState('');
    final confirmPin = useState('');
    final currentPinState = useState<PinType>(PinType.setup);
    final isGoingForward = useState(true);

    final selectedButton = useState<int?>(null);
    final isDialogShowing = useRef(false);

    void onNumberPressed(String number) {
      final currentPin = currentPinState.value == PinType.setup ? pin : confirmPin;

      if (currentPin.value.length < 6) {
        currentPin.value += number;

        // Auto-login when PIN is complete
        if (currentPin.value.length == 6) {
          if (currentPinState.value == PinType.setup) {
            isGoingForward.value = true;
            currentPinState.value = PinType.confirm;
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
      final currentPin = currentPinState.value == PinType.setup ? pin : confirmPin;

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
            'Set you personal 6-digit pin to protect your account. It will be used for fast and secure login',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.responsive.value<double>(phone: 18, tablet: 22, kiosk: 25),
            ),
          ),
          Gap(context.responsive.value<double>(phone: 30, tablet: 40, kiosk: 50)),
          PinIndicator(pin: pin.value, color: ColorSet.primary),
          Gap(context.responsive.value<double>(phone: 30, tablet: 40, kiosk: 50)),
          PinPad(
            onNumberPressed: onNumberPressed,
            onBackspace: onBackspace,
            selectedButton: selectedButton,
          ),
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
              fontSize: context.responsive.value<double>(phone: 18, tablet: 22, kiosk: 25),
            ),
          ),
          Gap(context.responsive.value<double>(phone: 30, tablet: 40, kiosk: 50)),
          PinIndicator(pin: confirmPin.value, color: ColorSet.primary),
          Gap(context.responsive.value<double>(phone: 30, tablet: 40, kiosk: 50)),
          PinPad(
            onNumberPressed: onNumberPressed,
            onBackspace: onBackspace,
            selectedButton: selectedButton,
          ),
          Gap(context.responsive.value<double>(phone: 20, tablet: 30, kiosk: 40)),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Gap(context.responsive.value<double>(phone: 30, tablet: 40, kiosk: 50)),
                    Padding(
                      padding: context.responsive.value<EdgeInsets>(
                        phone: const EdgeInsets.only(left: 100.0, right: 100, top: 80),
                        tablet: const EdgeInsets.only(left: 100.0, right: 100, top: 100),
                        kiosk: const EdgeInsets.only(left: 100.0, right: 100, top: 150),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: ColorSet.gradientBg,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: Icon(
                                  Icons.lock,
                                  size: context.responsive.value<double>(
                                    phone: 50,
                                    tablet: 70,
                                    kiosk: 100,
                                  ),
                                  color: ColorSet.background,
                                ),
                              ),
                            ),
                            Gap(context.responsive.value<double>(phone: 30, tablet: 40, kiosk: 50)),
                            _CustomPageTransition(
                              isSetupPin: currentPinState.value == PinType.setup,
                              child: ColoredBox(
                                color: ColorSet.background,
                                key: ValueKey<PinType>(currentPinState.value),
                                child:
                                    currentPinState.value == PinType.setup
                                        ? setUpPinView()
                                        : confirmPinView(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox.fromSize(
              size: Size.fromHeight(context.responsive.value(kiosk: 120, tablet: 90, phone: 70)),
              child: TopAppBar(
                onBackPressed: () {
                  switch (currentPinState.value) {
                    case PinType.setup:
                      const LoginRoute().go(context);
                    case PinType.confirm:
                      isGoingForward.value = false;
                      currentPinState.value = PinType.setup;
                  }
                },
                title: '',
              ),
            ),
          ],
        );
      },
    );
  }
}
