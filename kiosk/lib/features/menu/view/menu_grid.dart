import 'package:flutter/material.dart';

import '../../../gen/assets.gen.dart';
import '../../../navigation/router.dart';
import '../../../widgets/resposive_wrap_container.dart';
import '../../settings/view/franchisee_info_dialog.dart';
import '../entities/menu_item.dart';
import '../enums/menu_type.dart';
import '../enums/role.dart';
import 'menu_item_card.dart';

class MenuGrid extends StatelessWidget {
  const MenuGrid({super.key, required this.role});

  final Role role;

  List<MenuItem> get menuItems => _getMenuItems();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // kiosk: width>900 → 4 cols, else 3; tablet: width>600 → 3, else 2
        final rowItems = width > 900 ? 4 : width > 600 ? 3 : 2;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ResponsiveWrapContainer(
            equalWidth: true,
            rowItems: rowItems,
            spacing: 16,
            items:
                menuItems.map((item) {
                  return MenuItemCard(
                    menuItem: item,
                    onTap: (type) {
                      if (type == MenuType.newOrder) {
                        const SalesRoute().push<void>(context);
                        return;
                      }
                      if (type == MenuType.logout) {
                        const OnboardingRoute().go(context);
                        return;
                      }
                      if (type == MenuType.userManagement) {
                        const UserManagementRoute().push<void>(context);
                        return;
                      }
                      if (type == MenuType.salesReports) {
                        const SalesReportRoute().push<void>(context);
                        return;
                      }
                      if (type == MenuType.settings) {
                        showFranchiseeInfoDialog(context);
                        return;
                      }
                      if (type == MenuType.inventory) {
                        const ProductsRoute().push<void>(context);
                        return;
                      }
                      if (type == MenuType.transactions) {
                        const TransactionsRoute().push<void>(context);
                        return;
                      }
                    },
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  List<MenuItem> _getMenuItems() {
    final baseItems = [
      MenuItem(label: 'New Order', icon: Assets.images.svg.icCart.svg(), type: MenuType.newOrder),
      MenuItem(
        label: 'Inventory',
        icon: Assets.images.svg.icInventory.svg(),
        type: MenuType.inventory,
      ),
      MenuItem(
        label: 'Replenishment',
        icon: Assets.images.png.icAdtoKart.image(),
        type: MenuType.replenishment,
      ),
      MenuItem(
        label: 'Transactions',
        icon: Assets.images.svg.icTransactions.svg(),
        type: MenuType.transactions,
      ),
      MenuItem(label: 'Promos', icon: Assets.images.svg.icPromo.svg(), type: MenuType.promos),
      MenuItem(
        label: 'Sales Reports',
        icon: Assets.images.svg.icReports.svg(),
        type: MenuType.salesReports,
      ),
      MenuItem(
        label: 'Settings',
        icon: Assets.images.svg.icSettings.svg(),
        type: MenuType.settings,
      ),
      MenuItem(
        label: 'User',
        icon: Assets.images.svg.icUserManagement.svg(),
        type: MenuType.userManagement,
      ),
      MenuItem(label: 'Sync Data', icon: Assets.images.svg.icSync.svg(), type: MenuType.syncData),
    ];
    if (role == Role.user) {
      return baseItems
          .where(
            (item) =>
                item.type == MenuType.newOrder ||
                item.type == MenuType.logout ||
                item.type == MenuType.transactions,
          )
          .toList();
    }
    return baseItems;
  }

  int getCrossAxisCount(double width) {
    if (width < 300) return 1;
    if (width < 600) return 2;
    if (width < 900) return 2;
    return 3;
  }

  double getChildAspectRatio(double width) {
    if (width < 300) return 1.2;
    if (width < 600) return 1.5;
    if (width < 900) return 1.3;
    return 1.9;
  }
}
