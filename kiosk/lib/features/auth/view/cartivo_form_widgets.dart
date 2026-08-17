import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';

class CartivoTextField extends StatelessWidget {
  const CartivoTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: POSColors.textPrimary,
            fontSize: context.responsive.value<double>(phone: 13, tablet: 14, kiosk: 14),
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: TextStyle(
            color: POSColors.textPrimary,
            fontSize: context.responsive.value<double>(phone: 15, tablet: 16, kiosk: 16),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: POSColors.textDisabled),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: POSColors.surfaceSubtle,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(POSRadius.md),
              borderSide: BorderSide(color: POSColors.borderDefault),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(POSRadius.md),
              borderSide: BorderSide(color: hasError ? ColorSet.danger : POSColors.borderDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(POSRadius.md),
              borderSide: BorderSide(color: hasError ? ColorSet.danger : ColorSet.primary, width: 1.5),
            ),
          ),
        ),
        if (hasError) ...[
          const Gap(6),
          Text(
            errorText!,
            style: TextStyle(
              color: ColorSet.danger,
              fontSize: context.responsive.value<double>(phone: 12, tablet: 13, kiosk: 13),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class CartivoSubmitButton extends StatelessWidget {
  const CartivoSubmitButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    this.isDisabled = false,
    required this.label,
  });

  final bool isLoading;
  final bool isDisabled;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = isLoading || isDisabled;
    return SizedBox(
      width: double.infinity,
      height: context.responsive.value<double>(phone: 52, tablet: 56, kiosk: 60),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: POSGradient.primaryFaded,
            borderRadius: BorderRadius.circular(POSRadius.md),
            boxShadow: POSShadow.button,
          ),
          child: Opacity(
            opacity: disabled && !isLoading ? 0.5 : 1.0,
            child: InkWell(
              borderRadius: BorderRadius.circular(POSRadius.md),
              onTap: disabled ? null : onPressed,
              child: Center(
                child:
                    isLoading
                        ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                            strokeCap: StrokeCap.round,
                          ),
                        )
                        : Text(
                          label,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.responsive.value<double>(
                              phone: 16,
                              tablet: 17,
                              kiosk: 18,
                            ),
                            fontWeight: FontWeight.w700,
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

class CartivoErrorBanner extends StatelessWidget {
  const CartivoErrorBanner({super.key, required this.message});

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
              child: const Icon(Icons.error_outline_rounded, color: ColorSet.danger, size: 16),
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
