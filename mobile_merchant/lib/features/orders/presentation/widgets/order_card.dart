import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/order_event_dto.dart';
import '../../data/models/order_item_dto.dart';
import '../../domain/order_card_status.dart';
import '../format/order_display.dart';
import 'order_status_badge.dart';

class OrderCard extends StatefulWidget {
  const OrderCard({
    required this.event,
    required this.onStatusChange,
    required this.onCancel,
    required this.onTap,
    super.key,
  });

  final OrderEventDto event;

  /// Called with the new raw status string (e.g. "preparing").
  final Future<void> Function(String status) onStatusChange;
  final Future<void> Function() onCancel;

  /// Opens the read-only order detail sheet.
  final VoidCallback onTap;

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _isSubmitting = false;

  Future<void> _submit(Future<void> Function() action) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep order'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await _submit(widget.onCancel);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.event.data;
    final status = classifyStatus(widget.event);
    final isTerminal = status == OrderCardStatus.cancelled ||
        status == OrderCardStatus.fulfilled;
    final subtitle = orderSubtitle(data);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${data.id}',
                      style: AppTextStyles.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OrderStatusBadge(
                    status: status,
                    rawStatus: data.status,
                    interactive: !isTerminal,
                    isSubmitting: _isSubmitting,
                    onSelected: (next) =>
                        _submit(() => widget.onStatusChange(next.name)),
                  ),
                ],
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text(
                relativeOrderTime(data.createdAt.toLocal()),
                style: AppTextStyles.caption,
              ),
              if (data.items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                for (final item in data.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: _ItemRow(item: item),
                  ),
                const SizedBox(height: AppSpacing.xs),
                const Divider(height: 1, thickness: 1, color: AppColors.border),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: AppTextStyles.bodyMedium),
                  Text(
                    '₱${data.total.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (!isTerminal) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      foregroundColor: AppColors.error,
                      shape: const StadiumBorder(),
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    ),
                    onPressed:
                        _isSubmitting ? null : () => _confirmCancel(context),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.error,
                            ),
                          )
                        : const Text(
                            'CANCEL ORDER',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

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
          child: Text(
            item.productName,
            style: AppTextStyles.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '₱${(item.price * item.quantity).toStringAsFixed(2)}',
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}
