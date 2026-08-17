import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/button.dart';
import '../../../widgets/cartivo_app_bar.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../cartivo_orders/entities/cartivo_order.dart';
import '../../cartivo_orders/entities/cartivo_order_status.dart';
import '../../cartivo_orders/state/cartivo_orders_notifier.dart';
import 'cartivo_products_screen.dart' show formatPesoPrice;

class CartivoOrdersScreen extends ConsumerWidget {
  const CartivoOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final state = ref.watch(cartivoOrdersProvider);

    ref.listen(cartivoOrdersProvider, (previous, next) {
      if (next case AsyncError(:final error)) {
        showNetworkErrorDialog(
          context,
          error: error,
          onRetry: () => ref.read(cartivoOrdersProvider.notifier).refresh(),
        );
      }
    });

    return Scaffold(
      backgroundColor: POSColors.surfaceSubtle,
      appBar: CartivoAppBar(
        trailing: IconButton(
          onPressed: () => ref.read(cartivoOrdersProvider.notifier).refresh(),
          icon: Icon(Icons.refresh_rounded, color: ColorSet.primary, size: r.value(kiosk: 24, tablet: 22, phone: 20)),
        ),
      ),
      body: Padding(
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
            onRetry: () => ref.read(cartivoOrdersProvider.notifier).refresh(),
          ),
          data: (orders) => orders.isEmpty ? const _EmptyState() : _OrderList(orders: orders),
        ),
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

  final List<CartivoOrder> orders;

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

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final CartivoOrder order;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final dateFormat = DateFormat('MMM d, yyyy · h:mm a');

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
          Text(
            formatPesoPrice(order.currency, order.total),
            style: TextStyle(
              fontSize: r.value(kiosk: 18.0, tablet: 16.0, phone: 15.0),
              fontWeight: FontWeight.w800,
              color: ColorSet.primary,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final CartivoOrderStatus status;

  Color get _color {
    switch (status) {
      case CartivoOrderStatus.pending:
        return ColorSet.warning;
      case CartivoOrderStatus.paid:
        return ColorSet.success;
      case CartivoOrderStatus.cancelled:
      case CartivoOrderStatus.unknown:
        return POSColors.textDisabled;
    }
  }

  String get _label {
    switch (status) {
      case CartivoOrderStatus.pending:
        return 'Pending';
      case CartivoOrderStatus.paid:
        return 'Paid';
      case CartivoOrderStatus.cancelled:
        return 'Cancelled';
      case CartivoOrderStatus.unknown:
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
