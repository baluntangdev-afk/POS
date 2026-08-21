import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../gen/assets.gen.dart';
import 'package:decimal/decimal.dart';

import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../utils/physical_keyboard_detector.dart';
import '../../../utils/windows_touch_keyboard.dart';
import '../../../widgets/onscreen_keyboard/keyboard_suppress.dart';
import '../../../widgets/onscreen_keyboard/onscreen_keyboard.dart';
import '../../../widgets/product_image_placeholder.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/line_item.dart';
import '../entities/product.dart';
import '../enums/sale_type.dart';
import '../state/ordering_notifier.dart';
import 'discount_screen.dart';
import 'line_item_dialog.dart';

class OrderingScreen extends ConsumerWidget {
  const OrderingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const WindowsScaffold(
      backgroundColor: ColorSet.background,
      body: _AdaptiveOrderingLayout(),
    );
  }
}

// ── Adaptive layout — splits or stacks based on available width ───────────────
class _AdaptiveOrderingLayout extends HookConsumerWidget {
  const _AdaptiveOrderingLayout();

  static const double _splitThreshold = 720;
  static const double _panelWidth = 300;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;
    final wide = MediaQuery.sizeOf(context).width >= _splitThreshold;
    final panelOpen = useState(false);
    final prevWide = useRef<bool?>(null);

    final cartCount = ref.watch(
      orderingProvider.select(
        (it) => it.value?.sale.items.fold(0, (sum, item) => sum + item.quantity) ?? 0,
      ),
    );

    // Products and categories are fetched once in OrderingNotifier.build() and
    // cached for the life of the sale (so the cart survives navigating away
    // and back). Silently re-fetch both each time this screen is shown, so
    // categories/products added/edited/deleted in Inventory Management show up
    // without requiring an app restart.
    useEffect(() {
      Future.microtask(() {
        ref.read(orderingProvider.notifier).refreshProductGroups();
        ref.read(orderingProvider.notifier).refreshProducts();
      });
      return null;
    }, const []);

    // Auto-close the side panel when the layout switches to wide.
    useEffect(() {
      if (wide && prevWide.value == false) panelOpen.value = false;
      prevWide.value = wide;
      return null;
    }, [wide]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OrderingHeader(
          cartCount: wide ? 0 : cartCount,
          onCartTap: wide ? null : () => panelOpen.value = !panelOpen.value,
        ),
        Container(
          height: r.value<double>(kiosk: 64, tablet: 60, phone: 52),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: POSColors.borderDefault)),
          ),
          child: const _CategoryChipRow(),
        ),
        Expanded(
          child:
              wide
                  ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Expanded(child: _ProductGrid()),
                      SizedBox(
                        width: r.value(
                          kiosk: _panelWidth + 20,
                          tablet: _panelWidth,
                          phone: _panelWidth,
                        ),
                        child: const _OrderPanel(),
                      ),
                    ],
                  )
                  : Stack(
                    children: [
                      const _ProductGrid(),
                      // Dim backdrop — tapping closes the panel
                      AnimatedOpacity(
                        opacity: panelOpen.value ? 1.0 : 0.0,
                        duration: POSAnimation.normal,
                        child: IgnorePointer(
                          ignoring: !panelOpen.value,
                          child: GestureDetector(
                            onTap: () => panelOpen.value = false,
                            child: Container(color: Colors.black.withValues(alpha: 0.35)),
                          ),
                        ),
                      ),
                      // Sliding right panel
                      AnimatedPositioned(
                        duration: POSAnimation.normal,
                        curve: POSAnimation.easeOut,
                        right: panelOpen.value ? 0 : -(_panelWidth + 8),
                        top: 0,
                        bottom: 0,
                        width: _panelWidth,
                        child: const Material(
                          elevation: 8,
                          shadowColor: Colors.black26,
                          child: _OrderPanel(),
                        ),
                      ),
                    ],
                  ),
        ),
      ],
    );
  }
}

class _OrderingHeader extends StatelessWidget {
  const _OrderingHeader({this.cartCount = 0, this.onCartTap});

