import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/top_app_bar.dart';
import '../../../widgets/windows_scaffold.dart';
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
        backgroundColor: Colors.grey.shade50,
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
                  unselectedLabelColor: Colors.grey.shade600,
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
      backgroundColor: Colors.grey.shade50,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isSelected = selectedTab.value == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => selectedTab.value = index,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: r.spacingLg),
                decoration: BoxDecoration(
                  color: isSelected ? ColorSet.primary.withValues(alpha: 0.1) : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? ColorSet.primary : Colors.transparent,
                      width: r.value(kiosk: 3.0, tablet: 2.0, phone: 2.0),
                    ),
                  ),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: r.value(kiosk: 16.0, tablet: 14.0, phone: 12.0),
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
    final r = context.responsive;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category, size: r.value(kiosk: 80.0, tablet: 64.0, phone: 48.0),
              color: Colors.grey.shade400),
          SizedBox(height: r.spacingMd),
          Text(
            'Categories',
            style: TextStyle(
              fontSize: r.fontBody,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: r.spacingSm),
          Text(
            'Category management coming soon',
            style: TextStyle(fontSize: r.fontCaption, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
