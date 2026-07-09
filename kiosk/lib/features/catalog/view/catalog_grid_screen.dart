import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_builder.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../utils/debounce.dart';
import '../../../widgets/button.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/product_image_placeholder.dart';
import '../../../widgets/resposive_wrap_container.dart';
import '../../../widgets/text_box_form_field.dart';
import '../../auth/state/login_state_notifier.dart';
import '../data/models/category.dart';
import '../data/models/product.dart';
import '../state/catalog_categories_notifier.dart';
import '../state/catalog_products_notifier.dart';
import 'product_dialogs.dart';

class CatalogGridScreen extends HookConsumerWidget {
  const CatalogGridScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryId = useState<String?>(null);
    final searchQuery = useState<String?>(null);
    final isAdminOrSupervisor =
        ref
            .watch(loginStateProvider)
            .value
            ?.isAdminOrSupervisor ?? false;

    ref.listen(catalogProductsProvider, (_, next) {
      if (next case AsyncError(:final error)) {
        showNetworkErrorDialog(context, error: error);
      }
    });

    final isFirstBuild = useRef(true);

    useEffect(() {
      if (isFirstBuild.value) {
        isFirstBuild.value = false;
        return null;
      }
      Future.microtask(() {
        ref
            .read(catalogProductsProvider.notifier)
            .getResults(
            categoryId: categoryId.value, search: searchQuery.value);
      });
      return null;
    }, [categoryId.value, searchQuery.value]);

    return Padding(
      padding: EdgeInsets.all(
          context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
      child: Column(
        spacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
        children: [
          _FilterBar(
            categoryId: categoryId,
            searchQuery: searchQuery,
            isAdminOrSupervisor: isAdminOrSupervisor,
          ),
          _CategoryChips(selectedCategoryId: categoryId),
          Expanded(
              child: _ProductsGrid(isAdminOrSupervisor: isAdminOrSupervisor)),
        ],
      ),
    );
  }
}

// ── Filter bar: search + add button ──────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.categoryId,
    required this.searchQuery,
    required this.isAdminOrSupervisor,
  });

  final ValueNotifier<String?> categoryId;
  final ValueNotifier<String?> searchQuery;
  final bool isAdminOrSupervisor;

  @override
  Widget build(BuildContext context) {
    final isPhone = context.breakpoint.isPhone;

    return Container(
      padding: EdgeInsets.all(
          context.responsive.value(kiosk: 16, tablet: 12, phone: 10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      child: Row(
        spacing: context.responsive.value(kiosk: 12, tablet: 10, phone: 8),
        children: [
          Expanded(
            child: HookBuilder(
              builder: (context) {
                final debounce = useDebounce(const Duration(milliseconds: 350));
                return TextBoxFormField.singleLine(
                  hint: 'Search products...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: context.responsive.value(
                        kiosk: 20, tablet: 18, phone: 16),
                    color: POSColors.iconSubtle,
                  ),
                  style: TextStyle(
                    fontSize: context.responsive.value(
                        kiosk: 14, tablet: 14, phone: 12),
                  ),
                  onChanged: (value) {
                    debounce(() {
                      searchQuery.value = (value?.isEmpty ?? true)
                          ? null
                          : value;
                    });
                  },
                );
              },
            ),
          ),
          if (isAdminOrSupervisor)
            if (isPhone)
              FilledButton(
                onPressed: () => showSaveProductDialog(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.add, size: 20),
              )
            else
              Button(
                label: const Text('Add Product'),
                leading: const Icon(Icons.add),
                onPressed: () => showSaveProductDialog(context),
              ),
        ],
      ),
    );
  }
}

// ── Category filter chips ─────────────────────────────────────────────────────

class _CategoryChips extends HookConsumerWidget {
  const _CategoryChips({required this.selectedCategoryId});

  final ValueNotifier<String?> selectedCategoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(catalogCategoriesProvider);
    final scrollController = useScrollController();
    final canScrollLeft = useState(false);
    final canScrollRight = useState(false);

