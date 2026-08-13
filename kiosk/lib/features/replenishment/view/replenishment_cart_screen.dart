import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/button.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/top_app_bar.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/replenishment_cart_item.dart';
import '../state/replenishment_cart_notifier.dart';
import '../state/replenishment_checkout_notifier.dart';

class ReplenishmentCartScreen extends ConsumerWidget {
  const ReplenishmentCartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final cartItems = ref.watch(replenishmentCartProvider);

    ref.listen(replenishmentCheckoutProvider, (previous, next) {
      switch (next) {
        case AsyncData(value: final order?):
          showMessageDialog(
            context,
            type: DialogType.success,
            title: 'Order Placed',
            message:
                'Order #${order.id} for ${order.currency} '
                '${order.total.toStringAsFixed(2)} has been created. '
                'Pay for it anytime from the Orders section.',
            onPrimaryPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              if (context.mounted && context.canPop()) {
                context.pop();
              }
            },
          );
        case AsyncError(:final error):
          showNetworkErrorDialog(
            context,
            error: error,
            onRetry: () => ref.read(replenishmentCheckoutProvider.notifier).checkout(),
          );
        default:
          break;
      }
    });

    return WindowsScaffold(
      backgroundColor: ColorSet.background,
      body: Column(
        children: [
          TopAppBar(
            title: 'Replenishment Cart',
            trailing: cartItems.isEmpty
                ? null
                : IconButton(
                    onPressed: () => ref.read(replenishmentCartProvider.notifier).clear(),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: ColorSet.light,
                      size: r.value(kiosk: 24, tablet: 22, phone: 20),
                    ),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(r.value(kiosk: 32, tablet: 24, phone: 16)),
              child: cartItems.isEmpty
                  ? const _EmptyCartState()
                  : _CartItemList(items: cartItems),
            ),
          ),
          if (cartItems.isNotEmpty) _CartTotalBar(items: cartItems),
        ],
      ),
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: r.value(kiosk: 80.0, tablet: 64.0, phone: 48.0),
            color: POSColors.textDisabled,
          ),
          Gap(r.value(kiosk: 16.0, tablet: 12.0, phone: 8.0)),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: r.value(kiosk: 20.0, tablet: 16.0, phone: 14.0),
              fontWeight: FontWeight.w600,
              color: POSColors.textSecondary,
            ),
          ),
          Gap(r.value(kiosk: 8.0, tablet: 6.0, phone: 4.0)),
          Text(
            'Add replenishment products to get started.',
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

class _CartItemList extends StatelessWidget {
  const _CartItemList({required this.items});

  final IList<ReplenishmentCartItem> items;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => Gap(r.value(kiosk: 12, tablet: 10, phone: 8)),
      itemBuilder: (context, index) => _CartItemCard(item: items[index]),
    );
  }
}

class _CartItemCard extends ConsumerWidget {
  const _CartItemCard({required this.item});

  final ReplenishmentCartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final notifier = ref.read(replenishmentCartProvider.notifier);
    final btnSize = r.value(kiosk: 36.0, tablet: 32.0, phone: 30.0);

