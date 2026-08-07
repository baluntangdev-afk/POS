import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/providers/database_provider.dart';
import '../../../core/services/image_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../core/widgets/gradient_filled_button.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../../settings/state/store_info_notifier.dart';
import '../entities/line_item.dart';
import '../entities/sale.dart';
import '../state/ordering_notifier.dart';
import 'modifier_dialog.dart';

class OrderingScreen extends HookConsumerWidget {
  const OrderingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(() => ref.read(orderingProvider.notifier).refresh());
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
          title: const Text('New Order'),
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: () {
              context.go('/dashboard');
            },
            icon: Icon(Icons.arrow_back),
          ),
          actions: [
            _StoreHeader(),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (Breakpoints.isTablet(constraints.maxWidth)) {
              return const _TabletLayout();
            }
            return const _PhoneLayout();
          },
        ),
      ),
    );
  }
}

// ── Tablet: side-by-side product grid + cart panel ────────────────────────────

class _TabletLayout extends StatelessWidget {
  const _TabletLayout();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _ProductSection()),
        SizedBox(width: 320, child: _CartPanel()),
      ],
    );
  }
}

// ── Phone: full-width product grid + floating cart bar ─────────────────────────

class _PhoneLayout extends HookConsumerWidget {
  const _PhoneLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(
      orderingProvider.select((s) => s.value?.sale.totalQuantity ?? 0),
    );
    final cartTotal = ref.watch(
      orderingProvider.select((s) => s.value?.sale.total ?? 0),
    );

    return Stack(
      children: [
        const _ProductSection(),
        if (cartCount > 0)
          Positioned(
            bottom: AppSpacing.md,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: _CartBar(
              itemCount: cartCount,
              total: cartTotal,
              onTap: () => _showCartBottomSheet(context),
            ),
          ),
      ],
    );
  }

  void _showCartBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder:
          (ctx) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder:
                (_, controller) => const _CartPanel(scrollController: null),
          ),
    );
  }
}

// ── Product section (chips + grid) ────────────────────────────────────────────

class _ProductSection extends StatelessWidget {
  const _ProductSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CategoryChipRow(),
        Expanded(child: _ProductGrid()),
      ],
    );
  }
}

// ── Store branding header ───────────────────────────────────────────────────────

class _StoreHeader extends ConsumerWidget {
  const _StoreHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeName = ref.watch(
      storeInfoProvider.select((s) => s.value?.storeName),
    );
    final authState = ref.watch(authNotifierProvider);
    final cashierName =
        authState is AuthAuthenticated ? authState.user.name : null;
    final displayName = storeName?.isNotEmpty == true ? storeName! : 'New Order';

