import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../data/backend_api/sources/orders_api.dart';
import '../../../../styles/color_set.dart';
import '../../../../styles/responsive/responsive_value.dart';
import '../../../../theme/pos_design.dart';
import '../../entities/order_event.dart';
import '../order_format.dart';
import '../order_status.dart';
import 'order_items_dialog.dart';

/// Statuses staff can move an order to from the board. Cancel is deliberately
/// not part of this set — it's a separate, confirmed, destructive action via
/// [_CancelOrderButton].
const _assignableStatuses = [
  (OrderCardStatus.pending, 'pending'),
  (OrderCardStatus.preparing, 'preparing'),
  (OrderCardStatus.ready, 'ready'),
  (OrderCardStatus.fulfilled, 'fulfilled'),
];

class OrderCard extends HookConsumerWidget {
  const OrderCard({super.key, required this.event, required this.accentColor});

  final OrderEvent event;
  final Color accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final status = classifyOrderStatus(event);
    final isCancelled = status == OrderCardStatus.cancelled;
    final isActionable =
        status == OrderCardStatus.pending ||
        status == OrderCardStatus.preparing ||
        status == OrderCardStatus.ready;
    final data = event.data;
    final itemCount = data.items.fold<int>(0, (sum, item) => sum + item.quantity);
    final isSubmitting = useState(false);

    Future<void> submit(Future<void> Function() action, {required String failureMessage}) async {
      if (isSubmitting.value) return;
      isSubmitting.value = true;
      try {
        await action();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failureMessage),
              backgroundColor: ColorSet.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.sm)),
            ),
          );
        }
      }
      if (context.mounted) isSubmitting.value = false;
    }

    Future<void> changeStatus(String rawStatus) => submit(
      () => ref.read(ordersApiProvider).updateStatus(data.id, rawStatus),
      failureMessage: "Couldn't update order status. Try again.",
    );

    Future<void> cancelOrder() => submit(
      () => ref.read(ordersApiProvider).cancel(data.id),
      failureMessage: "Couldn't cancel this order. Try again.",
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isCancelled ? null : () => showOrderItemsDialog(context, event),
        borderRadius: BorderRadius.circular(POSRadius.md),
        child: Container(
          padding: EdgeInsets.all(r.scale(14)),
          decoration: BoxDecoration(
            color: isCancelled ? POSColors.surfaceSubtle : POSColors.surfaceElevated,
            borderRadius: BorderRadius.circular(POSRadius.md),
            border: Border.all(color: POSColors.borderDefault),
            boxShadow: isCancelled ? null : POSShadow.card,
          ),
          child: Opacity(
            opacity: isCancelled ? 0.6 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        data.id.toUpperCase(),
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: r.scale(15),
                          fontWeight: FontWeight.bold,
                          color: POSColors.textTertiary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    SizedBox(width: r.scale(8)),
                    if (isActionable)
                      _StatusDropdown(
                        status: status,
                        isSubmitting: isSubmitting.value,
                        onSelected: changeStatus,
                      )
                    else
                      _StatusIndicator(status: status, rawStatus: data.status),
                  ],
                ),
                SizedBox(height: r.scale(8)),
                Text(
                  data.customerName ?? 'Guest',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: r.scale(14),
                    fontWeight: FontWeight.w600,
                    color: POSColors.textPrimary,
                  ),
                ),
                SizedBox(height: r.scale(3)),
                Text(
                  formatOrderTime(data.createdAt),
                  style: TextStyle(
                    fontSize: r.scale(11.5),
                    fontWeight: FontWeight.w500,
                    color: POSColors.textTertiary,
                  ),
                ),
                if (data.facilityName != null) ...[
                  SizedBox(height: r.scale(6)),
                  _FacilityTag(facilityName: data.facilityName!, accentColor: accentColor),
                ],
                SizedBox(height: r.scale(10)),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: r.scale(12),
                          fontWeight: FontWeight.w500,
                          color: POSColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(width: r.scale(8)),
                    Text(
                      formatOrderMoney(data.total, data.currency),
                      style: TextStyle(
                        fontSize: r.scale(14.5),
                        fontWeight: FontWeight.w800,
                        color: POSColors.textPrimary,
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                        decorationColor: POSColors.textDisabled,
                      ),
                    ),
                  ],
                ),
                if (isActionable) ...[
                  SizedBox(height: r.scale(10)),
                  _CancelOrderButton(isSubmitting: isSubmitting.value, onConfirmed: cancelOrder),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FacilityTag extends StatelessWidget {
  const _FacilityTag({required this.facilityName, required this.accentColor});

  final String facilityName;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: r.scale(8), vertical: r.scale(4)),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.place_rounded, size: r.scale(12), color: accentColor),
            SizedBox(width: r.scale(4)),
            Flexible(
              child: Text(
                facilityName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: r.scale(11.5),
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.status, required this.rawStatus});

  final OrderCardStatus status;
  final String rawStatus;

  @override
  Widget build(BuildContext context) {
    final (label, color) = orderStatusPillStyle(status);
    return _StatusBadge(
      label: status == OrderCardStatus.unknown ? capitalizeWords(rawStatus) : label,
      color: color,
      filled: status == OrderCardStatus.fulfilled,
    );
  }
}

