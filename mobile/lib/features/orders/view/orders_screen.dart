import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/result/result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../live_orders/entities/order_event.dart';
import '../../live_orders/state/orders_feed_notifier.dart';
import '../../live_orders/state/orders_count_provider.dart';
import '../../live_orders/use_cases/order_update_error.dart';
import 'order_status.dart';

/// Live incoming-orders list. Reads `persistedOrdersProvider` — sourced from
/// the local `order_events` table, not the in-memory socket state directly
/// — so this screen shows the right thing on open even before any socket
/// event arrives this session. The connection itself is booted and checked
/// on `DashboardScreen`; this screen only observes it.
class OrdersScreen extends HookConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(persistedOrdersProvider);

    useEffect(() {
      unawaited(ref.read(ordersFeedNotifierProvider.notifier).refreshHistory());
      return null;
    }, const []);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/dashboard');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Orders'),
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => context.go('/dashboard'),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (e, _) => Center(
                child: Text(
                  'Could not load orders.\n$e',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          data: (orders) {
            if (orders.isEmpty) {
              return const EmptyStateWidget(
                title: 'No orders yet',
                subtitle:
                    'New orders placed through your storefront will show up here in real time.',
              );
            }
            return RefreshIndicator(
              onRefresh:
                  () =>
                      ref
                          .read(ordersFeedNotifierProvider.notifier)
                          .refreshHistory(),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: orders.length,
                separatorBuilder:
                    (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder:
                    (context, index) => _OrderCard(
                      event: orders[index],
                      onTap: () => _showOrderDetail(context, orders[index]),
                    ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showOrderDetail(BuildContext context, OrderEvent event) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _OrderDetailSheet(event: event),
    );
  }
}

class _OrderCard extends HookConsumerWidget {
  final OrderEvent event;
  final VoidCallback onTap;

  const _OrderCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = event.data;
    final status = classifyOrderStatus(event);
    final isCancelled = event.type == OrderEventType.cancelled;
    final canCancel = !isCancelled && status != OrderCardStatus.fulfilled;
    final isSubmitting = useState(false);

    // Runs [action], shows a snackbar on failure, and keeps the card in its
    // submitting state (spinner + disabled controls) until it settles.
    Future<void> submit(
      Future<Result<OrderEvent, OrderUpdateError>> Function() action,
    ) async {
      if (isSubmitting.value) return;
      isSubmitting.value = true;
      final result = await action();
      if (!context.mounted) return;
      isSubmitting.value = false;
      if (result.isFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    Future<void> changeStatus(OrderCardStatus next) => submit(
      () => ref
          .read(ordersFeedNotifierProvider.notifier)
          .setOrderStatus(data.id, next.rawValue),
    );

    Future<void> cancelOrder() => submit(
      () => ref
          .read(ordersFeedNotifierProvider.notifier)
          .setOrderStatus(data.id, OrderCardStatus.cancelled.rawValue),
    );
    final subtitle = [
      (data.customerName ?? '').isNotEmpty ? data.customerName : 'Guest',
      switch (data.fulfillmentType) {
        FulfillmentType.onSite =>
          (data.facilityName ?? '').isNotEmpty
              ? 'On-site · ${data.facilityName}'
              : 'On-site',
        FulfillmentType.pickup => 'Pickup',
        FulfillmentType.delivery => 'Delivery',
        FulfillmentType.other => null,
      },
    ].whereType<String>().join(' · ');

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8.0,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${data.id}',
                      style: AppTextStyles.headingSm,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _StatusBadge(
                    status: status,
                    rawStatus: data.status,
                    interactive: canCancel,
                    isSubmitting: isSubmitting.value,
                    onSelected: changeStatus,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                DateFormat('h:mm a').format(data.createdAt),
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${data.items.length} item${data.items.length == 1 ? '' : 's'}',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(symbol: '₱').format(data.total),
                    style: AppTextStyles.priceMd,
                  ),
                ],
              ),
              if (canCancel) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: MaterialButton(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: AppColors.error),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    splashColor: AppColors.error.withValues(alpha: 0.3),
                    padding: EdgeInsets.all(4.0),
                    onPressed: isSubmitting.value
                        ? null
                        : () => _confirmCancelOrder(context, cancelOrder),
                    child: isSubmitting.value
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
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
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

class _StatusBadge extends StatelessWidget {
  final OrderCardStatus status;
  final String rawStatus;
  final bool interactive;
  final bool isSubmitting;
  final ValueChanged<OrderCardStatus>? onSelected;

  const _StatusBadge({
    required this.status,
    required this.rawStatus,
    this.interactive = false,
    this.isSubmitting = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color) = orderStatusPillStyle(status);
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
      offset: const Offset(0, 30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      onSelected: (next) => onSelected?.call(next),
      itemBuilder: (context) => [
        for (final option in assignableOrderStatuses)
          PopupMenuItem(
            value: option,
            // The current status stays selectable so staff can re-apply it
            // (e.g. to re-push the update); it's only marked, not disabled.
            child: Row(
              children: [
                Expanded(child: Text(orderStatusPillStyle(option).$1)),
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

/// Asks for confirmation, then runs [onConfirmed] (the actual cancel request).
Future<void> _confirmCancelOrder(
  BuildContext context,
  Future<void> Function() onConfirmed,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cancel this order?'),
      content: const Text("This can't be undone."),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep order'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Cancel order'),
        ),
      ],
    ),
  );
  if (confirmed ?? false) await onConfirmed();
}

class _OrderDetailSheet extends StatelessWidget {
  final OrderEvent event;

  const _OrderDetailSheet({required this.event});

  @override
  Widget build(BuildContext context) {
    final data = event.data;
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
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
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Expanded(
                  child: Text(
                    'Order #${data.id}',
                    style: AppTextStyles.headingLg,
                  ),
                ),
                _StatusBadge(
                  status: classifyOrderStatus(event),
                  rawStatus: data.status,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              [
                if ((data.customerName ?? '').isNotEmpty) data.customerName,
                switch (data.fulfillmentType) {
                  FulfillmentType.onSite =>
                    'On-site${(data.facilityName ?? '').isNotEmpty ? ' · ${data.facilityName}' : ''}',
                  FulfillmentType.pickup => 'Pickup',
                  FulfillmentType.delivery => 'Delivery',
                  FulfillmentType.other => null,
                },
                _relativeTime(data.updatedAt),
              ].whereType<String>().join(' · '),
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...data.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Text(
                      '${item.quantity}×',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        item.productName,
                        style: AppTextStyles.bodyMd,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                        symbol: '₱',
                      ).format(item.price * item.quantity),
                      style: AppTextStyles.bodyMd,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppTextStyles.bodyLg.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  NumberFormat.currency(symbol: '₱').format(data.total),
                  style: AppTextStyles.priceLg,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