  final int cartCount;
  final VoidCallback? onCartTap;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Container(
      height: r.value(kiosk: 68.0, tablet: 60.0, phone: 52.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: POSColors.borderDefault)),
        boxShadow: POSShadow.headerBottom,
      ),
      padding: EdgeInsets.symmetric(horizontal: r.value(kiosk: 24.0, tablet: 16.0, phone: 12.0)),
      child: Row(
        children: [
          _HeaderBackButton(size: r.value(kiosk: 52.0, tablet: 44.0, phone: 38.0)),
          const Spacer(),
          Assets.images.cartivoLogo.image(height: r.value(kiosk: 36.0, tablet: 28.0, phone: 22.0)),
          const Spacer(),
          SizedBox(
            width: r.value<double>(kiosk: 110, tablet: 90, phone: 76),
            child:
                onCartTap != null
                    ? Align(
                      alignment: Alignment.centerRight,
                      child: _CartBadgeButton(count: cartCount, onTap: onCartTap!),
                    )
                    : null,
          ),
        ],
      ),
    );
  }
}

class _CartBadgeButton extends StatelessWidget {
  const _CartBadgeButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final size = r.value<double>(kiosk: 48, tablet: 42, phone: 36);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: POSColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(POSRadius.md),
              border: Border.all(color: POSColors.borderDefault),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: r.value<double>(kiosk: 24, tablet: 20, phone: 18),
              color: ColorSet.primary,
            ),
          ),
          if (count > 0)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: ColorSet.primary,
                  borderRadius: BorderRadius.circular(POSRadius.full),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  const _HeaderBackButton({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      child: OutlinedButton.icon(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
            return;
          }
          const MenuRoute().go(context);
        },
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
        label: const Text('Back'),
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorSet.primary,
          side: const BorderSide(color: ColorSet.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.md)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _CategoryChipRow extends HookConsumerWidget {
  const _CategoryChipRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      orderingProvider.select((it) {
        final value = it.value;
        return (
          productGroups: value?.productGroups ?? const IList.empty(),
          selectedGroup: value?.selectedGroup,
        );
      }),
    );
    final productGroups = state.productGroups;
    final selectedGroup = state.selectedGroup;

    final scrollController = useScrollController();
    final canScrollLeft = useState(false);
    final canScrollRight = useState(false);

    void updateScrollState() {
      if (!scrollController.hasClients) return;
      final pos = scrollController.position;
      canScrollLeft.value = pos.pixels > 2;
      canScrollRight.value = pos.pixels < pos.maxScrollExtent - 2;
    }

    useEffect(() {
      scrollController.addListener(updateScrollState);
      WidgetsBinding.instance.addPostFrameCallback((_) => updateScrollState());
      return () => scrollController.removeListener(updateScrollState);
    }, const []);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) => updateScrollState());
      return null;
    }, [productGroups.length]);

    const arrowWidth = 60.0;
    const animDuration = Duration(milliseconds: 250);
    const scrollStep = 240.0;

    return Stack(
      children: [
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.stylus,
            },
          ),
          child: ListView.builder(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: productGroups.length,
            itemBuilder: (context, index) {
              final group = productGroups[index];
              final isSelected = group == selectedGroup;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AnimatedContainer(
                  duration: POSAnimation.fast,
                  child: FilterChip(
                    label: Text(group.name),
                    selected: isSelected,
                    onSelected: (_) => ref.read(orderingProvider.notifier).selectGroup(group),
                    selectedColor: ColorSet.primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : POSColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: isSelected ? ColorSet.primary : POSColors.borderStrong,
                      width: 1.5,
                    ),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(POSRadius.sm),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Left arrow
        IgnorePointer(
          ignoring: !canScrollLeft.value,
          child: AnimatedOpacity(
            opacity: canScrollLeft.value ? 1.0 : 0.0,
            duration: animDuration,
            curve: Curves.easeInOut,
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap:
                    () => scrollController.animateTo(
                      scrollController.offset - scrollStep,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.decelerate,
                    ),
                child: Container(
                  width: arrowWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.white.withValues(alpha: 0)],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: POSShadow.card,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: POSColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Right arrow
        IgnorePointer(
          ignoring: !canScrollRight.value,
          child: AnimatedOpacity(
            opacity: canScrollRight.value ? 1.0 : 0.0,
            duration: animDuration,
            curve: Curves.easeInOut,
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap:
                    () => scrollController.animateTo(
                      scrollController.offset + scrollStep,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.decelerate,
                    ),
                child: Container(
                  width: arrowWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      colors: [Colors.white.withValues(alpha: 0), Colors.white],
                      stops: const [0.0, 0.6],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: POSShadow.card,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: POSColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: POSColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(POSRadius.lg),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 28,
                color: POSColors.textTertiary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cart is empty',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: POSColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap a product to add',
              style: TextStyle(fontSize: 12, color: POSColors.textTertiary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductGrid extends ConsumerWidget {
  const _ProductGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderingProvider.select((it) => it.whenData((data) => data.products)));
    final groupName = ref.watch(orderingProvider.select((it) => it.value?.selectedGroup?.name));
    if (state.isLoading) {
      return const Center(child: _LoadingState());
    }
    // Surface load failures instead of disguising them as an empty category —
    // otherwise an auth/network error looks identical to "no products" and the
    // grid appears blank for the user with no way to recover.
    if (state case AsyncError()) {
      return Center(child: _ProductsErrorState(onRetry: () => ref.invalidate(orderingProvider)));
    }
    final products = switch (state) {
      AsyncData(:final value) => value,
      _ => const IList<Product>.empty(),
    };
    if (products.isEmpty) {
      return const Center(child: _EmptyProductsState());
    }
    return RepaintBoundary(
      child: GridView.builder(
        padding: EdgeInsets.only(
          top: context.responsive.value(kiosk: 16.0, tablet: 12.0, phone: 10.0),
          left: context.responsive.value(kiosk: 20.0, tablet: 16.0, phone: 10.0),
          right: context.responsive.value(kiosk: 20.0, tablet: 16.0, phone: 10.0),
          bottom: context.responsive.value(kiosk: 20.0, tablet: 80.0, phone: 60.0),
        ),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: context.responsive.value(kiosk: 210.0, tablet: 170.0, phone: 140.0),
          mainAxisExtent: context.responsive.value(kiosk: 250.0, tablet: 210.0, phone: 180.0),
          crossAxisSpacing: context.responsive.value(kiosk: 14.0, tablet: 12.0, phone: 8.0),
          mainAxisSpacing: context.responsive.value(kiosk: 14.0, tablet: 12.0, phone: 8.0),
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _ProductCard(product: product, groupName: groupName);
        },
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: ColorSet.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(14),
          child: const CircularProgressIndicator(
            strokeWidth: 2.5,
            color: ColorSet.primary,
            strokeCap: StrokeCap.round,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Loading menu...',
          style: TextStyle(fontSize: 14, color: POSColors.textTertiary),
        ),
      ],
    );
  }
}

class _EmptyProductsState extends StatelessWidget {
  const _EmptyProductsState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: POSColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(POSRadius.lg),
          ),
          child: const Icon(Icons.restaurant_menu_rounded, size: 32, color: POSColors.textTertiary),
        ),
        const SizedBox(height: 12),
        const Text(
          'No products in this category',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: POSColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Select another category',
          style: TextStyle(fontSize: 13, color: POSColors.textTertiary),
        ),
      ],
    );
  }
}

class _ProductsErrorState extends StatelessWidget {
  const _ProductsErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(POSRadius.lg),
          ),
          child: const Icon(Icons.cloud_off_rounded, size: 32, color: Color(0xFFDC2626)),
        ),
        const SizedBox(height: 12),
        const Text(
          'Could not load products',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: POSColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Check your connection and try again',
          style: TextStyle(fontSize: 13, color: POSColors.textTertiary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: FilledButton.styleFrom(
              backgroundColor: ColorSet.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.md)),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, this.groupName});

  final Product product;
  final String? groupName;

  @override
  Widget build(BuildContext context) {
    final style = productPlaceholder(groupName);
    return Consumer(
      builder: (context, ref, _) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(POSRadius.xl),
            onTap: () async {
              final lineItem = await showLineItemDialog(context, productId: product.id);
              if (lineItem == null || !context.mounted) return;
              ref.read(orderingProvider.notifier).addLineItem(lineItem);
            },
            child: Container(
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
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(POSRadius.xl),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: product.image,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            // Fade only on the first decode; cached frames show
                            // instantly with no placeholder flash on rebuild.
                            fadeInDuration: POSAnimation.fast,
                            placeholderFadeInDuration: Duration.zero,
                            errorWidget:
                                (_, _, _) => Center(
                                  child: Icon(
                                    style.icon,
                                    size: context.responsive.value(
                                      kiosk: 48.0,
                                      tablet: 40.0,
                                      phone: 32.0,
                                    ),
                                    color: style.fg,
                                  ),
                                ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            width: context.responsive.value(kiosk: 38.0, tablet: 32.0, phone: 28.0),
                            height: context.responsive.value(
                              kiosk: 38.0,
                              tablet: 32.0,
                              phone: 28.0,
                            ),
                            decoration: const BoxDecoration(
                              gradient: POSGradient.primary,
                              shape: BoxShape.circle,
                              boxShadow: POSShadow.button,
                            ),
                            child: Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: context.responsive.value(
                                kiosk: 22.0,
                                tablet: 18.0,
                                phone: 16.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.responsive.value(kiosk: 12.0, tablet: 10.0, phone: 8.0),
                      0,
                      context.responsive.value(kiosk: 12.0, tablet: 10.0, phone: 8.0),
                      context.responsive.value(kiosk: 12.0, tablet: 10.0, phone: 8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: context.responsive.value(
                              kiosk: 14.0,
                              tablet: 12.0,
                              phone: 11.0,
                            ),
                            fontWeight: FontWeight.w700,
                            color: POSColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.price.pesoFormatted,
                          style: TextStyle(
                            fontSize: context.responsive.value(
                              kiosk: 14.0,
                              tablet: 12.0,
                              phone: 11.0,
                            ),
                            fontWeight: FontWeight.w800,
                            color: ColorSet.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// â”€â”€ Quantity stepper (used inside _OrderItemRow) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.full),
        border: Border.all(color: POSColors.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepBtn(icon: Icons.remove_rounded, onTap: quantity > 1 ? onDecrease : null),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: POSColors.textPrimary,
              ),
            ),
          ),
          _StepBtn(icon: Icons.add_rounded, onTap: onIncrease, filled: true),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, this.onTap, this.filled = false});

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: filled ? ColorSet.primary : ColorSet.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: filled ? Colors.white : (enabled ? ColorSet.primary : POSColors.textDisabled),
        ),
      ),
    );
  }
}

