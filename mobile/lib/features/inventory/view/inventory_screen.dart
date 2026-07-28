import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../entities/inventory_product.dart';
import '../state/inventory_notifier.dart';
import 'categories_tab.dart';
import 'product_form_dialog.dart';

class InventoryScreen extends HookConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.invalidate(inventoryNotifierProvider));
      return null;
    }, const []);

    final tabController = useTabController(initialLength: 2);
    final currentTab = useState(0);
    useEffect(() {
      void listener() => currentTab.value = tabController.index;
      tabController.addListener(listener);
      return () => tabController.removeListener(listener);
    }, [tabController]);

    final authState = ref.watch(authNotifierProvider);
    final isAdmin =
        authState is AuthAuthenticated && authState.user.isAdminOrSupervisor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Inventory Management'),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: 'Categories'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(inventoryNotifierProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: TabBarView(
        controller: tabController,
        children: const [
          _ProductsTab(),
          CategoriesTab(),
        ],
      ),
      floatingActionButton: currentTab.value == 0 && isAdmin
          ? const _ProductsTabFab()
          : null,
    );
  }
}

class _ProductsTabFab extends ConsumerWidget {
  const _ProductsTabFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryNotifierProvider);
    return state.maybeWhen(
      data: (s) => FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => ProductFormDialog(
            groupId: s.selectedGroupId ?? (s.groups.isNotEmpty ? s.groups.first.id : null),
          ),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product'),
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _ProductsTab extends HookConsumerWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryNotifierProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorStateWidget(
        message: e.toString(),
        onRetry: () => ref.read(inventoryNotifierProvider.notifier).refresh(),
      ),
      data: (s) => _InventoryBody(state: s),
    );
  }
}

class _InventoryBody extends HookConsumerWidget {
  final InventoryState state;
  const _InventoryBody({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    if (state.products.isEmpty && state.groups.isEmpty) {
      return EmptyStateWidget(
        title: 'No products yet',
        subtitle: 'Import a products CSV in Settings to get started.',
        icon: Icons.inventory_2_outlined,
      );
    }

    final filtered = state.filtered;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textDisabled),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              ),
              style: AppTextStyles.bodyLg,
              onChanged: (v) {
                ref.read(inventoryNotifierProvider.notifier).setSearch(v);
              },
            ),
          ),
        ),
        if (state.groups.isNotEmpty) ...[
          const Gap(AppSpacing.sm),
          _CategoryChips(
            groups: state.groups,
            selectedGroupId: state.selectedGroupId,
            onSelect: (id) => ref.read(inventoryNotifierProvider.notifier).selectGroup(id),
          ),
        ],
        const Gap(AppSpacing.md),
        Expanded(
          child: filtered.isEmpty
              ? EmptyStateWidget(
                  title: 'No products found',
                  subtitle: 'Try a different search or category',
                  icon: Icons.search_off_rounded,
                )
              : _ProductsGrid(products: filtered),
        ),
      ],
    );
  }
}

// ── Category chips ──────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  final List<InventoryGroup> groups;
  final int? selectedGroupId;
  final ValueChanged<int?> onSelect;

  const _CategoryChips({
    required this.groups,
    required this.selectedGroupId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: groups.length + 1,
        separatorBuilder: (context, index) => const Gap(AppSpacing.sm),
        itemBuilder: (_, i) {
          if (i == 0) {
            return _Chip(
              label: 'All',
              isSelected: selectedGroupId == null,
              onTap: () => onSelect(null),
            );
          }
          final g = groups[i - 1];
          return _Chip(
            label: '${g.name} (${g.productCount})',
            isSelected: selectedGroupId == g.id,
            onTap: () => onSelect(g.id),
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

  const _Chip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? []
              : [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.06), blurRadius: 4)],
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelMd.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Products grid ────────────────────────────────────────────────────────

class _ProductsGrid extends StatelessWidget {
  final List<InventoryProduct> products;
  const _ProductsGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 720 ? 3 : 2;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: 0.62,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemCount: products.length,
          itemBuilder: (_, i) => RepaintBoundary(child: _ProductCard(product: products[i])),
        );
      },
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final InventoryProduct product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isAdmin =
        authState is AuthAuthenticated && authState.user.isAdminOrSupervisor;

    return Opacity(
      opacity: product.isAvailable ? 1.0 : 0.55,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image ──────────────────────────────────────────────
              Expanded(
                flex: 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ProductImage(imageUrl: product.imageUrl, groupName: product.group?.name),
                    if (product.group != null)
                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: _Badge(product.group!.name, AppColors.shadow.withValues(alpha: 0.55)),
                      ),
                    if (!product.isAvailable)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: _Badge('Disabled', AppColors.error),
                      ),
                  ],
                ),
              ),
              // ── Info ───────────────────────────────────────────────
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: AppTextStyles.labelLg.copyWith(
                            fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(2),
                      Text(
                        'PHP ${product.price.toStringAsFixed(2)}',
                        style: AppTextStyles.priceMd.copyWith(color: AppColors.primary),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          if (isAdmin)
                            Expanded(
                              child: FilledButton(
                                onPressed: () => ref
                                    .read(inventoryNotifierProvider.notifier)
                                    .toggleAvailability(product),
                                style: FilledButton.styleFrom(
                                  backgroundColor: product.isAvailable
                                      ? AppColors.error.withValues(alpha: 0.12)
                                      : AppColors.success.withValues(alpha: 0.12),
                                  foregroundColor:
                                      product.isAvailable ? AppColors.error : AppColors.success,
                                  minimumSize: const Size(0, 32),
                                  padding: EdgeInsets.zero,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      product.isAvailable
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      size: 14,
                                    ),
                                    const Gap(4),
                                    Text(
                                      product.isAvailable ? 'Disable' : 'Enable',
                                      style: AppTextStyles.labelMd,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            const Spacer(),
                          if (isAdmin) ...[
                            const Gap(4),
                            _CardIconButton(
                              icon: Icons.edit_outlined,
                              color: AppColors.primary,
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => ProductFormDialog(
                                  existing: product,
                                  groupId: product.groupId,
                                ),
                              ),
                            ),
                          ],
                          // Modifier group management is being reworked; disable
                          // navigation to the per-product modifiers screen for now.
                          // const Gap(4),
                          // _CardIconButton(
                          //   icon: Icons.tune_rounded,
                          //   color: AppColors.secondary,
                          //   onPressed: () =>
                          //       context.push('/inventory/products/${product.id}/modifiers'),
                          // ),
                        ],
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

class _CardIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _CardIconButton({required this.icon, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: color),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? imageUrl;
  final String? groupName;
  const _ProductImage({this.imageUrl, this.groupName});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, e, st) => _Placeholder(groupName: groupName),
      );
    }
    return _Placeholder(groupName: groupName);
  }
}

class _Placeholder extends StatelessWidget {
  final String? groupName;
  const _Placeholder({this.groupName});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(Icons.fastfood_rounded, size: 36, color: AppColors.primary.withValues(alpha: 0.4)),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}
