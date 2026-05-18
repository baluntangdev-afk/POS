import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../widgets/windows_scaffold.dart';
import 'catalog_grid_screen.dart';
import 'modifier_groups_screen.dart';

class CatalogScreen extends HookConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = useState(0);

    return WindowsScaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(context.responsive.value(kiosk: 120, tablet: 90, phone: 70)),
        child: const _TopAppBar(),
      ),
      body: Column(
        children: [
          _TabBar(selectedTab: selectedTab),
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

class _TopAppBar extends StatelessWidget {
  const _TopAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.responsive.value(kiosk: 120, tablet: 90, phone: 70),
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
      child: Row(
        children: [
          Gap(context.responsive.value(kiosk: 32, tablet: 24, phone: 16)),
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
              size: context.responsive.value(kiosk: 48, tablet: 32, phone: 24),
            ),
          ),
          Expanded(
            child: Text(
              'Catalog Management',
              style: TextStyle(
                fontSize: context.responsive.value(kiosk: 36, tablet: 28, phone: 20),
                fontWeight: FontWeight.w600,
                color: ColorSet.light,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Gap(context.responsive.value(kiosk: 80, tablet: 56, phone: 40)),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.selectedTab});

  final ValueNotifier<int> selectedTab;

  @override
  Widget build(BuildContext context) {
    final tabs = ['Products', 'Modifier Groups', 'Categories'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children:
            tabs.asMap().entries.map((entry) {
              final index = entry.key;
              final title = entry.value;
              final isSelected = selectedTab.value == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => selectedTab.value = index,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: context.responsive.value(kiosk: 20, tablet: 16, phone: 12),
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? ColorSet.primary.withValues(alpha: 0.1) : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? ColorSet.primary : Colors.transparent,
                          width: context.responsive.value(kiosk: 3, tablet: 2, phone: 2),
                        ),
                      ),
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? ColorSet.primary : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category,
            size: context.responsive.value(kiosk: 80, tablet: 64, phone: 48),
            color: Colors.grey.shade400,
          ),
          Gap(context.responsive.value(kiosk: 16, tablet: 12, phone: 8)),
          Text(
            'Categories',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 24, tablet: 20, phone: 16),
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          Gap(context.responsive.value(kiosk: 8, tablet: 6, phone: 4)),
          Text(
            'Category management coming soon',
            style: TextStyle(
              fontSize: context.responsive.value(kiosk: 16, tablet: 14, phone: 12),
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
