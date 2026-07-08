import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_builder.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/button.dart';
import '../../auth/state/login_state_notifier.dart';
import '../data/models/category.dart';
import '../state/catalog_categories_notifier.dart';
import 'category_dialogs.dart';

class CategoriesTab extends ConsumerWidget {
  const CategoriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(catalogCategoriesProvider);
    final auth = ref.watch(loginStateProvider).value;
    final isAdminOrSupervisor = auth?.isAdminOrSupervisor ?? false;

    return Padding(
      padding: EdgeInsets.all(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
      child: state.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: ColorSet.primary,
            strokeWidth: 3,
            strokeCap: StrokeCap.round,
          ),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: context.responsive.value(kiosk: 64.0, tablet: 52.0, phone: 40.0),
                color: POSColors.textDisabled,
              ),
              Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
              Text(
                error.toString(),
                style: TextStyle(
                  fontSize: context.responsive.value(kiosk: 14, tablet: 13, phone: 12),
                  color: POSColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
              Button(
                label: const Text('Retry'),
                leading: const Icon(Icons.refresh_rounded),
                onPressed: () => ref.read(catalogCategoriesProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
        data: (categories) => categories.isEmpty
            ? _EmptyCategoriesState(isAdminOrSupervisor: isAdminOrSupervisor)
            : _CategoriesGrid(
                categories: categories,
                isAdminOrSupervisor: isAdminOrSupervisor,
              ),
      ),
    );
  }
}

class _EmptyCategoriesState extends StatelessWidget {
  const _EmptyCategoriesState({required this.isAdminOrSupervisor});

