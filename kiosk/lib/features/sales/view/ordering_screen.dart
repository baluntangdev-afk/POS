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
import '../../../widgets/windows_scaffold.dart';
import '../entities/product.dart';
import '../state/ordering_notifier.dart';
import 'line_item_dialog.dart';

class OrderingScreen extends ConsumerWidget {
  const OrderingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WindowsScaffold(
      backgroundColor: ColorSet.background,
      body: ResponsiveBuilder(
        kiosk: (context) {
          final isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait;
          if (isPortrait) {
            return const _PortraitLayout();
          } else {
            return const _LandscapeLayout();
          }
        },
        tablet: (context) => const _LandscapeLayout(),
        phone: (context) => const _LandscapeLayout(),
      ),
      floatingActionButton: const _CartButton(),
      floatingActionButtonLocation: _CartButtonLocation(),
    );
  }
}

class _LandscapeLayout extends StatelessWidget {
  const _LandscapeLayout();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorSet.secondary.withValues(alpha: 0.85),
                ColorSet.primary.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Container(
                height: context.responsive.value(kiosk: 120, tablet: 90, phone: 70),
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: ColorSet.light,
                        size: context.responsive.value(kiosk: 48, tablet: 36, phone: 24),
                      ),
                    ),
                    const Spacer(),
                    Assets.images.svg.icAdtoKart.svg(
                      height: context.responsive.value(kiosk: 80, tablet: 60, phone: 40),
                      colorFilter: const ColorFilter.mode(ColorSet.light, BlendMode.srcIn),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              Container(
                height: context.responsive.value(kiosk: 180, tablet: 140, phone: 100),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: ColorSet.text.withValues(alpha: 0.1))),
                ),
                child: const _CategoriesList(scrollDirection: Axis.horizontal),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
            vertical: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
          ),
          child: Text(
            'Menu',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 48, tablet: 36, phone: 24),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const Expanded(child: _ProductGrid()),
      ],
    );
  }
}