// â”€â”€ Per-item sale type pill toggle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SaleTypePill extends StatelessWidget {
  const _SaleTypePill({required this.selected, required this.onChanged});

  final SaleType? selected;
  final ValueChanged<SaleType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: POSColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(POSRadius.full),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _PillSegment(
            label: 'Dine In',
            isSelected: selected == SaleType.dineIn,
            onTap: () => onChanged(selected == SaleType.dineIn ? null : SaleType.dineIn),
          ),
          _PillSegment(
            label: 'Take Out',
            isSelected: selected == SaleType.takeOut,
            onTap: () => onChanged(selected == SaleType.takeOut ? null : SaleType.takeOut),
          ),
        ],
      ),
    );
  }
}

class _PillSegment extends StatelessWidget {
  const _PillSegment({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: POSAnimation.fast,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? ColorSet.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(POSRadius.full),
            boxShadow: isSelected ? POSShadow.button : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : POSColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Order panel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _OrderPanel extends HookConsumerWidget {
  const _OrderPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(
      orderingProvider.select((it) => it.value?.sale.items ?? const IList.empty()),
    );
    final selectedIndex = useState<int?>(null);

    useEffect(() {
      final sel = selectedIndex.value;
      if (sel != null && sel >= items.length) selectedIndex.value = null;
      return null;
    }, [items.length]);

    void replaceItem(int index, LineItem updated) =>
        ref.read(orderingProvider.notifier).replaceLineItem(updated, index: index);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: POSColors.borderDefault)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: POSColors.borderSubtle)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, size: 18, color: ColorSet.primary),
                const SizedBox(width: 8),
                const Text(
                  'Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: POSColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (items.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: ColorSet.primary,
                      borderRadius: BorderRadius.circular(POSRadius.full),
                    ),
                    child: Text(
                      '${items.fold(0, (sum, item) => sum + item.quantity)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Item list
          Expanded(
            child:
                items.isEmpty
                    ? const _EmptyCartState()
                    : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _OrderItemRow(
                          key: ValueKey(item.id),
                          item: item,
                          index: index,
                          isExpanded: selectedIndex.value == index,
                          onTap:
                              () =>
                                  selectedIndex.value = selectedIndex.value == index ? null : index,
                          onRemove: () {
                            if (selectedIndex.value == index) selectedIndex.value = null;
                            ref.read(orderingProvider.notifier).removeLineItem(index: index);
                          },
                          onQuantityChanged:
                              (qty) => replaceItem(index, item.copyWith(quantity: qty)),
                          onSaleTypeChanged:
                              (type) => replaceItem(index, item.copyWith(itemSaleType: type)),
                          onNotesChanged:
                              (notes) => replaceItem(
                                index,
                                item.copyWith(notes: notes.isEmpty ? null : notes),
                              ),
                          onClearDiscount:
                              item.discount != null
                                  ? () => ref
                                      .read(orderingProvider.notifier)
                                      .clearDiscount(index: index)
                                  : null,
                        );
                      },
                    ),
          ),

          if (items.isNotEmpty) const _OrderPanelFooter(),
        ],
      ),
    );
  }
}

