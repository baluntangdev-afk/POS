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

class CartivoRegisterView extends HookConsumerWidget {
  const CartivoRegisterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final obscurePassword = useState(true);
    final obscureConfirmPassword = useState(true);
    final emailError = useState<String?>(null);
    final passwordError = useState<String?>(null);
    final confirmPasswordError = useState<String?>(null);
    final formError = useState<String?>(null);
    final showLoginLink = useState(false);

    final authState = ref.watch(cartivoAuthStateProvider);
    final isSubmitting = authState.isLoading;

    ref.listen(cartivoAuthStateProvider, (previous, next) {
      next.whenOrNull(
        data: (auth) {
          if (auth != null) const CartivoHomeRoute().go(context);
        },
        error: (error, stackTrace) {
          if (error is CartivoAuthException) {
            formError.value = error.message;
            showLoginLink.value = error.kind == CartivoAuthErrorKind.emailTaken;
          } else {
            formError.value = error.message;
            showLoginLink.value = false;
          }
        },
      );
    });

    void handleRegister() {
      if (isSubmitting) return;

      final emailValidation = CartivoValidators.email(emailController.text);
      final passwordValidation = CartivoValidators.password(passwordController.text);
      final confirmValidation = CartivoValidators.confirmPassword(
        confirmPasswordController.text,
        passwordController.text,
      );
      emailError.value = emailValidation;
      passwordError.value = passwordValidation;
      confirmPasswordError.value = confirmValidation;
      if (emailValidation != null || passwordValidation != null || confirmValidation != null) {
        return;
      }

      formError.value = null;
      showLoginLink.value = false;
      final name = nameController.text.trim();
      ref
          .read(cartivoAuthStateProvider.notifier)
          .register(
            email: emailController.text.trim(),
            password: passwordController.text,
            name: name.isEmpty ? null : name,
          );
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
              onPressed: () => const CartivoLoginRoute().go(context),
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
            'Create your account.',
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
            'Sign up with your email to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: POSColors.textTertiary,
              fontSize: context.responsive.value<double>(phone: 13, tablet: 14, kiosk: 15),
              fontWeight: FontWeight.w400,
            ),
          ),
          Gap(context.responsive.value<double>(phone: 28, tablet: 32, kiosk: 36)),
          CartivoTextField(
            label: 'Name (optional)',
            controller: nameController,
            hintText: 'Juan Dela Cruz',
            keyboardType: TextInputType.name,
          ),
          const Gap(20),
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
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword.value ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: POSColors.iconSubtle,
              ),
              onPressed: () => obscurePassword.value = !obscurePassword.value,
            ),
          ),
          const Gap(20),
          CartivoTextField(
            label: 'Confirm Password',
            controller: confirmPasswordController,
            obscureText: obscureConfirmPassword.value,
            errorText: confirmPasswordError.value,
            onChanged: (_) => confirmPasswordError.value = null,
            onSubmitted: (_) => handleRegister(),
            suffixIcon: IconButton(
              icon: Icon(
                obscureConfirmPassword.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: POSColors.iconSubtle,
              ),
              onPressed: () => obscureConfirmPassword.value = !obscureConfirmPassword.value,
            ),
          ),
          const Gap(16),
          Align(
            alignment: Alignment.center,
            child: GestureDetector(
              onTap: () => const CartivoLoginRoute().go(context),
              child: Text.rich(
                TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(
                    color: POSColors.textTertiary,
                    fontSize: context.responsive.value<double>(phone: 13, tablet: 14, kiosk: 14),
                    fontWeight: FontWeight.w400,
                  ),
                  children: [
                    TextSpan(
                      text: 'Log in',
                      style: TextStyle(color: ColorSet.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (formError.value != null) ...[
            const Gap(16),
            CartivoErrorBanner(message: formError.value!),
            if (showLoginLink.value) ...[
              const Gap(8),
              Center(
                child: TextButton(
                  onPressed: () => const CartivoLoginRoute().go(context),
                  child: const Text('Log in instead'),
                ),
              ),
            ],
          ],
          Gap(context.responsive.value<double>(phone: 24, tablet: 28, kiosk: 32)),
          CartivoSubmitButton(isLoading: isSubmitting, label: 'Create Account', onPressed: handleRegister),
        ],
      ),
    );
  }
}