    // AppBar lays out `actions` with unbounded width, so an `Expanded` here
    // would throw ("incoming width constraints are unbounded"). Bound the
    // widget ourselves and use `Flexible` for the text column instead.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                _initialsOf(displayName),
                style: AppTextStyles.labelMd.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Gap(AppSpacing.sm),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: AppTextStyles.headingSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (cashierName != null && cashierName.isNotEmpty)
                    Text(
                      'Cashier: $cashierName',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initialsOf(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

// ── Category chips ─────────────────────────────────────────────────────────────

class _CategoryChipRow extends ConsumerWidget {
  const _CategoryChipRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(
      orderingProvider.select((s) => s.value?.groups ?? const []),
    );
    final selectedId = ref.watch(
      orderingProvider.select((s) => s.value?.selectedGroupId),
    );

    if (groups.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 52,
      color: AppColors.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        itemCount: groups.length + 1,
        separatorBuilder: (ctx, i2) => const Gap(AppSpacing.sm),
        itemBuilder: (_, i) {
          if (i == 0) {
            return _Chip(
              label: 'All',
              isSelected: selectedId == null,
              onTap:
                  () => ref.read(orderingProvider.notifier).selectGroup(null),
            );
          }
          final g = groups[i - 1];
          return _Chip(
            label: g.name,
            isSelected: selectedId == g.id,
            onTap: () => ref.read(orderingProvider.notifier).selectGroup(g.id),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Product grid ──────────────────────────────────────────────────────────────

class _ProductGrid extends ConsumerWidget {
  const _ProductGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Selects only the catalog fields (not `sale`), and `copyWith` reuses
    // the same `allProducts`/`groups` list instances across cart-only
    // updates — so this stays unchanged, and the grid doesn't rebuild,
    // while the cart is edited (add item, qty +/-, notes, sale type, etc).
    final state = ref.watch(
      orderingProvider.select(
        (s) => s.whenData(
          (d) => (
            allProducts: d.allProducts,
            groups: d.groups,
            selectedGroupId: d.selectedGroupId,
          ),
        ),
      ),
    );

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.error,
                ),
                const Gap(AppSpacing.md),
                Text(
                  'Failed to load products',
                  style: AppTextStyles.headingSm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Gap(AppSpacing.sm),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(orderingProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
      data: (catalog) {
        final products = catalog.allProducts.where((p) {
          if (!p.isAvailable) return false;
          if (catalog.selectedGroupId != null &&
              p.groupId != catalog.selectedGroupId) {
            return false;
          }
          return true;
        }).toList();
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.restaurant_menu_rounded,
                  size: 48,
                  color: AppColors.textDisabled,
                ),
                const Gap(AppSpacing.md),
                Text(
                  'No products available',
                  style: AppTextStyles.headingSm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final groupById = {for (final g in catalog.groups) g.id: g.name};

        return LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 600 ? 3 : 2;
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                100,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                childAspectRatio: 0.72,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemCount: products.length,
              itemBuilder:
                  (_, i) => RepaintBoundary(
                    child: _ProductCard(
                      product: products[i],
                      groupName: groupById[products[i].groupId] ?? '',
                    ),
                  ),
            );
          },
        );
      },
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final OrderProduct product;
  final String groupName;

  const _ProductCard({required this.product, required this.groupName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          onTap: () async {
            final db = ref.read(databaseProvider);
            final item = await showModifierDialog(
              context,
              product: product,
              groupName: groupName,
              db: db,
            );
            if (item != null) {
              ref.read(orderingProvider.notifier).addItem(item);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusXl),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ProductImage(imageUrl: product.imageUrl),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTextStyles.labelLg.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(2),
                    Text(
                      'PHP ${product.price.toStringAsFixed(2)}',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
  final String? imageUrl;

  const _ProductImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      Widget errorBuilder(BuildContext ctx, Object err, StackTrace? st) => _Placeholder();
      return ImageStorageService.isNetworkUrl(url)
          ? Image.network(url, fit: BoxFit.cover, errorBuilder: errorBuilder)
          : Image.file(File(url), fit: BoxFit.cover, errorBuilder: errorBuilder);
    }
    return _Placeholder();
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Icons.fastfood_rounded,
          size: 36,
          color: AppColors.primary.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

// ── Cart bar (phone only) ─────────────────────────────────────────────────────

class _CartBar extends StatelessWidget {
  final int itemCount;
  final double total;
  final VoidCallback onTap;

  const _CartBar({
    required this.itemCount,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                '$itemCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const Gap(AppSpacing.sm),
            Flexible(
              child: Text(
                'View Cart',
                style: AppTextStyles.bodyMd.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                'PHP ${total.toStringAsFixed(2)}',
                style: AppTextStyles.headingSm.copyWith(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const Gap(AppSpacing.sm),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cart panel (tablet side + phone bottom sheet) ─────────────────────────────

class _CartPanel extends HookConsumerWidget {
  final ScrollController? scrollController;

  const _CartPanel({this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderingProvider.select((s) => s.value));

    final items = state?.sale.items ?? const [];

    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Panel header
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const Gap(AppSpacing.sm),
                    Text('Current Order', style: AppTextStyles.headingSm),
                    const Spacer(),
                    if (items.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull,
                          ),
                        ),
                        child: Text(
                          '${state!.sale.totalQuantity}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (items.isNotEmpty) ...[
                      const Gap(AppSpacing.sm),
                      TextButton(
                        onPressed: () {
                          ref.read(orderingProvider.notifier).clearCart();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text('Clear'),
                      ),
                    ],
                  ],
                ),
                if (state != null) ...[
                  const Gap(AppSpacing.sm),
                  _SaleTypeSelector(
                    selected: state.sale.type,
                    onChanged:
                        (t) =>
                            ref.read(orderingProvider.notifier).setSaleType(t),
                  ),
                ],
              ],
            ),
          ),

          // Items + footer (scroll together so the footer never overflows
          // when the panel is short, e.g. a phone bottom sheet in landscape)
          Expanded(
            child:
                items.isEmpty
                    ? const _EmptyCartState()
                    : SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final item in items) ...[
                            _CartItemRow(key: ValueKey(item.id), item: item),
                            const Gap(AppSpacing.sm),
                          ],
                          _CartFooter(sale: state!.sale),
                        ],
                      ),
                    ),
          ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 28,
              color: AppColors.textDisabled,
            ),
          ),
          const Gap(AppSpacing.md),
          Text(
            'Cart is empty',
            style: AppTextStyles.headingSm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Gap(4),
          Text(
            'Tap a product to add',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}

// ── Cart item row (expandable) ────────────────────────────────────────────────

class _CartItemRow extends HookConsumerWidget {
  final LineItem item;

  const _CartItemRow({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = useState(false);
    final notifier = ref.read(orderingProvider.notifier);
    final notesController = useTextEditingController(text: item.notes ?? '');
    final notesFocus = useFocusNode();

    useEffect(() {
      void onFocusLost() {
        if (!notesFocus.hasFocus) {
          notifier.updateNotes(item.id, notesController.text);
        }
      }

      notesFocus.addListener(onFocusLost);
      return () => notesFocus.removeListener(onFocusLost);
    }, const []);

    final modSummary = item.modifiers
        .expand((g) => g.selected.map((o) => o.name))
        .join(', ');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color:
            expanded.value
                ? AppColors.primary.withValues(alpha: 0.05)
                : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: expanded.value ? AppColors.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsed header row
          InkWell(
            onTap: () => expanded.value = !expanded.value,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.variantName.isEmpty
                              ? item.productName
                              : '${item.productName} (${item.variantName})',
                          style: AppTextStyles.labelLg.copyWith(
                            fontWeight: FontWeight.w700,
                            color:
                                expanded.value
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(2),
                        Wrap(
                          spacing: 4,
                          children: [
                            Text(
                              'x${item.quantity}',
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (modSummary.isNotEmpty)
                              Text(
                                modSummary,
                                style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.textDisabled,
                                ),
                              ),
                            if (item.discount != null) const _DiscountBadge(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Gap(AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (item.discount != null) ...[
                        Text(
                          'PHP ${item.lineSubtotal.toStringAsFixed(2)}',
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.textDisabled,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                      Text(
                        'PHP ${item.lineTotal.toStringAsFixed(2)}',
                        style: AppTextStyles.labelLg.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded controls
          if (expanded.value) ...[
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm + 2,
                AppSpacing.sm,
                AppSpacing.sm + 2,
                AppSpacing.sm + 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Qty',
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Gap(AppSpacing.sm),
                      _MiniStepper(
                        quantity: item.quantity,
                        onDecrease:
                            () => notifier.updateQuantity(
                              item.id,
                              item.quantity - 1,
                            ),
                        onIncrease:
                            () => notifier.updateQuantity(
                              item.id,
                              item.quantity + 1,
                            ),
                        locked: item.discount != null,
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => notifier.removeItem(item.id),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull,
                            ),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(AppSpacing.sm),
                  Text(
                    'NOTES',
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.textDisabled,
                      letterSpacing: 0.8,
                      fontSize: 10,
                    ),
                  ),
                  const Gap(4),
                  TextField(
                    controller: notesController,
                    focusNode: notesFocus,
                    onSubmitted: (v) => notifier.updateNotes(item.id, v),
                    style: AppTextStyles.bodySm,
                    decoration: InputDecoration(
                      hintText: 'e.g. no onions…',
                      hintStyle: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textDisabled,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs + 2,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  if (item.discount != null) ...[
                    Text(
                      'Discount: PHP ${item.discountAmount.toStringAsFixed(2)}',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm - 4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_offer_rounded,
            size: 9,
            color: AppColors.warning,
          ),
          const Gap(2),
          Text(
            'Disc.',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.warning,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final bool locked;

  const _MiniStepper({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.4 : 1.0,
      child: AbsorbPointer(
        absorbing: locked,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MiniBtn(
                icon: Icons.remove_rounded,
                onTap: quantity > 1 ? onDecrease : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  '$quantity',
                  style: AppTextStyles.labelLg.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _MiniBtn(
                icon: Icons.add_rounded,
                filled: true,
                onTap: onIncrease,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  const _MiniBtn({required this.icon, this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color:
              filled
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color:
              filled
                  ? Colors.white
                  : (onTap != null
                      ? AppColors.primary
                      : AppColors.textDisabled),
        ),
      ),
    );
  }
}

// ── Cart footer ───────────────────────────────────────────────────────────────

class _CartFooter extends ConsumerWidget {
  final Sale sale;

  const _CartFooter({required this.sale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
        color: AppColors.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Totals
          _TotalRow('Subtotal', sale.subtotal, secondary: true),
          if (sale.totalDiscount > 0)
            _TotalRow('Discount', -sale.totalDiscount, secondary: true),
          const Gap(AppSpacing.xs),
          _TotalRow('Total', sale.total, large: true),
          const Gap(AppSpacing.sm),
          // Order discount
          OutlinedButton.icon(
            onPressed: () => context.push('/order/discount'),
            icon: const Icon(Icons.local_offer_outlined, size: 16),
            label: Text(
              sale.totalDiscount > 0
                  ? 'Discount: PHP ${sale.totalDiscount.toStringAsFixed(2)}'
                  : 'Apply Order Discount',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
          const Gap(AppSpacing.sm),
          // Checkout button
          GradientFilledButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              context.push('/order/payment');
            },
            minHeight: AppSpacing.touchPreferred,
            borderRadius: AppSpacing.radiusLg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Proceed to Payment',
                  style: AppTextStyles.headingSm.copyWith(color: Colors.white),
                ),
                const Gap(AppSpacing.sm),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sale type selector ─────────────────────────────────────────────────────────

class _SaleTypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _SaleTypeSelector({required this.selected, required this.onChanged});

  static const _types = [
    ('dine_in', 'Dine In', Icons.restaurant_rounded),
    ('take_out', 'Take Out', Icons.takeout_dining_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children:
          _types.map((t) {
            final (key, label, icon) = t;
            final isSel = selected == key;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primary : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: isSel ? AppColors.primary : AppColors.border,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: isSel ? Colors.white : AppColors.textSecondary,
                      ),
                      const Gap(2),
                      Text(
                        label,
                        style: AppTextStyles.labelMd.copyWith(
                          fontSize: 11,
                          color: isSel ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool secondary;
  final bool large;

  const _TotalRow(
    this.label,
    this.amount, {
    this.secondary = false,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style:
                  large
                      ? AppTextStyles.headingSm
                      : AppTextStyles.bodyMd.copyWith(
                        color: AppColors.textSecondary,
                      ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Gap(AppSpacing.sm),
          Text(
            amount < 0
                ? '-PHP ${(-amount).toStringAsFixed(2)}'
                : 'PHP ${amount.toStringAsFixed(2)}',
            style:
                large
                    ? AppTextStyles.priceMd.copyWith(color: AppColors.primary)
                    : AppTextStyles.bodyMd.copyWith(
                      color:
                          secondary
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
          ),
        ],
      ),
    );
  }
}
