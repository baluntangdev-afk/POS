import 'dart:async';
import 'dart:math' as math;

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
import '../../live_orders/state/order_detail_provider.dart';
import '../../live_orders/state/orders_feed_notifier.dart';
import '../../live_orders/state/orders_count_provider.dart';
import '../../live_orders/state/webhook_auth_status_provider.dart';
import '../../live_orders/entities/pos_order_status.dart';
import '../../live_orders/use_cases/cartivo_pos_error.dart';
import '../../live_orders/use_cases/webhook_auth_error.dart';
import 'order_status.dart';

/// Whether a store-info auth failure should replace the Orders list with an
/// error state rather than let a cached list show through. A rejected store ID
/// or a bad build config means the list can't be trusted; a transient network /
/// server blip (already covered by the toast) shouldn't hide orders we have.
bool _blocksOrdersList(WebhookAuthError reason) => switch (reason) {
  WebhookAuthError.network ||
  WebhookAuthError.serverError ||
  WebhookAuthError.rateLimited ||
  WebhookAuthError.unexpectedResponse ||
  WebhookAuthError.unknown => false,
  WebhookAuthError.invalidWebhookSecret ||
  WebhookAuthError.invalidClient ||
  WebhookAuthError.unauthorized ||
  WebhookAuthError.invalidRequest => true,
};

class OrdersScreen extends HookConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(persistedOrdersProvider);
    final authFailure = ref.watch(webhookAuthStatusProvider);

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
        body: _body(context, ref, ordersAsync, authFailure),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<OrderEvent>> ordersAsync,
    WebhookAuthFailure? authFailure,
  ) {
    if (authFailure != null && _blocksOrdersList(authFailure.reason)) {
      return EmptyStateWidget(
        icon: Icons.error_outline,
        title: "Can't load orders",
        subtitle: authFailure.message,
      );
    }

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, _) => const EmptyStateWidget(
            icon: Icons.error_outline,
            title: "Can't load orders",
            subtitle:
                'Something went wrong reading saved orders. Go back and try again.',
          ),
      data: (orders) {
        if (orders.isEmpty) {
          return const EmptyStateWidget(
            title: 'No orders yet',
            subtitle:
                'New orders placed through your storefront will show up here in real time.',
          );
        }
        return _OrdersList(orders: orders);
      },
    );
  }
}

void _showOrderDetail(BuildContext context, OrderEvent event) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _OrderDetailSheet(event: event),
  );
}

class _OrdersList extends HookConsumerWidget {
  final List<OrderEvent> orders;

  const _OrdersList({required this.orders});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabs = buildOrderStatusTabs(orders);
    final selected = useState<OrderCardStatus?>(null);

    final activeStatus =
        tabs.any((t) => t.status == selected.value) ? selected.value : null;

    final filtered =
        activeStatus == null
            ? orders
            : orders
                .where((e) => classifyOrderStatus(e) == activeStatus)
                .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OrdersTabBar(
          tabs: tabs,
          selected: activeStatus,
          onSelect: (status) => selected.value = status,
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.divider),
        Expanded(
          child:
              filtered.isEmpty
                  ? const EmptyStateWidget(
                    title: 'Nothing in this status',
                    subtitle: 'Switch tabs to see your other orders.',
                  )
                  : RefreshIndicator(
                    onRefresh:
                        () =>
                            ref
                                .read(ordersFeedNotifierProvider.notifier)
                                .refreshHistory(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: filtered.length,
                      separatorBuilder:
                          (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder:
                          (context, index) => _OrderCard(
                            event: filtered[index],
                            onTap:
                                () =>
                                    _showOrderDetail(context, filtered[index]),
                          ),
                    ),
                  ),
        ),
      ],
    );
  }
}

/// Horizontal, scrollable row of status pills. Mirrors the merchant app's
/// tab row: an active pill is filled with the brand color, each pill carries a
/// count badge.
class _OrdersTabBar extends StatelessWidget {
  final List<OrderStatusTab> tabs;
  final OrderCardStatus? selected;
  final ValueChanged<OrderCardStatus?> onSelect;

