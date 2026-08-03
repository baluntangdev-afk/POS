import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/top_app_bar.dart';
import '../../../widgets/windows_scaffold.dart';
import '../state/inventory_categories_notifier.dart';
import '../state/inventory_modifier_groups_notifier.dart';
import '../state/inventory_products_notifier.dart';
import 'inventory_grid_screen.dart';
import 'categories_tab.dart';

class InventoryScreen extends HookConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(inventoryProductsProvider);
        ref.invalidate(inventoryCategoriesProvider);
        ref.invalidate(inventoryModifierGroupsProvider);
      });
      return null;
    }, []);

    final isAndroid = context.breakpoint.isAndroid;

    if (isAndroid) {
      return _AndroidInventoryScreen();
    }

    return _WindowsInventoryScreen();
  }
}

// ── Android: Material TabBar + TabBarView (swipe-enabled) ────────────────────

class _AndroidInventoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const tabs = ['Products', 'Categories']; // Modifier Groups hidden for now
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
              const TopAppBar(title: 'Inventory Management'),
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
            InventoryGridScreen(),
            CategoriesTab(),
          ],
        ),
      ),
    );
  }
}

// ── Windows: custom GestureDetector tab bar + IndexedStack ───────────────────

class _WindowsInventoryScreen extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final selectedTab = useState(0);

    return WindowsScaffold(
      backgroundColor: ColorSet.background,
      body: Column(
        children: [
          const TopAppBar(title: 'Inventory Management'),
          _WindowsTabBar(selectedTab: selectedTab),
          Expanded(
            child: IndexedStack(
              index: selectedTab.value,
              children: const [InventoryGridScreen(), CategoriesTab()],
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
    const tabs = ['Products', 'Categories']; // Modifier Groups hidden for now
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

