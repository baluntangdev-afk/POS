import 'dart:ui';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../gen/assets.gen.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_builder.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/decimal_formatter.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/product.dart';
import '../state/ordering_notifier.dart';
import 'line_item_dialog.dart';

class OrderingScreen extends ConsumerWidget {
  const OrderingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (context.breakpoint.isAndroid) {
      return AndroidScaffold(
        backgroundColor: ColorSet.background,
        body: SafeArea(
          child: ResponsiveBuilder(
            kiosk: (context) => const _KioskLayout(),
            tablet: (context) => const _KioskLayout(),
            phone: (context) => const _KioskLayout(),
          ),
        ),
      );
    }
    return WindowsScaffold(
      backgroundColor: ColorSet.background,
      body: ResponsiveBuilder(
        kiosk: (context) => const _TabletLayout(),
        tablet: (context) => const _TabletLayout(),
        phone: (context) => const _TabletLayout(),
      ),
    );
  }
}

class _OrderingHeader extends StatelessWidget {
  const _OrderingHeader();

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
          Assets.images.svg.icAdtoKart.svg(
            height: r.value(kiosk: 36.0, tablet: 28.0, phone: 22.0),
            colorFilter: const ColorFilter.mode(ColorSet.primary, BlendMode.srcIn),
          ),
          const Spacer(),
          SizedBox(width: r.value<double>(kiosk: 110, tablet: 90, phone: 76)),
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
          if (context.canPop()) context.pop();
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

// ── Kiosk layout: header + sidebar + product grid + mini-cart ─────────────────
class _KioskLayout extends StatelessWidget {
  const _KioskLayout();

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _OrderingHeader(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: r.sidebarWidth,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(right: BorderSide(color: POSColors.borderDefault)),
                ),
                child: const _CategoriesList(scrollDirection: Axis.vertical),
              ),
              const Expanded(child: _ProductGrid()),
              const _MiniCartPanel(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Landscape / phone layout ──────────────────────────────────────────────────
class _LandscapeLayout extends StatelessWidget {
  const _LandscapeLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _OrderingHeader(),
        Container(
          height: context.responsive.value(kiosk: 110.0, tablet: 96.0, phone: 80.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: POSColors.borderDefault)),
          ),
          child: const _CategoriesList(scrollDirection: Axis.horizontal),
        ),
        const Expanded(child: _ProductGrid()),
        const _CartButton(),
      ],
    );
  }
}

// ── Tablet layout ──────────────────────────────────────────────────────────────
class _TabletLayout extends StatelessWidget {
  const _TabletLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _OrderingHeader(),
        Container(
          height: context.responsive.value<double>(kiosk: 64, tablet: 60, phone: 52),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: POSColors.borderDefault)),
          ),
          child: const _CategoryChipRow(),
        ),
        const Expanded(child: _ProductGrid()),
        const _StickyCartBar(),
      ],
    );
  }
}

// ── Category chip row for tablet ──────────────────────────────────────────────
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.sm)),
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
                onTap: () => scrollController.animateTo(
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
                onTap: () => scrollController.animateTo(
                  scrollController.offset + scrollStep,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.decelerate,
                ),
                child: Container(
                  width: arrowWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
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

// ── Sticky cart bottom bar for tablet ────────────────────────────────────────
class _StickyCartBar extends ConsumerWidget {
  const _StickyCartBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      orderingProvider.select(
        (it) => (count: it.value?.sale.items.length ?? 0, total: it.value?.sale.totalAmount),
      ),
    );

    if (state.count <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: POSColors.borderDefault)),
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -4))],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${state.count} item${state.count != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: POSColors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (state.total != null)
                Text(
                  state.total!.pesoFormatted,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ColorSet.primary,
                  ),
                ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 52,
            child: DecoratedBox(
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
                  onTap: () => const CartRoute().push<void>(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'View Cart',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini-cart panel (kiosk right panel) ───────────────────────────────────────
class _MiniCartPanel extends ConsumerWidget {
  const _MiniCartPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:lineItemCount, :totalAmount) = ref.watch(
      orderingProvider.select(
        (it) => (
          lineItemCount: it.value?.sale.items.length ?? 0,
          totalAmount: it.value?.sale.totalAmount,
        ),
      ),
    );

    return Container(
      width: context.responsive.cartPanelWidth,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: POSColors.borderDefault)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: POSColors.borderSubtle)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_outlined, size: 18, color: ColorSet.primary),
                const SizedBox(width: 8),
                const Text(
                  'Cart',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: POSColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (lineItemCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: ColorSet.primary,
                      borderRadius: BorderRadius.circular(POSRadius.full),
                    ),
                    child: Text(
                      '$lineItemCount',
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
          Expanded(child: lineItemCount == 0 ? const _EmptyCartState() : _MiniCartItemList()),
          if (lineItemCount > 0) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: POSColors.borderSubtle)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: POSColors.textSecondary,
                    ),
                  ),
                  if (totalAmount != null)
                    Text(
                      totalAmount.pesoFormatted,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: ColorSet.primary,
                      ),
                    ),
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 12), child: _ViewCartButton()),
          ],
        ],
      ),
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

class _ViewCartButton extends StatelessWidget {
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
          onTap: () => const CartRoute().push<void>(context),
          child: const SizedBox(
            height: 52,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'View Cart',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
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

class _MiniCartItemList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(
      orderingProvider.select((it) => it.value?.sale.items ?? const IList.empty()),
    );
    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Gap(6),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: POSColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(POSRadius.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: POSColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'x${item.quantity}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: POSColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
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
        );
      },
    );
  }
}

