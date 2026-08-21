import 'package:flutter/material.dart';

import '../../../../styles/color_set.dart';
import '../../../../styles/responsive/responsive_value.dart';
import '../../../../theme/pos_design.dart';
import '../../entities/order_event.dart';
import '../order_format.dart';
import '../order_status.dart';
import 'order_items_dialog.dart';

/// A single order card on the fulfillment board. Tapping any non-cancelled
/// card opens the item breakdown; cancelled orders are inert (nothing left
/// to act on) but stay visible and readable, just visually de-emphasized.
///
/// Sizing uses [ResponsiveValue.scale] (kiosk 1x / tablet 0.75x / phone 0.5x)
/// on top of kiosk-sized base numbers, matching how the rest of the app
/// scales with window size — everything here previously used fixed pixel
/// values, which is why the board didn't visibly react to resizing.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.event, required this.accentColor});

  final OrderEvent event;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final status = classifyOrderStatus(event);
    final isCancelled = status == OrderCardStatus.cancelled;
    final data = event.data;
    final itemCount = data.items.fold<int>(0, (sum, item) => sum + item.quantity);

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
                        '#${data.id}'.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: r.scale(13.5), fontWeight: FontWeight.w800, color: accentColor),
                      ),
                    ),
                    SizedBox(width: r.scale(10)),
                    Text(
                      formatOrderTime(data.createdAt),
                      style: TextStyle(fontSize: r.scale(12.5), fontWeight: FontWeight.w600, color: POSColors.textTertiary),
                    ),
                  ],
                ),
                SizedBox(height: r.scale(6)),
                Text(
                  data.customerName ?? 'Guest',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: r.scale(14), fontWeight: FontWeight.w600, color: POSColors.textPrimary),
                ),
                if (data.facilityName != null) ...[
                  SizedBox(height: r.scale(6)),
                  _FacilityTag(facilityName: data.facilityName!, accentColor: accentColor),
                ],
                SizedBox(height: r.scale(8)),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: r.scale(12), fontWeight: FontWeight.w500, color: POSColors.textSecondary),
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
                SizedBox(height: r.scale(8)),
                _StatusIndicator(status: status, rawStatus: data.status),
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
                style: TextStyle(fontSize: r.scale(11.5), fontWeight: FontWeight.w600, color: accentColor),
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
    if (status == OrderCardStatus.preparing) return const _PreparingDots();

    final (label, color) = orderStatusPillStyle(status);
    return _Pill(
      label: status == OrderCardStatus.unknown ? capitalizeWords(rawStatus) : label,
      color: color,
      filled: status == OrderCardStatus.completed,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, this.filled = false});

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: r.scale(9), vertical: r.scale(4)),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(POSRadius.full),
        ),
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: r.scale(11.5), fontWeight: FontWeight.w700, color: filled ? Colors.white : color),
        ),
      ),
    );
  }
}

/// Fixed "mid-flight" indicator for [OrderCardStatus.preparing]. The backend
/// only ever sends a flat "preparing" status string — no sub-stage — so this
/// intentionally doesn't fabricate per-order progress; it's a constant
/// received → preparing (filled) → ready (outlined) visual.
class _PreparingDots extends StatelessWidget {
  const _PreparingDots();

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final dotSize = r.scale(6);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            'Preparing',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: r.scale(11.5), fontWeight: FontWeight.w700, color: ColorSet.warning),
          ),
        ),
        SizedBox(width: r.scale(7)),
        _dot(size: dotSize, filled: true),
        SizedBox(width: r.scale(4)),
        _dot(size: dotSize, filled: true),
        SizedBox(width: r.scale(4)),
        _dot(size: dotSize, filled: false),
      ],
    );
  }

  Widget _dot({required double size, required bool filled}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? ColorSet.warning : POSColors.borderStrong,
      ),
    );
  }
}
