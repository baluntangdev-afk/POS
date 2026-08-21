import 'package:flutter/material.dart';

import '../../../../styles/color_set.dart';
import '../../../../styles/responsive/responsive_value.dart';
import '../../../../theme/pos_design.dart';
import '../../entities/order_event.dart';
import '../order_format.dart';

Future<void> showOrderItemsDialog(BuildContext context, OrderEvent event) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (context) => _OrderItemsDialog(event: event),
  );
}

class _OrderItemsDialog extends StatelessWidget {
  const _OrderItemsDialog({required this.event});

  final OrderEvent event;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final data = event.data;
    final itemCount = data.items.fold<int>(0, (sum, item) => sum + item.quantity);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: r.value(kiosk: 40, tablet: 28, phone: 16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 640),
        child: Container(
          decoration: BoxDecoration(
            color: POSColors.surfaceElevated,
            borderRadius: BorderRadius.circular(POSRadius.xl),
            boxShadow: POSShadow.panel,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(event: event, itemCount: itemCount),
              if (data.facilityName != null) _FacilityTag(facilityName: data.facilityName!),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      for (final item in data.items) _ItemRow(item: item),
                    ],
                  ),
                ),
              ),
              _Footer(total: data.total, currency: data.currency),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.event, required this.itemCount});

  final OrderEvent event;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final data = event.data;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${data.id}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: POSColors.textPrimary),
                ),
                const SizedBox(height: 3),
                Text(
                  '${data.customerName ?? 'Guest'} · $itemCount ${itemCount == 1 ? 'item' : 'items'}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: POSColors.textTertiary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            iconSize: 18,
            color: POSColors.textSecondary,
            style: IconButton.styleFrom(
              backgroundColor: POSColors.surfaceSubtle,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.sm)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FacilityTag extends StatelessWidget {
  const _FacilityTag({required this.facilityName});

  final String facilityName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: ColorSet.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(POSRadius.xs),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.place_rounded, size: 14, color: ColorSet.primary),
              const SizedBox(width: 5),
              Text(
                facilityName,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: ColorSet.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OrderEventItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: POSColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: ColorSet.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '${item.quantity}×',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: ColorSet.primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.productName,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: POSColors.textPrimary),
            ),
          ),
          Text(
            formatOrderMoney(item.quantity * item.price, null),
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: POSColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.total, required this.currency});

  final num total;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: POSColors.borderDefault)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: POSColors.textTertiary)),
          Text(
            formatOrderMoney(total, currency),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: POSColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