  final bool isAdminOrSupervisor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_rounded,
            size: context.responsive.value(kiosk: 64.0, tablet: 52.0, phone: 40.0),
            color: POSColors.textDisabled,
          ),
          Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
          Text(
            'No categories found',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 18.0, tablet: 16.0, phone: 14.0),
              fontWeight: FontWeight.w700,
              color: POSColors.textSecondary,
            ),
          ),
          Gap(context.responsive.value(kiosk: 8, tablet: 6, phone: 4)),
          Text(
            'Add categories to organise your catalog',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 14.0, tablet: 13.0, phone: 12.0),
              color: POSColors.textDisabled,
            ),
          ),
          if (isAdminOrSupervisor) ...[
            Gap(context.responsive.value(kiosk: 24, tablet: 20, phone: 16)),
            Button(
              label: const Text('Add Category'),
              leading: const Icon(Icons.add),
              onPressed: () => showSaveCategoryDialog(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoriesGrid extends StatelessWidget {
  const _CategoriesGrid({
    required this.categories,
    required this.isAdminOrSupervisor,
  });

  final List<CatalogCategory> categories;
  final bool isAdminOrSupervisor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${categories.length} ${categories.length == 1 ? 'Category' : 'Categories'}',
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 15.0, tablet: 14.0, phone: 13.0),
                fontWeight: FontWeight.w600,
                color: POSColors.textSecondary,
              ),
            ),
            if (isAdminOrSupervisor)
              Button(
                label: const Text('Add Category'),
                leading: const Icon(Icons.add),
                onPressed: () => showSaveCategoryDialog(context),
              ),
          ],
        ),
        Expanded(
          child: ResponsiveBuilder(
            kiosk: (context) => _CategoryGridView(
              categories: categories,
              crossAxisCount: 4,
              isAdminOrSupervisor: isAdminOrSupervisor,
            ),
            tablet: (context) => _CategoryGridView(
              categories: categories,
              crossAxisCount: 3,
              isAdminOrSupervisor: isAdminOrSupervisor,
            ),
            phone: (context) => _CategoryGridView(
              categories: categories,
              crossAxisCount: 2,
              isAdminOrSupervisor: isAdminOrSupervisor,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryGridView extends StatelessWidget {
  const _CategoryGridView({
    required this.categories,
    required this.crossAxisCount,
    required this.isAdminOrSupervisor,
  });

  final List<CatalogCategory> categories;
  final int crossAxisCount;
  final bool isAdminOrSupervisor;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.4,
        crossAxisSpacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
        mainAxisSpacing: context.responsive.value(kiosk: 16, tablet: 12, phone: 8),
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) => _CategoryCard(
        category: categories[index],
        isAdminOrSupervisor: isAdminOrSupervisor,
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.isAdminOrSupervisor,
  });

  final CatalogCategory category;
  final bool isAdminOrSupervisor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(POSRadius.xl),
        child: InkWell(
          onTap: () {
            // TODO: Navigate to category detail
          },
          child: Padding(
            padding: EdgeInsets.all(context.responsive.value(kiosk: 20, tablet: 16, phone: 12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: context.responsive.value(kiosk: 44.0, tablet: 38.0, phone: 32.0),
                      height: context.responsive.value(kiosk: 44.0, tablet: 38.0, phone: 32.0),
                      decoration: BoxDecoration(
                        color: ColorSet.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(POSRadius.md),
                      ),
                      child: Icon(
                        Icons.category_rounded,
                        color: ColorSet.primary,
                        size: context.responsive.value(kiosk: 22.0, tablet: 20.0, phone: 16.0),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive.value(kiosk: 10, tablet: 8, phone: 6),
                        vertical: context.responsive.value(kiosk: 4, tablet: 3, phone: 2),
                      ),
                      decoration: BoxDecoration(
                        color: category.isActive
                            ? ColorSet.success.withValues(alpha: 0.12)
                            : POSColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(POSRadius.full),
                      ),
                      child: Text(
                        category.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: context.responsive.value(kiosk: 11.0, tablet: 10.0, phone: 9.0),
                          fontWeight: FontWeight.w600,
                          color: category.isActive ? ColorSet.success : POSColors.textTertiary,
                        ),
                      ),
                    ),
                    if (isAdminOrSupervisor) ...[
                      Gap(context.responsive.value(kiosk: 4, tablet: 3, phone: 2)),
                      _ActionMenu(category: category),
                    ],
                  ],
                ),
                const Spacer(),
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: context.responsive.value(kiosk: 15.0, tablet: 14.0, phone: 12.0),
                    fontWeight: FontWeight.w700,
                    color: POSColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (category.description != null && category.description!.isNotEmpty) ...[
                  Gap(context.responsive.value(kiosk: 2, tablet: 2, phone: 1)),
                  Text(
                    category.description!,
                    style: TextStyle(
                      fontSize: context.responsive.value(kiosk: 12.0, tablet: 11.0, phone: 10.0),
                      color: POSColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                Gap(context.responsive.value(kiosk: 8, tablet: 6, phone: 4)),
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_rounded,
                      size: context.responsive.value(kiosk: 12.0, tablet: 11.0, phone: 10.0),
                      color: POSColors.iconSubtle,
                    ),
                    Gap(context.responsive.value(kiosk: 4, tablet: 3, phone: 2)),
                    Text(
                      '${category.productCount} ${category.productCount == 1 ? 'product' : 'products'}',
                      style: TextStyle(
                        fontSize: context.responsive.value(kiosk: 12.0, tablet: 11.0, phone: 10.0),
                        color: POSColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionMenu extends ConsumerWidget {
  const _ActionMenu({required this.category});

  final CatalogCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_CategoryAction>(
      onSelected: (action) async {
        switch (action) {
          case _CategoryAction.edit:
            await showSaveCategoryDialog(context, category: category);
          case _CategoryAction.toggleActive:
            await ref.read(catalogCategoriesProvider.notifier).toggleActive(category);
        }
      },
      icon: Icon(
        Icons.more_vert_rounded,
        size: context.responsive.value(kiosk: 20.0, tablet: 18.0, phone: 16.0),
        color: POSColors.iconSubtle,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(POSRadius.md),
      ),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: _CategoryAction.edit,
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18, color: ColorSet.primary),
              Gap(12),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: _CategoryAction.toggleActive,
          child: Row(
            children: [
              Icon(
                category.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                size: 18,
                color: category.isActive ? ColorSet.danger : ColorSet.success,
              ),
              const Gap(12),
              Text(
                category.isActive ? 'Disable' : 'Enable',
                style: TextStyle(
                  color: category.isActive ? ColorSet.danger : ColorSet.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _CategoryAction { edit, toggleActive }