    return Container(
      padding: EdgeInsets.all(r.value(kiosk: 16, tablet: 14, phone: 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: r.value(kiosk: 72.0, tablet: 64.0, phone: 56.0),
            height: r.value(kiosk: 72.0, tablet: 64.0, phone: 56.0),
            decoration: BoxDecoration(
              color: ColorSet.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(POSRadius.lg),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              color: ColorSet.primary.withValues(alpha: 0.55),
              size: r.value(kiosk: 32.0, tablet: 28.0, phone: 24.0),
            ),
          ),
          Gap(r.value(kiosk: 16, tablet: 12, phone: 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: TextStyle(
                          fontSize: r.value(kiosk: 15.0, tablet: 14.0, phone: 13.0),
                          fontWeight: FontWeight.w700,
                          color: POSColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: r.value(kiosk: 28.0, tablet: 26.0, phone: 24.0),
                      height: r.value(kiosk: 28.0, tablet: 26.0, phone: 24.0),
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => notifier.removeItem(item.product.id),
                          child: Icon(
                            Icons.close_rounded,
                            color: POSColors.textTertiary,
                            size: r.value(kiosk: 16.0, tablet: 15.0, phone: 14.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Gap(r.value(kiosk: 4, tablet: 3, phone: 2)),
                Text(
                  '${item.product.currency} ${item.product.price.toStringAsFixed(2)} each',
                  style: TextStyle(
                    fontSize: r.value(kiosk: 12.0, tablet: 11.0, phone: 10.0),
                    color: POSColors.textTertiary,
                  ),
                ),
                Gap(r.value(kiosk: 10, tablet: 8, phone: 6)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.product.currency} ${item.totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: r.value(kiosk: 16.0, tablet: 15.0, phone: 14.0),
                        fontWeight: FontWeight.w800,
                        color: ColorSet.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: ColorSet.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(POSRadius.full),
                        border: Border.all(color: ColorSet.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StepperButton(
                            icon: item.quantity <= 1
                                ? Icons.delete_outline_rounded
                                : Icons.remove_rounded,
                            size: btnSize,
                            onTap: () => notifier.decrementItem(item.product.id),
                          ),
                          SizedBox(
                            width: r.value(kiosk: 28.0, tablet: 24.0, phone: 22.0),
                            child: Text(
                              '${item.quantity}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: r.value(kiosk: 13.0, tablet: 12.0, phone: 11.0),
                                fontWeight: FontWeight.w700,
                                color: POSColors.textPrimary,
                              ),
                            ),
                          ),
                          _StepperButton(
                            icon: Icons.add_rounded,
                            size: btnSize,
                            onTap: () => notifier.incrementItem(item.product.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.size, required this.onTap});

  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, color: ColorSet.primary, size: size * 0.5),
        ),
      ),
    );
  }
}

class _CartTotalBar extends ConsumerWidget {
  const _CartTotalBar({required this.items});

  final IList<ReplenishmentCartItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final totalQuantity = items.fold<int>(0, (sum, item) => sum + item.quantity);
    final totalPrice = items.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final currency = items.first.product.currency;
    final isCheckingOut = ref.watch(replenishmentCheckoutProvider).isLoading;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: r.value(kiosk: 32, tablet: 24, phone: 16),
        vertical: r.value(kiosk: 20, tablet: 16, phone: 12),
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: POSColors.borderDefault)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '$totalQuantity ${totalQuantity == 1 ? 'item' : 'items'}',
                style: TextStyle(
                  fontSize: r.value(kiosk: 14.0, tablet: 13.0, phone: 12.0),
                  color: POSColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                'Total: ',
                style: TextStyle(
                  fontSize: r.value(kiosk: 15.0, tablet: 14.0, phone: 13.0),
                  fontWeight: FontWeight.w600,
                  color: POSColors.textSecondary,
                ),
              ),
              Text(
                '$currency ${totalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: r.value(kiosk: 22.0, tablet: 19.0, phone: 17.0),
                  fontWeight: FontWeight.w800,
                  color: ColorSet.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Gap(r.value(kiosk: 16, tablet: 14, phone: 12)),
          SizedBox(
            width: double.infinity,
            child: Button(
              label: isCheckingOut
                  ? SizedBox(
                      width: r.value(kiosk: 20.0, tablet: 18.0, phone: 16.0),
                      height: r.value(kiosk: 20.0, tablet: 18.0, phone: 16.0),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                        strokeCap: StrokeCap.round,
                      ),
                    )
                  : const Text('Checkout'),
              backgroundColor: ColorSet.primary,
              foregroundColor: Colors.white,
              onPressed: isCheckingOut
                  ? null
                  : () => ref.read(replenishmentCheckoutProvider.notifier).checkout(),
            ),
          ),
        ],
      ),
    );
  }
}
