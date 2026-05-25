import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_builder.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/button.dart';
import '../../../widgets/top_app_bar.dart';
import '../../../widgets/windows_scaffold.dart';
import '../data/models/category.dart';
import '../state/catalog_categories_notifier.dart';
import 'catalog_grid_screen.dart';
import 'modifier_groups_screen.dart';

class CatalogScreen extends HookConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAndroid = context.breakpoint.isAndroid;

    if (isAndroid) {
      return _AndroidCatalogScreen();
    }

    return _WindowsCatalogScreen();
  }
}

// ── Android: Material TabBar + TabBarView (swipe-enabled) ────────────────────

class _AndroidCatalogScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const tabs = ['Products', 'Modifier Groups', 'Categories'];
    final r = context.responsive;

    return DefaultTabController(
      length: tabs.length,
      child: AndroidScaffold(
        backgroundColor: ColorSet.background,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(
            r.appBarHeight + kTextTabBarHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TopAppBar(title: 'Catalog Management'),
              Material(
                color: Colors.white,
                child: TabBar(
                  labelColor: ColorSet.primary,
                  unselectedLabelColor: POSColors.textTertiary,
                  indicatorColor: ColorSet.primary,
                  indicatorWeight: 3,
                  labelStyle: TextStyle(
                    fontSize: r.value(kiosk: 16.0, tablet: 14.0, phone: 13.0),
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: r.value(kiosk: 16.0, tablet: 14.0, phone: 13.0),
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: tabs.map((t) => Tab(text: t)).toList(),
                ),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CatalogGridScreen(),
            ModifierGroupsScreen(),
            _CategoriesTab(),
          ],
        ),
      ),
    );
  }
}

// ── Windows: custom GestureDetector tab bar + IndexedStack ───────────────────

class _WindowsCatalogScreen extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final selectedTab = useState(0);

    return WindowsScaffold(
      backgroundColor: ColorSet.background,
      body: Column(
        children: [
          const TopAppBar(title: 'Catalog Management'),
          _WindowsTabBar(selectedTab: selectedTab),
          Expanded(
            child: IndexedStack(
              index: selectedTab.value,
              children: const [CatalogGridScreen(), ModifierGroupsScreen(), _CategoriesTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowsTabBar extends StatelessWidget {
  const _WindowsTabBar({required this.selectedTab});

  final ValueNotifier<int> selectedTab;

  @override
  Widget build(BuildContext context) {
    const tabs = ['Products', 'Modifier Groups', 'Categories'];
    final r = context.responsive;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: POSShadow.headerBottom,
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isSelected = selectedTab.value == index;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => selectedTab.value = index,
                child: AnimatedContainer(
                  duration: POSAnimation.fast,
                  padding: EdgeInsets.symmetric(vertical: r.spacingLg),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ColorSet.primary.withValues(alpha: 0.06)
                        : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected ? ColorSet.primary : Colors.transparent,
                        width: r.value(kiosk: 3.0, tablet: 2.5, phone: 2.0),
                      ),
                    ),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: r.value(kiosk: 15.0, tablet: 14.0, phone: 12.0),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? ColorSet.primary : POSColors.textTertiary,
                      letterSpacing: isSelected ? 0.2 : 0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Categories Tab ────────────────────────────────────────────────────────────

class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(catalogCategoriesProvider);

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
            ? _EmptyCategoriesState()
            : _CategoriesGrid(categories: categories),
      ),
    );
  }
}

class _EmptyCategoriesState extends StatelessWidget {
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
        ],
      ),
    );
  }
}

class _CategoriesGrid extends StatelessWidget {
  const _CategoriesGrid({required this.categories});

  final List<CatalogCategory> categories;

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
            Button(
              label: const Text('Add Category'),
              leading: const Icon(Icons.add),
              onPressed: () {
                // TODO: Show add category dialog
              },
            ),
          ],
        ),
        Expanded(
          child: ResponsiveBuilder(
            kiosk: (context) => _CategoryGridView(categories: categories, crossAxisCount: 4),
            tablet: (context) => _CategoryGridView(categories: categories, crossAxisCount: 3),
            phone: (context) => _CategoryGridView(categories: categories, crossAxisCount: 2),
          ),
        ),
      ],
    );
  }
}

class _CategoryGridView extends StatelessWidget {
  const _CategoryGridView({required this.categories, required this.crossAxisCount});

  final List<CatalogCategory> categories;
  final int crossAxisCount;

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
      itemBuilder: (context, index) => _CategoryCard(category: categories[index]),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final CatalogCategory category;

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