/// Tappable status control for actionable orders — opens a menu of every
/// status staff can set directly (jump ahead or revert), matching the
/// current one. A plain outlined rectangle, same family as [_StatusBadge]
/// plus a chevron, deliberately flat rather than filled/gradient — reads as
/// an ordinary form control instead of a decorative chip.
class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({
    required this.status,
    required this.isSubmitting,
    required this.onSelected,
  });

  final OrderCardStatus status;
  final bool isSubmitting;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final (label, color) = orderStatusPillStyle(status);

    return PopupMenuButton<String>(
      enabled: !isSubmitting,
      onSelected: onSelected,
      color: POSColors.surfaceElevated,
      elevation: 3,
      constraints: BoxConstraints(minWidth: r.scale(150)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(POSRadius.sm),
        side: const BorderSide(color: POSColors.borderDefault),
      ),
      offset: Offset(0, r.scale(4)),
      itemBuilder:
          (context) => [
            for (final (optionStatus, rawValue) in _assignableStatuses)
              PopupMenuItem<String>(
                value: rawValue,
                enabled: optionStatus != status,
                height: r.scale(40),
                child: _StatusMenuRow(status: optionStatus, isCurrent: optionStatus == status),
              ),
          ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: r.scale(10), vertical: r.scale(6)),
        decoration: BoxDecoration(
          color: POSColors.surfaceElevated,
          borderRadius: BorderRadius.circular(POSRadius.sm),
          border: Border.all(color: color, width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: r.scale(11),
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.4,
              ),
            ),
            SizedBox(width: r.scale(4)),
            if (isSubmitting)
              SizedBox(
                width: r.scale(11),
                height: r.scale(11),
                child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
              )
            else
              Icon(Icons.keyboard_arrow_down_rounded, size: r.scale(16), color: color),
          ],
        ),
      ),
    );
  }
}

/// One row inside the status popup menu — the current status is marked with
/// a check instead of the usual greyed-out disabled look.
class _StatusMenuRow extends StatelessWidget {
  const _StatusMenuRow({required this.status, required this.isCurrent});

  final OrderCardStatus status;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final (label, color) = orderStatusPillStyle(status);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isCurrent ? color : POSColors.textPrimary,
            ),
          ),
        ),
        if (isCurrent) Icon(Icons.check_rounded, size: 16, color: color),
      ],
    );
  }
}

/// Confirms, then fires the cancel request. Only shown for actionable orders.
class _CancelOrderButton extends StatelessWidget {
  const _CancelOrderButton({required this.isSubmitting, required this.onConfirmed});

  final bool isSubmitting;
  final VoidCallback onConfirmed;

  Future<void> _confirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.lg)),
            title: const Text('Cancel this order?', style: TextStyle(fontWeight: FontWeight.w700)),
            content: const Text(
              "This can't be undone.",
              style: TextStyle(color: POSColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Keep order'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: FilledButton.styleFrom(backgroundColor: ColorSet.danger),
                child: const Text('Cancel order'),
              ),
            ],
          ),
    );
    if (confirmed ?? false) onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isSubmitting ? null : () => _confirm(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorSet.danger,
          side: BorderSide(color: ColorSet.danger.withValues(alpha: isSubmitting ? 0.4 : 1)),
          padding: EdgeInsets.symmetric(vertical: r.scale(8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.sm)),
          minimumSize: Size(0, r.scale(32)),
        ),
        child: Padding(
          padding: EdgeInsetsGeometry.all(r.scale(15)),
          child:
              isSubmitting
                  ? SizedBox(
                    width: r.scale(14),
                    height: r.scale(14),
                    child: const CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: ColorSet.danger,
                    ),
                  )
                  : Text(
                    'CANCEL ORDER',
                    style: TextStyle(
                      fontSize: r.scale(12),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color, this.filled = false});

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.scale(9), vertical: r.scale(5)),
      decoration: BoxDecoration(
        color: filled ? color : POSColors.surfaceElevated,
        borderRadius: BorderRadius.circular(POSRadius.sm),
        border: filled ? null : Border.all(color: color, width: 1.4),
      ),
      child: Text(
        label.toUpperCase(),
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: r.scale(11),
          fontWeight: FontWeight.w800,
          color: filled ? Colors.white : color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
