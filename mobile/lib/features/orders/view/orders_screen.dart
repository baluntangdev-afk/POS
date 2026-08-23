import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../live_orders/entities/order_event.dart';
import '../../live_orders/state/pending_orders_count_provider.dart';
import 'order_status.dart';

/// Live incoming-orders list. Reads `persistedOrdersProvider` — sourced from
/// the local `order_events` table, not the in-memory socket state directly
/// — so this screen shows the right thing on open even before any socket
/// event arrives this session. The connection itself is booted and checked
/// on `DashboardScreen`; this screen only observes it.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(persistedOrdersProvider);

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
          error: (e, _) => Center(
            child: Text(
              'Could not load orders.\n$e',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
            ),
          ),
          data: (orders) {
            if (orders.isEmpty) {
              return const EmptyStateWidget(
                title: 'No orders yet',
                subtitle: 'New orders placed through your storefront will show up here in real time.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _OrderCard(
                event: orders[index],
                onTap: () => _showOrderDetail(context, orders[index]),
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

class _OrderCard extends StatelessWidget {
  final OrderEvent event;
  final VoidCallback onTap;

  const _OrderCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final data = event.data;
    final isCancelled = event.type == OrderEventType.cancelled;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border(
              left: BorderSide(
                color: isCancelled ? AppColors.textDisabled : AppColors.primary,
                width: 3,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text('Order #${data.id}', style: AppTextStyles.headingSm)),
                  Text(_relativeTime(data.updatedAt), style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              if ((data.customerName ?? '').isNotEmpty)
                Text(
                  data.customerName!,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _StatusBadge(status: classifyOrderStatus(event), rawStatus: data.status),
                  const SizedBox(width: AppSpacing.xs),
                  _FulfillmentChip(
                    type: data.fulfillmentType,
                    facilityName: data.facilityName,
                    isCancelled: isCancelled,
                  ),
                  const Spacer(),
                  Text(
                    '${data.items.length} item${data.items.length == 1 ? '' : 's'}',
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    NumberFormat.currency(symbol: '₱').format(data.total),
                    style: AppTextStyles.priceMd,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FulfillmentChip extends StatelessWidget {
  final FulfillmentType type;
  final String? facilityName;
  final bool isCancelled;

  const _FulfillmentChip({required this.type, this.facilityName, required this.isCancelled});

  String get _label => switch (type) {
        FulfillmentType.onSite =>
          (facilityName ?? '').isNotEmpty ? 'On-site · $facilityName' : 'On-site',
        FulfillmentType.pickup => 'Pickup',
        FulfillmentType.delivery => 'Delivery',
        FulfillmentType.other => 'Order',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCancelled ? AppColors.errorLight : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isCancelled ? 'Cancelled' : _label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: isCancelled ? AppColors.error : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderCardStatus status;
  final String rawStatus;

  const _StatusBadge({required this.status, required this.rawStatus});

  @override
  Widget build(BuildContext context) {
    final (label, color) = orderStatusPillStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Text(
        (status == OrderCardStatus.unknown ? rawStatus : label).toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: color,
        ),
      ),
    );
  }
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        ),
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
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
                Expanded(child: Text('Order #${data.id}', style: AppTextStyles.headingLg)),
                _StatusBadge(status: classifyOrderStatus(event), rawStatus: data.status),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              [
                if ((data.customerName ?? '').isNotEmpty) data.customerName,
                switch (data.fulfillmentType) {
                  FulfillmentType.onSite => 'On-site${(data.facilityName ?? '').isNotEmpty ? ' · ${data.facilityName}' : ''}',
                  FulfillmentType.pickup => 'Pickup',
                  FulfillmentType.delivery => 'Delivery',
                  FulfillmentType.other => null,
                },
                _relativeTime(data.updatedAt),
              ].whereType<String>().join(' · '),
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            ...data.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Text('${item.quantity}×', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(item.productName, style: AppTextStyles.bodyMd)),
                    Text(NumberFormat.currency(symbol: '₱').format(item.price * item.quantity), style: AppTextStyles.bodyMd),
                  ],
                ),
              ),
            ),
            const Divider(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: AppTextStyles.bodyLg.copyWith(color: AppColors.textSecondary)),
                Text(NumberFormat.currency(symbol: '₱').format(data.total), style: AppTextStyles.priceLg),
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
