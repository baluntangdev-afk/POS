import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../gen/assets.gen.dart';
import '../../../navigation/router.dart';
import '../../../widgets/resposive_wrap_container.dart';
import '../../orders/state/pending_orders_count_provider.dart';
import '../../settings/view/pos_terminal_details_dialog.dart';
import '../entities/menu_item.dart';
import '../enums/menu_type.dart';
import '../enums/role.dart';
import 'menu_item_card.dart';

class MenuGrid extends ConsumerWidget {
  const MenuGrid({super.key, required this.role});

  final Role role;

  List<MenuItem> _menuItems(int pendingOrdersCount) {
    return _getMenuItems().map((item) {
      if (item.type != MenuType.orders) return item;
      // Always set, even at 0, so the badge stays visible at all times.
      return item.copyWith(badgeCount: pendingOrdersCount);
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingOrdersCount = ref.watch(pendingOrdersCountProvider).value ?? 0;
    final menuItems = _menuItems(pendingOrdersCount);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final rowItems = width > 900 ? 4 : width > 600 ? 3 : 2;
        final padding = width > 900 ? 32.0 : width > 600 ? 24.0 : 16.0;
        final spacing = width > 900 ? 20.0 : 16.0;
        return Padding(
          padding: EdgeInsets.all(padding),
          child: ResponsiveWrapContainer(
            equalWidth: true,
            rowItems: rowItems,
            spacing: spacing,
            items:
                menuItems.map((item) {
                  return MenuItemCard(
                    menuItem: item,
                    onTap: (type) {
                      if (type == MenuType.newOrder) {
                         const OrderingRoute().push<void>(context);
                         return;
                      }
                      if (type == MenuType.orders) {
                        const OrdersRoute().push<void>(context);
                        return;
                      }
                      if (type == MenuType.logout) {
                        const LoginRoute().go(context);
                        return;
                      }
                      if (type == MenuType.userManagement) {
                        const UserManagementRoute().push<void>(context);
                        return;
                      }
                      if (type == MenuType.settings) {
                        showPosTerminalDetailsDialog(context);
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
                      if (type == MenuType.backupTransfer) {
                        const DeviceTransferRoute().push<void>(context);
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
      const MenuItem(
        label: 'Orders',
        icon: Icon(Icons.receipt_long_outlined),
        type: MenuType.orders,
      ),
      MenuItem(
        label: 'Inventory',
        icon: Assets.images.svg.icInventory.svg(),
        type: MenuType.inventory,
      ),
      MenuItem(
        label: 'Transactions',
        icon: Assets.images.svg.icTransactions.svg(),
        type: MenuType.transactions,
      ),
      MenuItem(label: 'Promos', icon: Assets.images.svg.icPromo.svg(), type: MenuType.promos),
      // Sales Reports hidden for now
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
      const MenuItem(
        label: 'Backup & Transfer',
        icon: Icon(Icons.settings_backup_restore_rounded),
        type: MenuType.backupTransfer,
      ),
    ];
    if (role == Role.user) {
      return baseItems
          .where(
            (item) =>
                item.type == MenuType.newOrder ||
                item.type == MenuType.orders ||
                item.type == MenuType.logout ||
                item.type == MenuType.transactions,
          )
          .toList();
    }
    return baseItems; // admin and supervisor see all menus
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
