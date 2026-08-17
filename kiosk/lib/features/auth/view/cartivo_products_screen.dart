import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/button.dart';
import '../../../widgets/cartivo_app_bar.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/product_image_placeholder.dart';
import '../../cartivo_orders/state/cartivo_orders_notifier.dart';
import '../../cartivo_products/entities/cartivo_product.dart';
import '../../cartivo_products/state/cartivo_cart_notifier.dart';
import '../../cartivo_products/state/cartivo_products_notifier.dart';

class CartivoProductsScreen extends ConsumerWidget {
  const CartivoProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final state = ref.watch(cartivoProductsProvider);

    ref.listen(cartivoProductsProvider, (previous, next) {
      if (next case AsyncError(:final error)) {
        showNetworkErrorDialog(
          context,
          error: error,
          onRetry: () => ref.read(cartivoProductsProvider.notifier).refresh(),
        );
      }
    });

    return Scaffold(
      backgroundColor: POSColors.surfaceSubtle,
      floatingActionButton: const _CartSummaryBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: CartivoAppBar(
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _OrdersBadgeButton(),
            IconButton(
              onPressed: () => ref.read(cartivoProductsProvider.notifier).refresh(),
              icon: Icon(Icons.refresh_rounded, color: ColorSet.primary, size: r.value(kiosk: 24, tablet: 22, phone: 20)),
            ),
          ],
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
            onRetry: () => ref.read(cartivoProductsProvider.notifier).refresh(),
          ),
          data: (products) =>
              products.isEmpty ? const _EmptyState() : _ProductList(products: products),
        ),
      ),
    );
  }
}

class _OrdersBadgeButton extends ConsumerWidget {
  const _OrdersBadgeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final pendingCount = ref.watch(cartivoPendingOrdersCountProvider);

    return IconButton(
      onPressed: () => const CartivoOrdersRoute().push<void>(context),
      icon: Badge(
        label: Text('$pendingCount'),
        isLabelVisible: pendingCount > 0,
        backgroundColor: ColorSet.danger,
        child: Icon(
          Icons.receipt_long_rounded,
          color: ColorSet.primary,
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
    final cartItems = ref.watch(cartivoCartProvider);

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
                key: const ValueKey('cartivo-cart-bar'),
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
                    onTap: () => const CartivoCartRoute().push<void>(context),
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
            Icons.shopping_bag_outlined,
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
            'Your Cartivo product catalog will show up here.',
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

  final List<CartivoProduct> products;

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
            padding: EdgeInsets.only(bottom: r.value(kiosk: 96.0, tablet: 88.0, phone: 80.0)),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: r.value(kiosk: 210.0, tablet: 170.0, phone: 140.0),
              mainAxisExtent: r.value(kiosk: 250.0, tablet: 210.0, phone: 180.0),
              crossAxisSpacing: r.value(kiosk: 14.0, tablet: 12.0, phone: 8.0),
              mainAxisSpacing: r.value(kiosk: 14.0, tablet: 12.0, phone: 8.0),
            ),
            itemCount: products.length,
            itemBuilder: (context, index) => CartivoProductTile(product: products[index]),
          ),
        ),
      ],
    );
  }
}

/// Product tile matching the ordering grid's product card: a placeholder
/// icon on a tinted panel with a floating add-to-cart control, name + price
/// below.
class CartivoProductTile extends StatelessWidget {
  const CartivoProductTile({super.key, required this.product});

  final CartivoProduct product;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final style = productPlaceholder(product.name);

    return Container(
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                Center(
                  child: Icon(
                    style.icon,
                    size: r.value(kiosk: 48.0, tablet: 40.0, phone: 32.0),
                    color: style.fg,
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _QuantityControl(product: product),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              r.value(kiosk: 12.0, tablet: 10.0, phone: 8.0),
              0,
              r.value(kiosk: 12.0, tablet: 10.0, phone: 8.0),
              r.value(kiosk: 12.0, tablet: 10.0, phone: 8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: r.value(kiosk: 14.0, tablet: 12.0, phone: 11.0),
                    fontWeight: FontWeight.w700,
                    color: POSColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  formatPesoPrice(product.currency, product.price),
                  style: TextStyle(
                    fontSize: r.value(kiosk: 14.0, tablet: 12.0, phone: 11.0),
                    fontWeight: FontWeight.w800,
                    color: ColorSet.primary,
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

final _pesoFormat = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);

String formatPesoPrice(String currency, double price) =>
    currency == 'PHP' ? _pesoFormat.format(price) : '$currency ${price.toStringAsFixed(2)}';

class _QuantityControl extends ConsumerWidget {
  const _QuantityControl({required this.product});

  final CartivoProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final quantity = ref.watch(
      cartivoCartProvider.select((items) {
        final index = items.indexWhere((item) => item.product.id == product.id);
        return index == -1 ? 0 : items[index].quantity;
      }),
    );
    final notifier = ref.read(cartivoCartProvider.notifier);
    final btnSize = r.value(kiosk: 30.0, tablet: 27.0, phone: 25.0);

    if (quantity == 0) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: POSGradient.primary,
          shape: BoxShape.circle,
          boxShadow: POSShadow.button,
        ),
        child: SizedBox(
          width: r.value(kiosk: 38.0, tablet: 32.0, phone: 28.0),
          height: r.value(kiosk: 38.0, tablet: 32.0, phone: 28.0),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => notifier.addItem(product),
              child: Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: r.value(kiosk: 22.0, tablet: 18.0, phone: 16.0),
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
