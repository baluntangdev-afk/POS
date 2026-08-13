import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/button.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/top_app_bar.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/replenishment_product.dart';
import '../state/replenishment_cart_notifier.dart';
import '../state/replenishment_orders_notifier.dart';
import '../state/replenishment_products_notifier.dart';

class ReplenishmentScreen extends ConsumerWidget {
  const ReplenishmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final state = ref.watch(replenishmentProductsProvider);

    ref.listen(replenishmentProductsProvider, (previous, next) {
      if (next case AsyncError(:final error)) {
        showNetworkErrorDialog(
          context,
          error: error,
          onRetry: () => ref.read(replenishmentProductsProvider.notifier).refresh(),
        );
      }
    });

    return WindowsScaffold(
      backgroundColor: ColorSet.background,
      floatingActionButton: const _CartSummaryBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Column(
        children: [
          TopAppBar(
            title: 'Replenishment',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _OrdersBadgeButton(),
                IconButton(
                  onPressed: () => ref.read(replenishmentProductsProvider.notifier).refresh(),
                  icon: Icon(Icons.refresh_rounded, color: ColorSet.light, size: r.value(kiosk: 24, tablet: 22, phone: 20)),
                ),
              ],
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
                  onRetry: () => ref.read(replenishmentProductsProvider.notifier).refresh(),
                ),
                data: (products) =>
                    products.isEmpty ? const _EmptyState() : _ProductList(products: products),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersBadgeButton extends ConsumerWidget {
  const _OrdersBadgeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final pendingCount = ref.watch(replenishmentPendingOrdersCountProvider);

    return IconButton(
      onPressed: () => const ReplenishmentOrdersRoute().push<void>(context),
      icon: Badge(
        label: Text('$pendingCount'),
        isLabelVisible: pendingCount > 0,
        backgroundColor: ColorSet.danger,
        child: Icon(
          Icons.receipt_long_rounded,
          color: ColorSet.light,
          size: r.value(kiosk: 24, tablet: 22, phone: 20),
        ),
      ),
    );
  }
}

class _CartSummaryBar extends ConsumerWidget {
  const _CartSummaryBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final cartItems = ref.watch(replenishmentCartProvider);

    return AnimatedSwitcher(
      duration: POSAnimation.normal,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: cartItems.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: EdgeInsets.only(bottom: r.value(kiosk: 16, tablet: 12, phone: 8)),
              child: DecoratedBox(
                key: const ValueKey('replenishment-cart-bar'),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: ColorSet.gradientBg,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(POSRadius.full),
                  boxShadow: POSShadow.button,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(POSRadius.full),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(POSRadius.full),
                    onTap: () => const ReplenishmentCartRoute().push<void>(context),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: r.value(kiosk: 28, tablet: 24, phone: 20),
                        vertical: r.value(kiosk: 18, tablet: 16, phone: 14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${cartItems.fold<int>(0, (sum, item) => sum + item.quantity)}',
                              style: TextStyle(
                                fontSize: r.value(kiosk: 13, tablet: 12, phone: 11),
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Gap(r.value(kiosk: 12, tablet: 10, phone: 8)),
                          Text(
                            'View Cart',
                            style: TextStyle(
                              fontSize: r.value(kiosk: 16, tablet: 15, phone: 14),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Gap(r.value(kiosk: 8, tablet: 6, phone: 4)),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: r.value(kiosk: 18, tablet: 16, phone: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
            Icons.inventory_2_outlined,
            size: r.value(kiosk: 80.0, tablet: 64.0, phone: 48.0),
            color: POSColors.textDisabled,
          ),
          Gap(r.value(kiosk: 16.0, tablet: 12.0, phone: 8.0)),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: r.value(kiosk: 20.0, tablet: 16.0, phone: 14.0),
              fontWeight: FontWeight.w600,
              color: POSColors.textSecondary,
            ),
          ),
          Gap(r.value(kiosk: 8.0, tablet: 6.0, phone: 4.0)),
          Text(
            'Replenishment products will show up here.',
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

class _ProductList extends StatelessWidget {
  const _ProductList({required this.products});

  final List<ReplenishmentProduct> products;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: r.value(kiosk: 16, tablet: 12, phone: 8),
      children: [
        Text(
          '${products.length} ${products.length == 1 ? 'Product' : 'Products'}',
          style: TextStyle(
            fontSize: r.value(kiosk: 15.0, tablet: 14.0, phone: 13.0),
            fontWeight: FontWeight.w600,
            color: POSColors.textSecondary,
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: r.value(kiosk: 220.0, tablet: 180.0, phone: 150.0),
              mainAxisExtent: r.value(kiosk: 236.0, tablet: 204.0, phone: 176.0),
              crossAxisSpacing: r.value(kiosk: 16.0, tablet: 12.0, phone: 8.0),
              mainAxisSpacing: r.value(kiosk: 16.0, tablet: 12.0, phone: 8.0),
            ),
            itemCount: products.length,
            itemBuilder: (context, index) => _ProductCard(product: products[index]),
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final ReplenishmentProduct product;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: ColorSet.primary.withValues(alpha: 0.08),
                  child: Center(
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: ColorSet.primary.withValues(alpha: 0.55),
                      size: r.value(kiosk: 48.0, tablet: 40.0, phone: 32.0),
                    ),
                  ),
                ),
                Positioned(
                  right: r.value(kiosk: 8.0, tablet: 7.0, phone: 6.0),
                  bottom: r.value(kiosk: 8.0, tablet: 7.0, phone: 6.0),
                  child: _QuantityControl(product: product),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(r.value(kiosk: 12.0, tablet: 10.0, phone: 8.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: r.value(kiosk: 14.0, tablet: 13.0, phone: 12.0),
                    fontWeight: FontWeight.w700,
                    color: POSColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Gap(r.value(kiosk: 4, tablet: 3, phone: 2)),
                Text(
                  '${product.currency} ${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: r.value(kiosk: 15.0, tablet: 14.0, phone: 13.0),
                    fontWeight: FontWeight.w800,
                    color: ColorSet.primary,
                    letterSpacing: -0.3,
                  ),
                ),
                Gap(r.value(kiosk: 2, tablet: 2, phone: 1)),
                Text(
                  'Added ${dateFormat.format(product.createdAt)}',
                  style: TextStyle(
                    fontSize: r.value(kiosk: 11.0, tablet: 10.0, phone: 9.0),
                    color: POSColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityControl extends ConsumerWidget {
  const _QuantityControl({required this.product});

  final ReplenishmentProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final quantity = ref.watch(
      replenishmentCartProvider.select((items) {
        final index = items.indexWhere((item) => item.product.id == product.id);
        return index == -1 ? 0 : items[index].quantity;
      }),
    );
    final notifier = ref.read(replenishmentCartProvider.notifier);
    final btnSize = r.value(kiosk: 30.0, tablet: 27.0, phone: 25.0);

    if (quantity == 0) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: POSGradient.primary,
          shape: BoxShape.circle,
          boxShadow: POSShadow.button,
        ),
        child: SizedBox(
          width: r.value(kiosk: 36.0, tablet: 32.0, phone: 28.0),
          height: r.value(kiosk: 36.0, tablet: 32.0, phone: 28.0),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => notifier.addItem(product),
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: r.value(kiosk: 20.0, tablet: 18.0, phone: 16.0),
              ),
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.full),
        boxShadow: POSShadow.button,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            size: btnSize,
            onTap: () => notifier.decrementItem(product.id),
          ),
          SizedBox(
            width: r.value(kiosk: 22.0, tablet: 20.0, phone: 18.0),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: r.value(kiosk: 12.0, tablet: 11.0, phone: 10.0),
                fontWeight: FontWeight.w700,
                color: POSColors.textPrimary,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            size: btnSize,
            onTap: () => notifier.incrementItem(product.id),
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
          child: Icon(icon, color: ColorSet.primary, size: size * 0.55),
        ),
      ),
    );
  }
}
