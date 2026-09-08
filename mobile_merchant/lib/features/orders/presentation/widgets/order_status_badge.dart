import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/order_card_status.dart';

/// The status pill shown on an order card and in the detail sheet.
///
/// When [interactive] is true (and [onSelected] is provided) it becomes a
/// dropdown for reassigning the order's status; otherwise it's a plain label.
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({
    required this.status,
    required this.rawStatus,
    this.interactive = false,
    this.isSubmitting = false,
    this.onSelected,
    super.key,
  });

  final OrderCardStatus status;
  final String rawStatus;
  final bool interactive;
  final bool isSubmitting;
  final ValueChanged<OrderCardStatus>? onSelected;

  @override
  Widget build(BuildContext context) {
    final (label, color) = statusStyle(status);

    final pill = Container(
      padding: EdgeInsets.symmetric(
        horizontal: interactive ? 10 : 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            (status == OrderCardStatus.unknown ? rawStatus : label)
                .toUpperCase(),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: color,
            ),
          ),
          if (interactive) ...[
            const SizedBox(width: 2),
            if (isSubmitting)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: color,
                ),
              )
            else
              Icon(Icons.keyboard_arrow_down, size: 14, color: color),
          ],
        ],
      ),
    );

    if (!interactive || onSelected == null) return pill;

    return PopupMenuButton<OrderCardStatus>(
      tooltip: '',
      enabled: !isSubmitting,
      padding: EdgeInsets.zero,
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final option in assignableOrderStatuses)
          PopupMenuItem(
            value: option,
            child: Row(
              children: [
                Expanded(child: Text(statusStyle(option).$1)),
                if (option == status)
                  const Icon(Icons.check, size: 18, color: AppColors.primary),
              ],
            ),
          ),
      ],
      child: pill,
    );
  }
}