class _CheckoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: POSGradient.primary,
        borderRadius: BorderRadius.circular(POSRadius.xxl),
        boxShadow: POSShadow.button,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(POSRadius.xxl),
        child: InkWell(
          borderRadius: BorderRadius.circular(POSRadius.xxl),
          onTap: () => const PaymentRoute().push<void>(context),
          child: const SizedBox(
            height: 48,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Proceed to Checkout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Order panel footer — VAT breakdown + discount + checkout ──────────────────
class _OrderPanelFooter extends ConsumerWidget {
  const _OrderPanelFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final computations = ref.watch(
      orderingProvider.select((it) {
        final sale = it.value?.sale;
        if (sale == null) return <({String label, Decimal amount})>[];
        return [
          (label: 'VATable Sales', amount: sale.vatableAmount),
          if (sale.vatExemptSales > Decimal.zero)
            (label: 'VAT-Exempt Sales', amount: sale.vatExemptSales),
          (label: 'VAT', amount: sale.vatAmount),
          if (sale.discountAmount > Decimal.zero) (label: 'Discount', amount: -sale.discountAmount),
          (label: 'Total', amount: sale.totalAmount),
        ];
      }),
    );

    final (:isLoading, :lineItemCount) = ref.watch(
      orderingProvider.select(
        (it) => (isLoading: it.isLoading, lineItemCount: it.value?.sale.items.length ?? 0),
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: POSColors.borderSubtle)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // VAT breakdown rows
          ...computations.map((c) {
            final (:label, :amount) = c;
            final isTotal = label == 'Total';
            if (isTotal) {
              return Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: POSColors.textPrimary,
                      ),
                    ),
                    Text(
                      amount.pesoFormatted,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: ColorSet.primary,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: POSColors.textTertiary)),
                  Text(
                    amount.pesoFormatted,
                    style: const TextStyle(
                      fontSize: 11,
                      color: POSColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          // Apply Discount
          SizedBox(
            height: 40,
            child: OutlinedButton.icon(
              onPressed: !isLoading && lineItemCount > 0 ? () => showDiscountDialog(context) : null,
              icon: const Icon(Icons.local_offer_outlined, size: 14),
              label: const Text('Apply Discount'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorSet.primary,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                side: BorderSide(color: ColorSet.primary.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.md)),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _CheckoutButton(),
        ],
      ),
    );
  }
}

class _OrderItemRow extends HookWidget {
  const _OrderItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.isExpanded,
    required this.onTap,
    required this.onRemove,
    required this.onQuantityChanged,
    required this.onSaleTypeChanged,
    required this.onNotesChanged,
    this.onClearDiscount,
  });

  final LineItem item;
  final int index;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<SaleType?> onSaleTypeChanged;
  final ValueChanged<String> onNotesChanged;
  final VoidCallback? onClearDiscount;

  @override
  Widget build(BuildContext context) {
    final notesController = useTextEditingController(text: item.notes ?? '');
    final notesFocus = useFocusNode();
    final hasPhysicalKeyboard = useValueListenable(PhysicalKeyboardDetector.attached);

    useEffect(() {
      void onFocusChange() {
        if (!notesFocus.hasFocus) onNotesChanged(notesController.text);
      }

      notesFocus.addListener(onFocusChange);
      return () => notesFocus.removeListener(onFocusChange);
    }, const []);

    useEffect(() {
      final newNotes = item.notes ?? '';
      if (notesController.text != newNotes && !notesFocus.hasFocus) {
        notesController.text = newNotes;
      }
      return null;
    }, [item.notes]);

    final modifierSummary = item.modifiers.expand((m) => m.options.map((o) => o.name)).join(', ');

    return AnimatedContainer(
      duration: POSAnimation.fast,
      decoration: BoxDecoration(
        color: isExpanded ? ColorSet.primary.withValues(alpha: 0.06) : POSColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(POSRadius.md),
        border: Border.all(color: isExpanded ? ColorSet.primary : Colors.transparent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // â”€â”€ Collapsed header â”€â”€
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(POSRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.productName} (${item.variant.name})',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isExpanded ? ColorSet.primary : POSColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'x${item.quantity}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: POSColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (item.itemSaleType != null)
                              _SaleTypeBadge(saleType: item.itemSaleType!),
                            if (item.discount != null)
                              GestureDetector(
                                onTap: onClearDiscount,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.local_offer_rounded,
                                        size: 8,
                                        color: Color(0xFFD97706),
                                      ),
                                      const SizedBox(width: 2),
                                      const Text(
                                        'Discounted',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFD97706),
                                        ),
                                      ),
                                      if (onClearDiscount != null) ...[
                                        const SizedBox(width: 3),
                                        const Icon(
                                          Icons.close_rounded,
                                          size: 9,
                                          color: Color(0xFFD97706),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            if (item.notes != null && item.notes!.isNotEmpty)
                              Text(
                                item.notes!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: POSColors.textTertiary,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (modifierSummary.isNotEmpty)
                              Text(
                                modifierSummary,
                                style: const TextStyle(fontSize: 10, color: POSColors.textTertiary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (item.discount != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.grossAmount.pesoFormatted,
                          style: const TextStyle(
                            fontSize: 11,
                            color: POSColors.textTertiary,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: POSColors.textTertiary,
                          ),
                        ),
                        Text(
                          item.totalAmount.pesoFormatted,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ColorSet.primary,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      item.grossAmount.pesoFormatted,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ColorSet.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // â”€â”€ Expanded controls â”€â”€
          if (isExpanded) ...[
            const Divider(height: 1, thickness: 1, color: POSColors.borderSubtle),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Qty',
                        style: TextStyle(
                          fontSize: 11,
                          color: POSColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (item.discount != null)
                        Opacity(
                          opacity: 0.4,
                          child: AbsorbPointer(
                            child: _QuantityStepper(
                              quantity: item.quantity,
                              onDecrease: () {},
                              onIncrease: () {},
                            ),
                          ),
                        )
                      else
                        _QuantityStepper(
                          quantity: item.quantity,
                          onDecrease: () => onQuantityChanged(item.quantity - 1),
                          onIncrease: () => onQuantityChanged(item.quantity + 1),
                        ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(POSRadius.full),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'ORDER TYPE',
                    style: TextStyle(
                      fontSize: 9,
                      color: POSColors.textTertiary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _SaleTypePill(selected: item.itemSaleType, onChanged: onSaleTypeChanged),
                  const SizedBox(height: 10),
                  const Text(
                    'NOTES',
                    style: TextStyle(
                      fontSize: 9,
                      color: POSColors.textTertiary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: notesController,
                    focusNode: notesFocus,
                    onSubmitted: onNotesChanged,
                    readOnly: KeyboardSuppress.readOnly(hasPhysicalKeyboard),
                    showCursor: KeyboardSuppress.showCursor(hasPhysicalKeyboard),
                    keyboardType: KeyboardSuppress.type(null, hasPhysicalKeyboard),
                    contextMenuBuilder: KeyboardSuppress.contextMenuBuilder(hasPhysicalKeyboard),
                    onTap: KeyboardSuppress.onTap,
                    onTapOutside: (_) {
                      notesFocus.unfocus();
                      OnScreenKeyboard.hide();
                      WindowsTouchKeyboard.dismiss();
                    },
                    style: const TextStyle(fontSize: 12, color: POSColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. no onions, extra rice...',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: POSColors.textDisabled,
                        fontStyle: FontStyle.italic,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(POSRadius.sm),
                        borderSide: const BorderSide(color: POSColors.borderDefault),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(POSRadius.sm),
                        borderSide: const BorderSide(color: POSColors.borderDefault),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(POSRadius.sm),
                        borderSide: const BorderSide(color: ColorSet.primary, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SaleTypeBadge extends StatelessWidget {
  const _SaleTypeBadge({required this.saleType});

  final SaleType saleType;

  @override
  Widget build(BuildContext context) {
    final isDineIn = saleType == SaleType.dineIn;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: isDineIn ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        saleType.displayName,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: isDineIn ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
        ),
      ),
    );
  }
}
