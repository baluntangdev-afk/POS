import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/order_event_dto.dart';
import '../../data/models/order_item_dto.dart';
import '../../domain/order_card_status.dart';
import '../format/order_display.dart';
import 'order_status_badge.dart';

/// Opens the read-only order detail sheet for [event].
void showOrderDetailSheet(BuildContext context, OrderEventDto event) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _OrderDetailSheet(event: event),
  );
}

class _OrderDetailSheet extends StatelessWidget {
  const _OrderDetailSheet({required this.event});

  final OrderEventDto event;

  @override
  Widget build(BuildContext context) {
    final data = event.data;
    final subtitle = [
      orderSubtitle(data),
      relativeOrderTime(data.createdAt.toLocal()),
    ].where((s) => s.isNotEmpty).join(' · ');

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Order #${data.id}',
                    style: AppTextStyles.titleLarge,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                OrderStatusBadge(
                  status: classifyStatus(event),
                  rawStatus: data.status,
                ),
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: AppTextStyles.caption,
              ),
            ],
            if (data.customerEmail?.isNotEmpty ?? false) ...[
              const SizedBox(height: AppSpacing.xs),
              _MetaRow(icon: Icons.mail_outline, text: data.customerEmail!),
            ],
            if (data.districtName?.isNotEmpty ?? false) ...[
              const SizedBox(height: AppSpacing.xs),
              _MetaRow(icon: Icons.place_outlined, text: data.districtName!),
            ],
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.items.isEmpty)
                      Text(
                        'No items on this order.',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      )
                    else
                      for (final item in data.items)
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _DetailItemRow(item: item),
                        ),
                  ],
                ),
              ),
            ),
            const Divider(height: AppSpacing.lg, color: AppColors.border),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textSecondary),
                ),
                Text(
                  '₱${data.total.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DetailItemRow extends StatelessWidget {
  const _DetailItemRow({required this.item});

  final OrderItemDto item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${item.quantity}×',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.productName, style: AppTextStyles.bodyMedium),
              Text(
                '₱${item.price.toStringAsFixed(2)} each',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '₱${(item.price * item.quantity).toStringAsFixed(2)}',
          style: AppTextStyles.bodyMedium
              .copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
