import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../gen/assets.gen.dart';
import '../../../navigation/router.dart';
import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_builder.dart';
import '../../../styles/responsive/responsive_value.dart';
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
            tablet: (context) => const _TabletLayout(),
            phone: (context) => const _LandscapeLayout(),
          ),
        ),
      );
    }
    return WindowsScaffold(
      backgroundColor: ColorSet.background,
      body: ResponsiveBuilder(
        kiosk: (context) => const _KioskLayout(),
        tablet: (context) => const _TabletLayout(),
        phone: (context) => const _LandscapeLayout(),
      ),
    );
  }
}

// ── Shared white header bar ───────────────────────────────────────────────────
class _OrderingHeader extends StatelessWidget {
  const _OrderingHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.responsive.value(kiosk: 68.0, tablet: 60.0, phone: 52.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8E6E1))),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.value(kiosk: 24.0, tablet: 16.0, phone: 12.0),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () {
              if (context.canPop()) context.pop();
            },
            icon: Icon(
              Icons.arrow_back_ios,
              size: context.responsive.value(kiosk: 18.0, tablet: 15.0, phone: 13.0),
            ),
            label: const Text('Back'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorSet.primary,
              side: const BorderSide(color: ColorSet.primary, width: 2),
              minimumSize: Size(
                context.responsive.value(kiosk: 110.0, tablet: 90.0, phone: 76.0),
                context.responsive.value(kiosk: 52.0, tablet: 44.0, phone: 38.0),
              ),
              textStyle: TextStyle(
                fontSize: context.responsive.value(kiosk: 15.0, tablet: 13.0, phone: 12.0),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const Spacer(),
          Assets.images.svg.icAdtoKart.svg(
            height: context.responsive.value(kiosk: 40.0, tablet: 32.0, phone: 24.0),
            colorFilter: const ColorFilter.mode(ColorSet.primary, BlendMode.srcIn),
          ),
          const Spacer(),
          // Balance the back button so the logo is centered
          SizedBox(
            width: context.responsive.value<double>(kiosk: 110, tablet: 90, phone: 76),
          ),
        ],
      ),
    );
  }
}

// ── Kiosk layout: header + sidebar + product grid + mini-cart ────────────────
class _KioskLayout extends StatelessWidget {
  const _KioskLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _OrderingHeader(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // White sidebar: vertical categories
              Container(
                width: 220,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(right: BorderSide(color: Color(0xFFE8E6E1))),
                ),
                child: const _CategoriesList(scrollDirection: Axis.vertical),
              ),
              // Center: product grid
              const Expanded(child: _ProductGrid()),
              // Right: mini-cart panel
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
          height: context.responsive.value(kiosk: 120.0, tablet: 100.0, phone: 80.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE8E6E1))),
          ),
          child: const _CategoriesList(scrollDirection: Axis.horizontal),
        ),
        const Expanded(child: _ProductGrid()),
        const _CartButton(),
      ],
    );
  }
}

// ── Tablet layout: header + chips + grid + sticky cart bar ───────────────────
class _TabletLayout extends StatelessWidget {
  const _TabletLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _OrderingHeader(),
        Container(
          height: 64,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE8E6E1))),
          ),
          child: const _CategoryChipRow(),
        ),
        const Expanded(child: _ProductGrid()),
        const _StickyCartBar(),
      ],
    );
  }
}

// ── Category chip row for tablet ─────────────────────────────────────────────
class _CategoryChipRow extends ConsumerWidget {
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

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: productGroups.length,
      itemBuilder: (context, index) {
        final group = productGroups[index];
        final isSelected = group == selectedGroup;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(group.name),
            selected: isSelected,
            onSelected: (_) {
              ref.read(orderingProvider.notifier).selectGroup(group);
            },
            selectedColor: ColorSet.primary,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : ColorSet.dark,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
            side: BorderSide(
              color: isSelected ? ColorSet.primary : Colors.grey.shade300,
            ),
            showCheckmark: false,
          ),
        );
      },
    );
  }
}