// ── Categories list ───────────────────────────────────────────────────────────
class _CategoriesList extends ConsumerWidget {
  const _CategoriesList({required this.scrollDirection});

  final Axis scrollDirection;

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

    return ListView.builder(
      scrollDirection: scrollDirection,
      itemCount: productGroups.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final group = productGroups[index];
        final isSelected = group == selectedGroup;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => ref.read(orderingProvider.notifier).selectGroup(group),
            child: AnimatedContainer(
              duration: POSAnimation.fast,
              width:
                  scrollDirection == Axis.horizontal
                      ? context.responsive.value(kiosk: 150.0, tablet: 120.0, phone: 100.0)
                      : null,
              height:
                  scrollDirection == Axis.vertical
                      ? context.responsive.value(kiosk: 76.0, tablet: 68.0, phone: 58.0)
                      : null,
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive.value(kiosk: 14.0, tablet: 10.0, phone: 8.0),
                vertical: context.responsive.value(kiosk: 8.0, tablet: 6.0, phone: 5.0),
              ),
              decoration: BoxDecoration(
                color: isSelected ? ColorSet.primary.withValues(alpha: 0.08) : Colors.transparent,
                border:
                    scrollDirection == Axis.vertical
                        ? Border(
                          left: BorderSide(
                            color: isSelected ? ColorSet.primary : Colors.transparent,
                            width: 3,
                          ),
                          bottom: const BorderSide(color: POSColors.borderSubtle),
                        )
                        : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (scrollDirection == Axis.vertical) ...[
                    // Image.memory(
                    //   group.image,
                    //   height: context.responsive.value(kiosk: 28.0, tablet: 24.0, phone: 20.0),
                    //   fit: BoxFit.contain,
                    //   color: isSelected ? ColorSet.primary : POSColors.iconSubtle,
                    //   colorBlendMode: BlendMode.srcIn,
                    //   errorBuilder:
                    //       (_, __, ___) => Icon(
                    //         Icons.image_not_supported_outlined,
                    //         size: context.responsive.value(kiosk: 28.0, tablet: 24.0, phone: 20.0),
                    //         color: isSelected ? ColorSet.primary : POSColors.iconSubtle,
                    //       ),
                    // ),
                    Gap(context.responsive.value(kiosk: 4.0, tablet: 3.0, phone: 2.0)),
                  ],
                  if (scrollDirection == Axis.horizontal) ...[
                    // Expanded(
                    //   child: Image.memory(
                    //     group.image,
                    //     fit: BoxFit.contain,
                    //     color: isSelected ? ColorSet.primary : POSColors.iconSubtle,
                    //     colorBlendMode: BlendMode.srcIn,
                    //     errorBuilder:
                    //         (_, __, ___) => Icon(
                    //           Icons.image_not_supported_outlined,
                    //           size: context.responsive.value(
                    //             kiosk: 28.0,
                    //             tablet: 24.0,
                    //             phone: 20.0,
                    //           ),
                    //           color: isSelected ? ColorSet.primary : POSColors.iconSubtle,
                    //         ),
                    //   ),
                    // ),
                    Gap(context.responsive.value(kiosk: 4.0, tablet: 3.0, phone: 2.0)),
                  ],
                  Text(
                    group.name,
                    style: TextStyle(
                      fontSize: context.responsive.value(kiosk: 12.0, tablet: 11.0, phone: 10.0),
                      color: isSelected ? ColorSet.primary : POSColors.textTertiary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
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

// ── Product grid ─────────────────────────────────────────────────────────────
class _ProductGrid extends ConsumerWidget {
  const _ProductGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderingProvider.select((it) => it.whenData((data) => data.products)));
    if (state.isLoading) {
      return const Center(child: _LoadingState());
    }
    final products = switch (state) {
      AsyncData(:final value) => value,
      _ => const IList<Product>.empty(),
    };
    if (products.isEmpty && !state.isLoading) {
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
          return _ProductCard(product: product);
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(POSRadius.xl),
                boxShadow: POSShadow.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(POSRadius.xl),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(
                              context.responsive.value(kiosk: 14.0, tablet: 10.0, phone: 8.0),
                            ),
                            child: Image.memory(
                              product.image,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (_, __, ___) => Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      size: context.responsive.value(
                                        kiosk: 48.0,
                                        tablet: 40.0,
                                        phone: 32.0,
                                      ),
                                      color: POSColors.iconSubtle,
                                    ),
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

// ── Cart button FAB (landscape/phone layouts) ─────────────────────────────────
class _CartButton extends ConsumerWidget {
  const _CartButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:lineItemCount, :total) = ref.watch(
      orderingProvider.select(
        (it) => (
          lineItemCount: it.value?.sale.items.length ?? 0,
          total: it.value?.sale.totalAmount,
        ),
      ),
    );
    if (lineItemCount <= 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(context.responsive.value(kiosk: 16.0, tablet: 12.0, phone: 10.0)),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: POSColors.borderDefault)),
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -4))],
      ),
      child: DecoratedBox(
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
            onTap: () => const CartRoute().push<void>(context),
            child: SizedBox(
              height: context.responsive.value(kiosk: 60.0, tablet: 52.0, phone: 48.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'View Cart ($lineItemCount)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (total != null) ...[
                    const SizedBox(width: 16),
                    Container(width: 1, height: 18, color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(width: 16),
                    Text(
                      total.pesoFormatted,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