  const _OrdersTabBar({
    required this.tabs,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isActive = tab.status == selected;
          return Center(
            child: GestureDetector(
              onTap: () => onSelect(tab.status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: isActive ? AppColors.primary : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tab.label,
                      style: AppTextStyles.labelLg.copyWith(
                        color:
                            isActive
                                ? AppColors.textOnPrimary
                                : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isActive
                                ? Colors.white.withValues(alpha: 0.22)
                                : AppColors.background,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusFull,
                        ),
                      ),
                      child: Text(
                        '${tab.count}',
                        style: AppTextStyles.bodySm.copyWith(
                          fontWeight: FontWeight.w700,
                          color:
                              isActive
                                  ? AppColors.textOnPrimary
                                  : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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
    final canCancel = canCancelOrder(event);
    final isSubmitting = useState(false);

    // Runs [action], shows a snackbar on failure, and keeps the card in its
    // submitting state (spinner + disabled controls) until it settles.
    Future<void> submit(
      Future<Result<OrderEvent, CartivoPosFailure>> Function() action,
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
          .updateCartivoOrderStatus(
            event,
            PosOrderStatus.values.byName(next.rawValue),
          ),
    );

    Future<void> cancelOrder(String reason) => submit(
      () => ref
          .read(ordersFeedNotifierProvider.notifier)
          .updateCartivoOrderStatus(
            event,
            PosOrderStatus.cancelled,
            reason: reason,
          ),
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
                DateFormat('h:mm a').format(data.createdAt.toLocal()),
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
                    onPressed:
                        isSubmitting.value
                            ? null
                            : () => _confirmCancelOrder(context, event, cancelOrder),
                    child:
                        isSubmitting.value
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
      itemBuilder:
          (context) => [
            for (final option in assignableOrderStatuses)
              PopupMenuItem(
                value: option,
                // The current status stays selectable so staff can re-apply it
                // (e.g. to re-push the update); it's only marked, not disabled.
                child: Row(
                  children: [
                    Expanded(child: Text(orderStatusPillStyle(option).$1)),
                    if (option == status)
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ),
          ],
      child: pill,
    );
  }
}

/// Collects a cancellation reason (Cartivo rejects a cancel without one), then
/// runs [onConfirmed] with it (the actual cancel request).
Future<void> _confirmCancelOrder(
  BuildContext context,
  OrderEvent event,
  Future<void> Function(String reason) onConfirmed,
) async {
  final reason = await showDialog<String>(
    context: context,
    builder: (_) => _CancelOrderDialog(orderId: event.data.id),
  );
  if (reason != null) await onConfirmed(reason);
}

const _cancelReasonPresets = [
  'Customer requested',
  'Out of stock',
  'Unable to fulfill',
  'Duplicate order',
];

class _CancelOrderDialog extends HookWidget {
  final String orderId;

  const _CancelOrderDialog({required this.orderId});

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController();
    final text = useValueListenable(controller);
    final reason = text.text.trim();

    return AlertDialog(
      title: Text('Cancel order #$orderId?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tell us why. This can't be undone.",
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in _cancelReasonPresets)
                  ChoiceChip(
                    label: Text(preset),
                    selected: reason == preset,
                    onSelected: (_) {
                      controller.text = preset;
                      controller.selection = TextSelection.collapsed(
                        offset: preset.length,
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              maxLines: 3,
              minLines: 2,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Or type your own reason',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Keep order'),
        ),
        TextButton(
          onPressed: reason.isEmpty ? null : () => Navigator.of(context).pop(reason),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Cancel order'),
        ),
      ],
    );
  }
}

/// Read-only bottom sheet for one order. The header renders from the cached
/// [event]; the body reads the full order from Cartivo. While loading it shows
/// a skeleton sized from the cached items, and if the fetch fails the cached
/// details stay visible under an error banner.
class _OrderDetailSheet extends HookConsumerWidget {
  final OrderEvent event;

  const _OrderDetailSheet({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(orderDetailProvider(event.data.id));
    final fetched = detail.value;
    final data = fetched ?? event.data;
    final isLoading = detail.isLoading && fetched == null;
    final error = (detail.hasError && !detail.isLoading) ? detail.error : null;

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            _SheetHeader(event: event, data: data),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child:
                    isLoading
                        ? _SheetSkeleton(
                          itemCount: math.max(event.data.items.length, 1),
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (error != null)
                              _ErrorBanner(
                                error: cartivoPosErrorFrom(error),
                                onRetry:
                                    () => ref.invalidate(
                                      orderDetailProvider(event.data.id),
                                    ),
                              ),
                            _OrderContent(data: data),
                          ],
                        ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            isLoading ? const _TotalBarSkeleton() : _TotalBar(data: data),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final OrderEvent event;
  final OrderData data;

  const _SheetHeader({required this.event, required this.data});

  @override
  Widget build(BuildContext context) {
    final created = data.createdAt.toLocal();
    final placed = DateUtils.isSameDay(created, DateTime.now())
        ? DateFormat('h:mm a').format(created)
        : DateFormat('MMM d, h:mm a').format(created);
    final wasUpdated = data.updatedAt.difference(data.createdAt).inSeconds >= 60;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${(data.id)}',
                style: AppTextStyles.headingLg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Placed $placed'
                '${wasUpdated ? ' · Updated ${_relativeTime(data.updatedAt)}' : ''}',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        _SheetStatusPill(
          status: classifyOrderStatus(
            OrderEvent(eventId: event.eventId, type: event.type, data: data),
          ),
          rawStatus: data.status,
        ),
      ],
    );
  }
}

/// Filled status pill for the sheet. Same colors as the list's outlined badge,
/// on the matching `*Light` surface.
class _SheetStatusPill extends StatelessWidget {
  final OrderCardStatus status;
  final String rawStatus;

  const _SheetStatusPill({required this.status, required this.rawStatus});

  @override
  Widget build(BuildContext context) {
    final (label, color) = orderStatusPillStyle(status);
    final background = switch (status) {
      OrderCardStatus.pending ||
      OrderCardStatus.preparing => AppColors.warningLight,
      OrderCardStatus.ready => AppColors.successLight,
      OrderCardStatus.cancelled => AppColors.errorLight,
      OrderCardStatus.fulfilled || OrderCardStatus.unknown => AppColors.background,
    };
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.4,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        status == OrderCardStatus.unknown ? rawStatus : label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodySm.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final CartivoPosError error;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.sm,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error),
              Expanded(child: Text(error.message, style: AppTextStyles.bodyMd)),
            ],
          ),
          if (error.isRetryable)
            SizedBox(
              height: AppSpacing.touchMin,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderContent extends StatelessWidget {
  final OrderData data;

  const _OrderContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final money = _moneyFormat(data.currency);
    final fulfillment = switch (data.fulfillmentType) {
      FulfillmentType.onSite => ('On-site', Icons.storefront_outlined),
      FulfillmentType.pickup => ('Pickup', Icons.shopping_bag_outlined),
      FulfillmentType.delivery => ('Delivery', Icons.local_shipping_outlined),
      FulfillmentType.other => null,
    };
    final location = [
      data.facilityName,
      data.districtName,
    ].firstWhere((s) => (s ?? '').isNotEmpty, orElse: () => null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (fulfillment != null || location != null) ...[
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (fulfillment != null)
                _InfoChip(icon: fulfillment.$2, label: fulfillment.$1),
              if (location != null)
                _InfoChip(icon: Icons.place_outlined, label: location),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _CustomerRow(name: data.customerName, email: data.customerEmail),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ITEMS',
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${data.items.length}',
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (data.items.isEmpty)
          Text(
            'No items on this order.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.textDisabled),
          )
        else
          for (final item in data.items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _ItemRow(item: item, money: money),
            ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelLg,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  final String? name;
  final String? email;

  const _CustomerRow({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    final hasName = (name ?? '').trim().isNotEmpty;
    final hasEmail = (email ?? '').isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        spacing: AppSpacing.md,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child:
                hasName
                    ? Text(
                      _initials(name!),
                      style: AppTextStyles.labelLg.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                    : const Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                    ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasName ? name! : 'Guest',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingSm,
                ),
                if (hasEmail)
                  Text(
                    email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final OrderEventItem item;
  final NumberFormat money;

  const _ItemRow({required this.item, required this.money});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Text(
            '${item.quantity}×',
            style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: AppTextStyles.labelLg),
                if (item.quantity > 1)
                  Text(
                    '${money.format(item.price)} each',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            money.format(item.price * item.quantity),
            style: AppTextStyles.labelLg,
          ),
        ),
      ],
    );
  }
}

class _TotalBar extends StatelessWidget {
  final OrderData data;

  const _TotalBar({required this.data});

  @override
  Widget build(BuildContext context) {
    final count = data.items.length;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total', style: AppTextStyles.labelLg),
              Text(
                '$count item${count == 1 ? '' : 's'}',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Text(_moneyFormat(data.currency).format(data.total), style: AppTextStyles.priceLg),
        ],
      ),
    );
  }
}

Color _usePulseColor(BuildContext context) {
  final controller = useAnimationController(
    duration: const Duration(milliseconds: 1400),
  );
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  useEffect(() {
    if (!reduceMotion) controller.repeat(reverse: true);
    return null;
  }, [reduceMotion]);
  final t = useAnimation(controller);
  return Color.lerp(AppColors.divider, AppColors.surfaceVariant, t)!;
}

class _Bone extends StatelessWidget {
  final double? width;
  final double height;
  final Color color;
  final bool circle;

  const _Bone({
    this.width,
    required this.height,
    required this.color,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(AppSpacing.radiusSm),
      ),
    );
  }
}

class _SheetSkeleton extends HookWidget {
  final int itemCount;

  const _SheetSkeleton({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    final c = _usePulseColor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          spacing: AppSpacing.sm,
          children: [
            _Bone(width: 96, height: 32, color: c),
            _Bone(width: 128, height: 32, color: c),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: const BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: AppColors.divider),
            ),
          ),
          child: Row(
            spacing: AppSpacing.md,
            children: [
              _Bone(width: 40, height: 40, color: c, circle: true),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.sm,
                  children: [
                    _Bone(width: 128, height: 16, color: c),
                    _Bone(width: 176, height: 12, color: c),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Bone(width: 48, height: 12, color: c),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < itemCount; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.md,
              children: [
                _Bone(width: 32, height: 32, color: c),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.sm,
                    children: [
                      _Bone(width: 160, height: 16, color: c),
                      _Bone(width: 80, height: 12, color: c),
                    ],
                  ),
                ),
                _Bone(width: 64, height: 16, color: c),
              ],
            ),
          ),
      ],
    );
  }
}

class _TotalBarSkeleton extends HookWidget {
  const _TotalBarSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = _usePulseColor(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.sm,
            children: [
              _Bone(width: 48, height: 16, color: c),
              _Bone(width: 56, height: 12, color: c),
            ],
          ),
          _Bone(width: 112, height: 32, color: c),
        ],
      ),
    );
  }
}

String _shortOrderId(String id) =>
    id.length > 12 ? id.substring(0, 8).toUpperCase() : id;

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  final first = parts.first[0];
  final last = parts.length > 1 ? parts.last[0] : '';
  return '$first$last'.toUpperCase();
}

NumberFormat _moneyFormat(String currency) =>
    currency.isEmpty || currency == 'PHP'
        ? NumberFormat.currency(symbol: '₱')
        : NumberFormat.simpleCurrency(name: currency);

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
