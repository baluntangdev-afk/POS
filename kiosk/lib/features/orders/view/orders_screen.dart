import 'dart:async';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/brand_header.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/order_event.dart';
import '../state/pending_orders_count_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Connection status is shown by the app-wide ConnectivityStatusBanner
    // (see app.dart) — this screen only needs the persisted (on-disk) order
    // list, the same source the menu badge reads, not the live feed's
    // in-memory event log, which is empty on a fresh session/reconnect even
    // when orders are already stored locally.
    final events = ref.watch(persistedOrdersProvider).value ?? const [];

    return WindowsScaffold(
      backgroundColor: ColorSet.background,
      body: Column(
        children: [
          BrandHeader(
            trailing: events.isEmpty ? null : _DeleteAllButton(onConfirmed: () => deleteAllOrders(ref)),
          ),
          Expanded(
            child: events.isEmpty ? const _EmptyBody() : _OrderEventList(events: events.toIList()),
          ),
        ],
      ),
    );
  }
}

class _DeleteAllButton extends StatelessWidget {
  const _DeleteAllButton({required this.onConfirmed});

  final VoidCallback onConfirmed;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.lg)),
        title: const Text('Delete all orders?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          "This clears every order from this screen and can't be undone.",
          style: TextStyle(color: POSColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: ColorSet.danger),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => unawaited(_confirmDelete(context)),
      tooltip: 'Delete all orders',
      icon: const Icon(Icons.delete_outline_rounded),
      color: ColorSet.danger,
    );
  }
}

class _OrderEventList extends StatelessWidget {
  const _OrderEventList({required this.events});

  final IList<OrderEvent> events;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return ListView.separated(
      padding: EdgeInsets.all(r.value<double>(kiosk: 24, tablet: 16, phone: 12)),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _OrderEventCard(event: events[index]),
    );
  }
}

class _OrderEventCard extends StatelessWidget {
  const _OrderEventCard({required this.event});

  final OrderEvent event;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final (label, color) = switch (event.type) {
      OrderEventType.created => ('New order', ColorSet.success),
      OrderEventType.updated => ('Order updated', ColorSet.tertiary),
      OrderEventType.cancelled => ('Order cancelled', ColorSet.danger),
    };

    return Container(
      padding: EdgeInsets.all(r.value<double>(kiosk: 20, tablet: 16, phone: 12)),
      decoration: BoxDecoration(
        color: POSColors.surfaceElevated,
        borderRadius: BorderRadius.circular(POSRadius.md),
        border: Border.all(color: POSColors.borderDefault),
        boxShadow: POSShadow.card,
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  'Order #${event.data.id} · ${event.data.customerName ?? 'Guest'}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: POSColors.textPrimary, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  '${event.data.currency} ${event.data.total} · ${event.data.status}',
                  style: const TextStyle(color: POSColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final iconBoxSize = r.value<double>(kiosk: 96, tablet: 80, phone: 64);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(r.value<double>(kiosk: 32, tablet: 24, phone: 16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: ColorSet.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(POSRadius.xl),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: ColorSet.primary,
                size: iconBoxSize * 0.5,
              ),
            ),
            SizedBox(height: r.value<double>(kiosk: 24, tablet: 20, phone: 16)),
            Text(
              'Orders',
              style: TextStyle(
                fontSize: r.value<double>(kiosk: 24, tablet: 20, phone: 18),
                fontWeight: FontWeight.w700,
                color: POSColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: r.value<double>(kiosk: 8, tablet: 6, phone: 4)),
            Text(
              'Waiting for orders',
              style: TextStyle(
                fontSize: r.value<double>(kiosk: 16, tablet: 14, phone: 13),
                fontWeight: FontWeight.w500,
                color: POSColors.textSecondary,
              ),
            ),
            SizedBox(height: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: r.value<double>(kiosk: 360, tablet: 320, phone: 280)),
              child: Text(
                'New online orders will show up here as they come in.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                  color: POSColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