class _PortraitLayout extends StatelessWidget {
  const _PortraitLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: context.responsive.value(kiosk: 240, tablet: 180, phone: 140),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorSet.secondary.withValues(alpha: 0.85),
                ColorSet.primary.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: ColorSet.light,
                        size: context.responsive.value(kiosk: 48, tablet: 36, phone: 24),
                      ),
                    ),
                  ],
                ),
              ),
              Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
              Assets.images.svg.icAdtoKart.svg(
                width: context.responsive.value(kiosk: 48, tablet: 36, phone: 24),
                colorFilter: const ColorFilter.mode(ColorSet.light, BlendMode.srcIn),
              ),
              Gap(context.responsive.value(kiosk: 64, tablet: 48, phone: 32)),
              const Expanded(child: _CategoriesList(scrollDirection: Axis.vertical)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.all(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
                child: Text(
                  'Menu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 48, tablet: 36, phone: 24),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
              const Expanded(child: _ProductGrid()),
            ],
          ),
        ),
      ],
    );
  }
}

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
        return GestureDetector(
          onTap: () {
            ref.read(orderingProvider.notifier).selectGroup(group);
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            width:
                scrollDirection == Axis.horizontal
                    ? context.responsive.value(kiosk: 180, tablet: 140, phone: 100)
                    : null,
            padding: EdgeInsets.symmetric(
              horizontal: context.responsive.value(kiosk: 24, tablet: 16, phone: 12),
              vertical: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
            ),
            decoration: BoxDecoration(
              color: isSelected ? ColorSet.light.withValues(alpha: 0.2) : null,
              border:
                  scrollDirection == Axis.vertical
                      ? Border(bottom: BorderSide(color: ColorSet.light.withValues(alpha: 0.4)))
                      : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (scrollDirection == Axis.vertical) ...[
                  Image.memory(
                    group.image,
                    height: context.responsive.value(kiosk: 64, tablet: 48, phone: 32),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => SizedBox(
                      height: context.responsive.value(kiosk: 64, tablet: 48, phone: 32),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: ColorSet.light.withValues(alpha: 0.5),
                        size: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
                      ),
                    ),
                  ),
                  Gap(context.responsive.value(kiosk: 8, tablet: 6, phone: 4)),
                ],
                if (scrollDirection == Axis.horizontal) ...[
                  Expanded(
                    child: Image.memory(
                      group.image,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.image_not_supported_outlined,
                        color: ColorSet.light.withValues(alpha: 0.5),
                        size: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
                      ),
                    ),
                  ),
                  Gap(context.responsive.value(kiosk: 8, tablet: 6, phone: 4)),
                ],
                Text(
                  group.name,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 24, tablet: 18, phone: 14),
                    color: ColorSet.light,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

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
    return GridView.builder(
      padding: EdgeInsets.only(
        top: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
        left: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
        right: context.responsive.value(kiosk: 32, tablet: 24, phone: 16),
        bottom: context.responsive.value(kiosk: 128, tablet: 96, phone: 64),
      ),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: context.responsive.value(kiosk: 200, tablet: 150, phone: 120),
        mainAxisExtent: context.responsive.value(kiosk: 280, tablet: 210, phone: 180),
        crossAxisSpacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
        mainAxisSpacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return GestureDetector(
          onTap: () async {
            final lineItem = await showLineItemDialog(context, productId: product.id);
            if (lineItem == null || !context.mounted) return;
            ref.read(orderingProvider.notifier).addLineItem(lineItem);
          },
          behavior: HitTestBehavior.opaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: context.responsive.value(kiosk: 200, tablet: 150, phone: 120),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.all(
                            context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
                          ),
                          child: Image.memory(
                            product.image,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey.shade400,
                              size: context.responsive.value(kiosk: 48, tablet: 36, phone: 24),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          width: context.responsive.value(kiosk: 40, tablet: 30, phone: 24),
                          height: context.responsive.value(kiosk: 40, tablet: 30, phone: 24),
                          decoration: const BoxDecoration(
                            color: ColorSet.success,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: ColorSet.light,
                            size: context.responsive.value(kiosk: 24, tablet: 18, phone: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Gap(context.responsive.value(kiosk: 8, tablet: 6, phone: 4)),
              Text(
                product.name,
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 24, tablet: 18, phone: 14),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

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
    return GestureDetector(
      onTap: () {
        const CartRoute().push<void>(context);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: context.responsive.value(kiosk: 80, tablet: 56, phone: 48),
        height: context.responsive.value(kiosk: 80, tablet: 56, phone: 48),
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
              width: context.responsive.value(kiosk: 48, tablet: 32, phone: 24),
              height: context.responsive.value(kiosk: 48, tablet: 32, phone: 24),
              colorFilter: const ColorFilter.mode(ColorSet.light, BlendMode.srcIn),
            ),
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                width: context.responsive.value(kiosk: 32, tablet: 24, phone: 20),
                height: context.responsive.value(kiosk: 32, tablet: 24, phone: 20),
                decoration: const BoxDecoration(color: ColorSet.danger, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    lineItemCount > 99 ? '99+' : '$lineItemCount',
                    style: TextStyle(
                      color: ColorSet.light,
                      fontSize: context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartButtonLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Get total width and height of the scaffold
    final Size(width: scaffoldWidth, height: scaffoldHeight) = scaffoldGeometry.scaffoldSize;

    // Get the button dimensions to ensure we calculate from its edge, not its center
    final Size(width: buttonWidth, height: buttonHeight) =
        scaffoldGeometry.floatingActionButtonSize;

    // Subtract the cart button size and custom margins from the total screen size
    final deviceType = Breakpoint.getDeviceTypeFromScreenSize(scaffoldGeometry.scaffoldSize);
    final margin = switch (deviceType) {
      DeviceType.kiosk => 32,
      DeviceType.tablet => 24,
      DeviceType.phone => 16,
    };
    final x = scaffoldWidth - buttonWidth - margin;
    final y = scaffoldHeight - buttonHeight - margin;
    return Offset(x, y);
  }
}
