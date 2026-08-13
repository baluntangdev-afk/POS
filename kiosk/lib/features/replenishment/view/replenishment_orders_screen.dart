import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/button.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/top_app_bar.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/replenishment_order.dart';
import '../entities/replenishment_order_status.dart';
import '../state/replenishment_orders_notifier.dart';
import '../state/replenishment_pay_order_notifier.dart';

class ReplenishmentOrdersScreen extends ConsumerWidget {
  const ReplenishmentOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final state = ref.watch(replenishmentOrdersProvider);

    ref.listen(replenishmentOrdersProvider, (previous, next) {
      if (next case AsyncError(:final error)) {
        showNetworkErrorDialog(
          context,
          error: error,
          onRetry: () => ref.read(replenishmentOrdersProvider.notifier).refresh(),
        );
      }
    });

    return WindowsScaffold(
      backgroundColor: ColorSet.background,
      body: Column(
        children: [
          TopAppBar(
            title: 'Orders',
            trailing: IconButton(
              onPressed: () => ref.read(replenishmentOrdersProvider.notifier).refresh(),
              icon: Icon(
                Icons.refresh_rounded,
                color: ColorSet.light,
                size: r.value(kiosk: 24, tablet: 22, phone: 20),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(r.value(kiosk: 32, tablet: 24, phone: 16)),
              child: state.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: ColorSet.primary,
                    strokeWidth: 3,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                error: (error, _) => _ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.read(replenishmentOrdersProvider.notifier).refresh(),
                ),
                data: (orders) =>
                    orders.isEmpty ? const _EmptyState() : _OrderList(orders: orders),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: r.value(kiosk: 64.0, tablet: 52.0, phone: 40.0),
            color: POSColors.textDisabled,
          ),
          Gap(r.value(kiosk: 16, tablet: 12, phone: 8)),
          Text(
            message,
            style: TextStyle(
              fontSize: r.value(kiosk: 14, tablet: 13, phone: 12),
              color: POSColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          Gap(r.value(kiosk: 16, tablet: 12, phone: 8)),
          Button(
            label: const Text('Retry'),
            leading: const Icon(Icons.refresh_rounded),
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: r.value(kiosk: 80.0, tablet: 64.0, phone: 48.0),
            color: POSColors.textDisabled,
          ),
          Gap(r.value(kiosk: 16.0, tablet: 12.0, phone: 8.0)),
          Text(
            'No orders yet',
            style: TextStyle(
              fontSize: r.value(kiosk: 20.0, tablet: 16.0, phone: 14.0),
              fontWeight: FontWeight.w600,
              color: POSColors.textSecondary,
            ),
          ),
          Gap(r.value(kiosk: 8.0, tablet: 6.0, phone: 4.0)),
          Text(
            'Orders you place from the cart will show up here.',
            style: TextStyle(
              fontSize: r.value(kiosk: 14.0, tablet: 12.0, phone: 10.0),
              color: POSColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  const _OrderList({required this.orders});

  final List<ReplenishmentOrder> orders;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return ListView.separated(
      itemCount: orders.length,
      separatorBuilder: (_, _) => Gap(r.value(kiosk: 12, tablet: 10, phone: 8)),
      itemBuilder: (context, index) => _OrderCard(order: orders[index]),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order});

  final ReplenishmentOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final dateFormat = DateFormat('MMM d, yyyy · h:mm a');
    final isPending = order.status == ReplenishmentOrderStatus.pending;

    ref.listen(replenishmentPayOrderProvider(order.id), (previous, next) {
      if (next case AsyncError(:final error)) {
        showNetworkErrorDialog(
          context,
          error: error,
          onRetry: () => ref.read(replenishmentPayOrderProvider(order.id).notifier).pay(),
        );
      }
    });
    final isPaying = ref.watch(replenishmentPayOrderProvider(order.id)).isLoading;

    return Container(
      padding: EdgeInsets.all(r.value(kiosk: 16, tablet: 14, phone: 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Order #${order.id}',
                  style: TextStyle(
                    fontSize: r.value(kiosk: 15.0, tablet: 14.0, phone: 13.0),
                    fontWeight: FontWeight.w700,
                    color: POSColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Gap(r.value(kiosk: 8, tablet: 6, phone: 4)),
              _StatusChip(status: order.status),
            ],
          ),
          Gap(r.value(kiosk: 4, tablet: 3, phone: 2)),
          Text(
            dateFormat.format(order.createdAt),
            style: TextStyle(
              fontSize: r.value(kiosk: 12.0, tablet: 11.0, phone: 10.0),
              color: POSColors.textTertiary,
            ),
          ),
          Gap(r.value(kiosk: 12, tablet: 10, phone: 8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.currency} ${order.total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: r.value(kiosk: 18.0, tablet: 16.0, phone: 15.0),
                  fontWeight: FontWeight.w800,
                  color: ColorSet.primary,
                  letterSpacing: -0.4,
                ),
              ),
              if (isPending)
                Button(
                  label: isPaying
                      ? SizedBox(
                          width: r.value(kiosk: 18.0, tablet: 16.0, phone: 14.0),
                          height: r.value(kiosk: 18.0, tablet: 16.0, phone: 14.0),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                            strokeCap: StrokeCap.round,
                          ),
                        )
                      : const Text('Pay Now'),
                  backgroundColor: ColorSet.primary,
                  foregroundColor: Colors.white,
                  onPressed: isPaying
                      ? null
                      : () => ref.read(replenishmentPayOrderProvider(order.id).notifier).pay(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ReplenishmentOrderStatus status;

  Color get _color {
    switch (status) {
      case ReplenishmentOrderStatus.pending:
        return ColorSet.warning;
      case ReplenishmentOrderStatus.paid:
        return ColorSet.success;
      case ReplenishmentOrderStatus.cancelled:
      case ReplenishmentOrderStatus.unknown:
        return POSColors.textDisabled;
    }
  }

  String get _label {
    switch (status) {
      case ReplenishmentOrderStatus.pending:
        return 'Pending';
      case ReplenishmentOrderStatus.paid:
        return 'Paid';
      case ReplenishmentOrderStatus.cancelled:
        return 'Cancelled';
      case ReplenishmentOrderStatus.unknown:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: r.value(kiosk: 10.0, tablet: 9.0, phone: 8.0),
        vertical: r.value(kiosk: 4.0, tablet: 4.0, phone: 3.0),
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(POSRadius.full),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: r.value(kiosk: 11.0, tablet: 10.0, phone: 9.0),
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}
