import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';

class UsernameInput extends HookConsumerWidget {
  const UsernameInput({super.key, required this.controller, this.errorText});

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = context.responsive;
    final focusNode = useFocusNode();

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth * 0.15;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: ColorSet.light,
                  borderRadius: BorderRadius.circular(
                    responsive.value<double>(phone: 12, tablet: 16, kiosk: 20),
                  ),
                  border: errorText != null ? Border.all(color: ColorSet.danger, width: 2) : null,
                ),
                child: TextField(
                  focusNode: focusNode,
                  controller: controller,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ColorSet.dark,
                    fontSize: responsive.value<double>(phone: 16, tablet: 20, kiosk: 24),
                    fontWeight: FontWeight.w400,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                  decoration: InputDecoration(
                    hintText: 'Enter Username',
                    hintStyle: TextStyle(
                      color: ColorSet.dark.withValues(alpha: 0.6),
                      fontSize: responsive.value<double>(phone: 16, tablet: 20, kiosk: 24),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: responsive.value<EdgeInsets>(
                      phone: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      tablet: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      kiosk: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    ),
                  ),
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    errorText!,
                    style: TextStyle(
                      color: ColorSet.danger,
                      fontSize: responsive.value<double>(phone: 12, tablet: 14, kiosk: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
