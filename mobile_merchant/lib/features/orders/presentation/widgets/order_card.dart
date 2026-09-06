import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/order_event_dto.dart';
import '../../domain/order_card_status.dart';

class OrderCard extends StatefulWidget {
  const OrderCard({
    required this.event,
    required this.onStatusChange,
    required this.onCancel,
    super.key,
  });

  final OrderEventDto event;

  /// Called with the new raw status string (e.g. "preparing").
  final Future<void> Function(String status) onStatusChange;
  final Future<void> Function() onCancel;

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
    final customerLabel =
        (data.customerName?.isNotEmpty ?? false) ? data.customerName! : 'Guest';

    return Container(
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
              _StatusBadge(
                status: status,
                rawStatus: data.status,
                interactive: !isTerminal,
                isSubmitting: _isSubmitting,
                onSelected: (next) =>
                    _submit(() => widget.onStatusChange(next.name)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            customerLabel,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _formatTime(data.createdAt.toLocal()),
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${data.items.length} item${data.items.length == 1 ? '' : 's'}',
                style: AppTextStyles.caption,
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
    );
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}

// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
    required this.rawStatus,
    this.interactive = false,
    this.isSubmitting = false,
    this.onSelected,
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
