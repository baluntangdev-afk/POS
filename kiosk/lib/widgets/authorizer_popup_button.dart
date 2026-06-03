import 'package:flutter/material.dart';

import '../data/backend_api/schemas/authorizer_dto.dart';
import '../styles/color_set.dart';
import '../styles/responsive/responsive_value.dart';
import '../theme/pos_design.dart';

class AuthorizerPopupButton extends StatelessWidget {
  const AuthorizerPopupButton({
    super.key,
    required this.authorizers,
    required this.selected,
    required this.onSelected,
    required this.r,
  });

  final List<AuthorizerDto> authorizers;
  final AuthorizerDto? selected;
  final ValueChanged<AuthorizerDto> onSelected;
  final ResponsiveValue r;

  @override
  Widget build(BuildContext context) {
    final isEmpty = authorizers.isEmpty;

    return PopupMenuButton<AuthorizerDto>(
      enabled: !isEmpty,
      onSelected: onSelected,
      offset: const Offset(0, 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.md)),
      color: Theme.of(context).colorScheme.surface,
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 360),
      position: PopupMenuPosition.under,
      itemBuilder: (_) => authorizers.map((user) {
        final isSelected = selected?.userId == user.userId;
        return PopupMenuItem<AuthorizerDto>(
          value: user,
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                size: 16,
                color: isSelected ? ColorSet.primary : POSColors.borderStrong,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.fullName,
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                        fontWeight: FontWeight.w600,
                        color: POSColors.textPrimary,
                      ),
                    ),
                    Text(
                      user.role,
                      style: TextStyle(
                        fontSize: r.value<double>(kiosk: 11, tablet: 10, phone: 10),
                        color: POSColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        height: r.value<double>(kiosk: 52, tablet: 46, phone: 42),
        padding: EdgeInsets.symmetric(
          horizontal: r.value<double>(kiosk: 16, tablet: 14, phone: 12),
        ),
        decoration: BoxDecoration(
          color: POSColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(POSRadius.md),
          border: Border.all(
            color: selected != null ? ColorSet.primary.withValues(alpha: 0.5) : POSColors.borderDefault,
            width: selected != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.person_rounded,
              size: r.value<double>(kiosk: 18, tablet: 16, phone: 14),
              color: selected != null ? ColorSet.primary : POSColors.textTertiary,
            ),
            SizedBox(width: r.value<double>(kiosk: 10, tablet: 8, phone: 8)),
            Expanded(
              child: Text(
                isEmpty
                    ? 'No authorizers found'
                    : (selected != null ? selected!.fullName : 'Select authorizer...'),
                style: TextStyle(
                  fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                  color: selected != null ? POSColors.textPrimary : POSColors.textTertiary,
                  fontWeight: selected != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (selected != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ColorSet.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  selected!.role,
                  style: TextStyle(
                    fontSize: r.value<double>(kiosk: 10, tablet: 10, phone: 10),
                    color: ColorSet.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isEmpty ? POSColors.borderStrong : POSColors.textTertiary,
              size: r.value<double>(kiosk: 20, tablet: 18, phone: 16),
            ),
          ],
        ),
      ),
    );
  }
}