    useEffect(() {
      void update() {
        if (!scrollController.hasClients) return;
        final pos = scrollController.position;
        canScrollLeft.value = pos.pixels > 0;
        canScrollRight.value = pos.pixels < pos.maxScrollExtent;
      }

      scrollController.addListener(update);
      WidgetsBinding.instance.addPostFrameCallback((_) => update());

      return () => scrollController.removeListener(update);
    }, [scrollController]);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollController.hasClients) return;
        final pos = scrollController.position;
        canScrollLeft.value = pos.pixels > 0;
        canScrollRight.value = pos.pixels < pos.maxScrollExtent;
      });
      return null;
    }, [categoriesState]);

    return categoriesState.maybeWhen(
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();

        final bgColor = Theme
            .of(context)
            .scaffoldBackgroundColor;

        return SizedBox(
          height: context.responsive.value(
              kiosk: 40.0, tablet: 36.0, phone: 32.0),
          child: Stack(
            children: [
              Positioned.fill(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.stylus,
                    },
                  ),
                  child: ListView.separated(
                    controller: scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length + 1,
                    separatorBuilder:
                        (_, __) =>
                        Gap(context.responsive.value(
                            kiosk: 8, tablet: 6, phone: 6)),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _Chip(
                          label: 'All',
                          isSelected: selectedCategoryId.value == null,
                          onTap: () => selectedCategoryId.value = null,
                          context: context,
                        );
                      }
                      final cat = categories[index - 1];
                      return _Chip(
                        label: '${cat.name} (${cat.productCount})',
                        isSelected: selectedCategoryId.value == cat.id,
                        onTap: () => selectedCategoryId.value = cat.id,
                        context: context,
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: canScrollLeft.value ? 1.0 : 0.0,
                  duration: POSAnimation.fast,
                  child: IgnorePointer(
                    ignoring: !canScrollLeft.value,
                    child: _ScrollArrow(
                      direction: _ArrowDirection.left,
                      bgColor: bgColor,
                      onTap:
                          () =>
                          scrollController.animateTo(
                            (scrollController.offset - 160).clamp(
                              0.0,
                              scrollController.position.maxScrollExtent,
                            ),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: canScrollRight.value ? 1.0 : 0.0,
                  duration: POSAnimation.fast,
                  child: IgnorePointer(
                    ignoring: !canScrollRight.value,
                    child: _ScrollArrow(
                      direction: _ArrowDirection.right,
                      bgColor: bgColor,
                      onTap:
                          () =>
                          scrollController.animateTo(
                            (scrollController.offset + 160).clamp(
                              0.0,
                              scrollController.position.maxScrollExtent,
                            ),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.context,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final BuildContext context;

  @override
  Widget build(BuildContext outerContext) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: POSAnimation.fast,
        padding: EdgeInsets.symmetric(
          horizontal: outerContext.responsive.value(
              kiosk: 16, tablet: 14, phone: 12),
        ),
        decoration: BoxDecoration(
          color: isSelected ? ColorSet.primary : Colors.white,
          borderRadius: BorderRadius.circular(POSRadius.full),
          border: Border.all(
            color: isSelected ? ColorSet.primary : POSColors.borderDefault,
            width: 1.5,
          ),
          boxShadow: isSelected ? [] : POSShadow.card,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: outerContext.responsive.value(
                  kiosk: 13.0, tablet: 12.0, phone: 11.0),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : POSColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Scroll arrow indicator ────────────────────────────────────────────────────

enum _ArrowDirection { left, right }

class _ScrollArrow extends StatelessWidget {
  const _ScrollArrow(
      {required this.direction, required this.bgColor, required this.onTap});

  final _ArrowDirection direction;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isLeft = direction == _ArrowDirection.left;
    final circleSize = context.responsive.value(
        kiosk: 30.0, tablet: 26.0, phone: 22.0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: context.responsive.value(kiosk: 64.0, tablet: 52.0, phone: 44.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
            end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
            colors: [
              bgColor.withValues(alpha: 0.0),
              bgColor.withValues(alpha: 0.95)
            ],
            stops: const [0.0, 0.6],
          ),
        ),
        child: Center(
          child: Container(
            width: circleSize,
            height: circleSize,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: POSShadow.card,
            ),
            child: Center(
              child: Icon(
                isLeft ? Icons.chevron_left_rounded : Icons
                    .chevron_right_rounded,
                size: context.responsive.value(
                    kiosk: 18.0, tablet: 16.0, phone: 14.0),
                color: POSColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Products grid ─────────────────────────────────────────────────────────────

class _ProductsGrid extends ConsumerWidget {
  const _ProductsGrid({required this.isAdminOrSupervisor});

  final bool isAdminOrSupervisor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
        catalogProductsProvider.select((it) => it.whenData((d) => d.products)));

    return state.when(
      loading:
          () =>
      const Center(
        child: CircularProgressIndicator(
          color: ColorSet.primary,
          strokeWidth: 3,
          strokeCap: StrokeCap.round,
        ),
      ),
      error: (_, __) => const Center(child: SizedBox.shrink()),
      data: (products) {
        if (products.isEmpty) {
          return _EmptyProductsState();
        }

        return ResponsiveBuilder(
          kiosk: (context) =>
              _Grid(
                products: products,
                crossAxisCount: 4,
                ratio: 0.72,
                isAdminOrSupervisor: isAdminOrSupervisor,
              ),
          tablet: (context) =>
              _Grid(
                products: products,
                crossAxisCount: 3,
                ratio: 0.72,
                isAdminOrSupervisor: isAdminOrSupervisor,
              ),
          phone: (context) =>
              _Grid(
                products: products,
                crossAxisCount: 2,
                ratio: 0.70,
                isAdminOrSupervisor: isAdminOrSupervisor,
              ),
        );
      },
    );
  }
}

class _EmptyProductsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_rounded,
                    size: context.responsive.value(
                        kiosk: 64, tablet: 52, phone: 40),
                    color: POSColors.textDisabled,
                  ),
                  Gap(context.responsive.value(
                      kiosk: 16, tablet: 12, phone: 8)),
                  Text(
                    'No products found',
                    style: TextStyle(
                      fontSize: context.responsive.value(
                          kiosk: 18, tablet: 15, phone: 13),
                      fontWeight: FontWeight.w700,
                      color: POSColors.textSecondary,
                    ),
                  ),
                  Gap(context.responsive.value(kiosk: 6, tablet: 4, phone: 3)),
                  Text(
                    'Try adjusting your search or category filter',
                    style: TextStyle(
                      fontSize: context.responsive.value(
                          kiosk: 13, tablet: 12, phone: 11),
                      color: POSColors.textDisabled,
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

class _Grid extends StatelessWidget {
  const _Grid({
    required this.products,
    required this.crossAxisCount,
    required this.ratio,
    required this.isAdminOrSupervisor,
  });

  final List<CatalogProduct> products;
  final int crossAxisCount;
  final double ratio;
  final bool isAdminOrSupervisor;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: ratio,
        crossAxisSpacing: context.responsive.value(
            kiosk: 16, tablet: 12, phone: 8),
        mainAxisSpacing: context.responsive.value(
            kiosk: 16, tablet: 12, phone: 8),
      ),
      itemCount: products.length,
      itemBuilder: (context, index) =>
          _ProductCard(
            product: products[index],
            isAdminOrSupervisor: isAdminOrSupervisor,
          ),
    );
  }
}

// ── Product card ──────────────────────────────────────────────────────────────

class _ProductCard extends ConsumerWidget {
  const _ProductCard(
      {required this.product, required this.isAdminOrSupervisor});

  final CatalogProduct product;
  final bool isAdminOrSupervisor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = context.responsive;

    return Opacity(
      opacity: product.isAvailable ? 1.0 : 0.6,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(POSRadius.xl),
          boxShadow: POSShadow.card,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(POSRadius.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image area ──────────────────────────────────────────
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ProductImage(imageUrl: product.imageUrl,
                        categoryName: product.category?.name),
                    // Category badge overlay
                    if (product.category != null)
                      Positioned(
                        left: r.value(kiosk: 8, tablet: 7, phone: 6),
                        bottom: r.value(kiosk: 8, tablet: 7, phone: 6),
                        child: _CategoryBadge(name: product.category!.name),
                      ),
                    if (!product.isAvailable)
                      Positioned(
                        right: r.value(kiosk: 8, tablet: 7, phone: 6),
                        top: r.value(kiosk: 8, tablet: 7, phone: 6),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: r.value(kiosk: 8, tablet: 7, phone: 6),
                            vertical: r.value(kiosk: 3, tablet: 3, phone: 2),
                          ),
                          decoration: BoxDecoration(
                            color: ColorSet.danger,
                            borderRadius: BorderRadius.circular(POSRadius.sm),
                          ),
                          child: Text(
                            'Disabled',
                            style: TextStyle(
                              fontSize: r.value(kiosk: 10, tablet: 9, phone: 8),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // ── Info area ────────────────────────────────────────────
              Expanded(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.all(
                      r.value(kiosk: 12, tablet: 10, phone: 8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: r.value(kiosk: 14, tablet: 12, phone: 10),
                          fontWeight: FontWeight.w700,
                          color: POSColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Gap(r.value(kiosk: 2, tablet: 2, phone: 2)),
                      Text(
                        'PHP ${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: r.value(kiosk: 15, tablet: 13, phone: 11),
                          fontWeight: FontWeight.w800,
                          color: ColorSet.primary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (isAdminOrSupervisor) ...[
                        const Spacer(),
                        Gap(r.value(kiosk: 8, tablet: 6, phone: 4)),
                        Row(
                          children: [
                            Expanded(
                              child: Button(
                                label: Text(
                                  'Edit',
                                  style: TextStyle(fontSize: r.value(
                                      kiosk: 12, tablet: 11, phone: 10)),
                                ),
                                onPressed: () =>
                                    showSaveProductDialog(
                                        context, product: product),
                                backgroundColor: ColorSet.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            Gap(r.value(kiosk: 6, tablet: 5, phone: 4)),
                            IconButton(
                              onPressed: () =>
                                  ref
                                      .read(catalogProductsProvider.notifier)
                                      .toggleAvailability(product),
                              icon: Icon(
                                product.isAvailable
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: r.value(kiosk: 20, tablet: 18, phone: 16),
                                color: product.isAvailable
                                    ? ColorSet.danger
                                    : ColorSet.success,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: (product.isAvailable
                                    ? ColorSet.danger
                                    : ColorSet.success)
                                    .withValues(alpha: 0.08),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      POSRadius.md),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl, this.categoryName});

  final String? imageUrl;
  final String? categoryName;

  @override
  Widget build(BuildContext context) {
    final style = productPlaceholder(categoryName);
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, ___) => _ImagePlaceholder(style: style),
      );
    }
    return _ImagePlaceholder(style: style);
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.style});

  final ProductPlaceholderStyle? style;

  @override
  Widget build(BuildContext context) {
    final s = style ?? defaultProductPlaceholder;
    return ColoredBox(
      color: s.bg,
      child: Center(
        child: Icon(
          s.icon,
          size: context.responsive.value(kiosk: 40, tablet: 32, phone: 24),
          color: s.fg,
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.value(kiosk: 8, tablet: 7, phone: 6),
        vertical: context.responsive.value(kiosk: 3, tablet: 3, phone: 2),
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(POSRadius.full),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: context.responsive.value(kiosk: 10, tablet: 9, phone: 8),
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
