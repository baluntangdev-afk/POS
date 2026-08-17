import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../exceptions/cartivo_auth_exception.dart';
import '../../../exceptions/exception_extension.dart';
import '../../../gen/assets.gen.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../cartivo_auth/cartivo_validators.dart';
import '../../cartivo_auth/state/cartivo_auth_state_notifier.dart';
import 'cartivo_form_widgets.dart';

const _rateLimitCooldown = Duration(seconds: 30);

class CartivoLoginView extends HookConsumerWidget {
  const CartivoLoginView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final obscurePassword = useState(true);
    final emailError = useState<String?>(null);
    final passwordError = useState<String?>(null);
    final formError = useState<String?>(null);
    final cooldown = useState(0);

    useEffect(() {
      if (cooldown.value <= 0) return null;
      final timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (cooldown.value <= 1) {
          cooldown.value = 0;
        } else {
          cooldown.value -= 1;
        }
      });
      return timer.cancel;
    }, [cooldown.value > 0]);

    final authState = ref.watch(cartivoAuthStateProvider);
    final isSigningIn = authState.isLoading;

    ref.listen(cartivoAuthStateProvider, (previous, next) {
      next.whenOrNull(
        data: (auth) {
          if (auth != null) const CartivoHomeRoute().go(context);
        },
        error: (error, stackTrace) {
          if (error is CartivoAuthException) {
            formError.value = error.message;
            if (error.kind == CartivoAuthErrorKind.rateLimited) {
              cooldown.value = _rateLimitCooldown.inSeconds;
            }
          } else {
            formError.value = error.message;
          }
        },
      );
    });

    void handleSignIn() {
      if (isSigningIn || cooldown.value > 0) return;

      final emailValidation = CartivoValidators.email(emailController.text);
      final passwordValidation = CartivoValidators.password(passwordController.text);
      emailError.value = emailValidation;
      passwordError.value = passwordValidation;
      if (emailValidation != null || passwordValidation != null) return;

      formError.value = null;
      ref
          .read(cartivoAuthStateProvider.notifier)
          .login(email: emailController.text.trim(), password: passwordController.text);
    }

    final hPad = context.responsive.value<double>(phone: 28, tablet: 36, kiosk: 48);
    final vPad = context.responsive.value<double>(phone: 24, tablet: 28, kiosk: 36);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => const OrderSourceRoute().go(context),
              icon: const Icon(Icons.arrow_back_rounded, color: POSColors.textPrimary),
            ),
          ),
          const Gap(4),
          Center(
            child: Assets.images.cartivoLogo.image(
              height: context.responsive.value<double>(phone: 36, tablet: 42, kiosk: 48),
              fit: BoxFit.contain,
            ),
          ),
          const Gap(24),
          Text(
            'Sign in to your account.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: POSColors.textPrimary,
              fontSize: context.responsive.value<double>(phone: 24, tablet: 28, kiosk: 30),
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const Gap(8),
          Text(
            'Enter your email and password to sign in.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: POSColors.textTertiary,
              fontSize: context.responsive.value<double>(phone: 13, tablet: 14, kiosk: 15),
              fontWeight: FontWeight.w400,
            ),
          ),
          Gap(context.responsive.value<double>(phone: 28, tablet: 32, kiosk: 36)),
          CartivoTextField(
            label: 'Email',
            controller: emailController,
            hintText: 'yourname@example.com',
            keyboardType: TextInputType.emailAddress,
            errorText: emailError.value,
            onChanged: (_) => emailError.value = null,
          ),
          const Gap(20),
          CartivoTextField(
            label: 'Password',
            controller: passwordController,
            obscureText: obscurePassword.value,
            errorText: passwordError.value,
            onChanged: (_) => passwordError.value = null,
            onSubmitted: (_) => handleSignIn(),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword.value ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: POSColors.iconSubtle,
              ),
              onPressed: () => obscurePassword.value = !obscurePassword.value,
            ),
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Forgot Password?',
                style: TextStyle(
                  color: POSColors.textTertiary,
                  fontSize: context.responsive.value<double>(phone: 13, tablet: 14, kiosk: 14),
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () => const CartivoRegisterRoute().go(context),
                child: Text(
                  'Register',
                  style: TextStyle(
                    color: ColorSet.primary,
                    fontSize: context.responsive.value<double>(phone: 13, tablet: 14, kiosk: 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (formError.value != null) ...[
            const Gap(16),
            CartivoErrorBanner(message: formError.value!),
          ],
          if (cooldown.value > 0) ...[
            const Gap(8),
            Text(
              'Try again in ${cooldown.value}s.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: POSColors.textTertiary,
                fontSize: context.responsive.value<double>(phone: 12, tablet: 13, kiosk: 13),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          Gap(context.responsive.value<double>(phone: 24, tablet: 28, kiosk: 32)),
          CartivoSubmitButton(
            isLoading: isSigningIn,
            isDisabled: cooldown.value > 0,
            label: 'Sign In',
            onPressed: handleSignIn,
          ),
        ],
      ),
    );
  }
}