// ── Sticky cart bottom bar for tablet ────────────────────────────────────────
class _StickyCartBar extends ConsumerWidget {
  const _StickyCartBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      orderingProvider.select((it) => (
        count: it.value?.sale.items.length ?? 0,
        total: it.value?.sale.totalAmount,
      )),
    );

    if (state.count <= 0) return const SizedBox.shrink();

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE8E6E1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${state.count} item${state.count != 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              if (state.total != null)
                Text(
                  state.total!.pesoFormatted,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                gradient: const LinearGradient(
                  colors: ColorSet.gradientBg,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(26),
                child: InkWell(
                  borderRadius: BorderRadius.circular(26),
                  onTap: () => const CartRoute().push<void>(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28),
                    child: Center(
                      child: Text(
                        'View Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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
      orderingProvider.select((it) => (
        lineItemCount: it.value?.sale.items.length ?? 0,
        totalAmount: it.value?.sale.totalAmount,
      )),
    );

    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE8E6E1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Cart',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorSet.dark,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child:
                lineItemCount == 0
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Your cart is empty',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    )
                    : _MiniCartItemList(),
          ),
          if (lineItemCount > 0) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (totalAmount != null)
                    Text(
                      totalAmount.pesoFormatted,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: ColorSet.primary,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: ColorSet.gradientBg,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(32),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(32),
                    onTap: () => const CartRoute().push<void>(context),
                    child: const SizedBox(
                      height: 64,
                      child: Center(
                        child: Text(
                          'View Cart',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
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
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Gap(8),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: ColorSet.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'x${item.quantity}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                item.grossAmount.pesoFormatted,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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

// ── Categories list (vertical or horizontal) ─────────────────────────────────
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
            onTap: () {
              ref.read(orderingProvider.notifier).selectGroup(group);
            },
            child: Container(
            width:
                scrollDirection == Axis.horizontal
                    ? context.responsive.value(kiosk: 160.0, tablet: 130.0, phone: 100.0)
                    : null,
            height:
                scrollDirection == Axis.vertical
                    ? context.responsive.value(kiosk: 72.0, tablet: 64.0, phone: 52.0)
                    : null,
            padding: EdgeInsets.symmetric(
              horizontal: context.responsive.value(kiosk: 16.0, tablet: 12.0, phone: 10.0),
              vertical: context.responsive.value(kiosk: 10.0, tablet: 8.0, phone: 6.0),
            ),
            decoration: BoxDecoration(
              color: isSelected ? ColorSet.primary : Colors.transparent,
              border:
                  scrollDirection == Axis.vertical
                      ? Border(
                        left: BorderSide(
                          color: isSelected ? ColorSet.secondary : Colors.transparent,
                          width: 4,
                        ),
                        bottom: const BorderSide(color: Color(0xFFE8E6E1)),
                      )
                      : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (scrollDirection == Axis.vertical) ...[
                  Image.memory(
                    group.image,
                    height: context.responsive.value(kiosk: 32.0, tablet: 26.0, phone: 20.0),
                    fit: BoxFit.contain,
                    color: isSelected ? Colors.white : null,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                  Gap(context.responsive.value(kiosk: 4.0, tablet: 3.0, phone: 2.0)),
                ],
                if (scrollDirection == Axis.horizontal) ...[
                  Expanded(
                    child: Image.memory(
                      group.image,
                      fit: BoxFit.contain,
                      color: isSelected ? Colors.white : null,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                  Gap(context.responsive.value(kiosk: 6.0, tablet: 4.0, phone: 3.0)),
                ],
                Text(
                  group.name,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 14.0, tablet: 13.0, phone: 12.0),
                    color: isSelected ? Colors.white : const Color(0xFF555555),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            ),  // Container
          ),    // InkWell
        );      // Material
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
      return const Center(child: CircularProgressIndicator());
    }
    final products = switch (state) {
      AsyncData(:final value) => value,
      _ => const IList<Product>.empty(),
    };
    return RepaintBoundary(
      child: GridView.builder(
      padding: EdgeInsets.only(
        top: context.responsive.value(kiosk: 16.0, tablet: 12.0, phone: 8.0),
        left: context.responsive.value(kiosk: 24.0, tablet: 20.0, phone: 12.0),
        right: context.responsive.value(kiosk: 24.0, tablet: 20.0, phone: 12.0),
        bottom: context.responsive.value(kiosk: 24.0, tablet: 80.0, phone: 64.0),
      ),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: context.responsive.value(kiosk: 220.0, tablet: 160.0, phone: 130.0),
        mainAxisExtent: context.responsive.value(kiosk: 260.0, tablet: 210.0, phone: 180.0),
        crossAxisSpacing: context.responsive.value(kiosk: 16.0, tablet: 12.0, phone: 8.0),
        mainAxisSpacing: context.responsive.value(kiosk: 16.0, tablet: 12.0, phone: 8.0),
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              final lineItem = await showLineItemDialog(context, productId: product.id);
              if (lineItem == null || !context.mounted) return;
              ref.read(orderingProvider.notifier).addLineItem(lineItem);
            },
            child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.all(
                            context.responsive.value(kiosk: 16.0, tablet: 12.0, phone: 8.0),
                          ),
                          child: Image.memory(product.image, fit: BoxFit.contain),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          width: context.responsive.value(kiosk: 48.0, tablet: 38.0, phone: 30.0),
                          height: context.responsive.value(kiosk: 48.0, tablet: 38.0, phone: 30.0),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: ColorSet.gradientBg),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: ColorSet.light,
                            size: context.responsive.value(kiosk: 24.0, tablet: 20.0, phone: 16.0),
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
                          fontSize: context.responsive.value(kiosk: 18.0, tablet: 14.0, phone: 12.0),
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        product.price.pesoFormatted,
                        style: TextStyle(
                          fontSize: context.responsive.value(kiosk: 16.0, tablet: 13.0, phone: 11.0),
                          fontWeight: FontWeight.w800,
                          color: ColorSet.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ),    // Container
          ),      // InkWell
        );        // Material
      },
      ),          // GridView.builder
    );            // RepaintBoundary
  }
}

// ── Cart button FAB (landscape/phone layouts) ─────────────────────────────────
class _CartButton extends ConsumerWidget {
  const _CartButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lineItemCount = ref.watch(
      orderingProvider.select((it) => it.value?.sale.items.length ?? 0),
    );
    if (lineItemCount <= 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.all(context.responsive.value(kiosk: 24.0, tablet: 16.0, phone: 12.0)),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => const CartRoute().push<void>(context),
            child: Container(
            width: context.responsive.value(kiosk: 80.0, tablet: 56.0, phone: 48.0),
            height: context.responsive.value(kiosk: 80.0, tablet: 56.0, phone: 48.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorSet.secondary.withValues(alpha: 0.85),
                  ColorSet.primary.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Assets.images.svg.icCart.svg(
                  width: context.responsive.value(kiosk: 40.0, tablet: 28.0, phone: 22.0),
                  height: context.responsive.value(kiosk: 40.0, tablet: 28.0, phone: 22.0),
                  colorFilter: const ColorFilter.mode(ColorSet.light, BlendMode.srcIn),
                ),
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: context.responsive.value(kiosk: 28.0, tablet: 20.0, phone: 16.0),
                    height: context.responsive.value(kiosk: 28.0, tablet: 20.0, phone: 16.0),
                    decoration: const BoxDecoration(
                      color: ColorSet.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        lineItemCount > 99 ? '99+' : '$lineItemCount',
                        style: TextStyle(
                          color: ColorSet.light,
                          fontSize: context.responsive.value(kiosk: 11.0, tablet: 9.0, phone: 8.0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ),    // Container
          ),      // InkWell
        ),        // Material
      ),          // Align
    );            // Padding
  }
}
