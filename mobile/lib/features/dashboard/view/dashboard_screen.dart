import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../widgets/setup_prompt_dialog.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../../inventory/state/inventory_notifier.dart';
import '../../settings/state/store_info_notifier.dart';
import '../../users/state/users_notifier.dart';
import 'store_details_dialog.dart';

class _Tile {
  final String label;
  final IconData icon;
  final Color accent;
  final String route;

  const _Tile({
    required this.label,
    required this.icon,
    required this.accent,
    required this.route,
  });
}

const _kTileNew = _Tile(
  label: 'New Order',
  icon: Icons.shopping_cart_outlined,
  accent: Color(0xFF1B7A8C),
  route: '/order',
);
const _kTileTransactions = _Tile(
  label: 'Transactions',
  icon: Icons.receipt_long_outlined,
  accent: Color(0xFF16A085),
  route: '/transactions',
);
const _kTileInventory = _Tile(
  label: 'Inventory',
  icon: Icons.storefront_outlined,
  accent: Color(0xFFE67E22),
  route: '/inventory',
);
const _kTileSettings = _Tile(
  label: 'Settings',
  icon: Icons.settings_outlined,
  accent: Color(0xFF6B7280),
  route: '/settings',
);
const _kTileUsers = _Tile(
  label: 'Users',
  icon: Icons.manage_accounts_outlined,
  accent: Color(0xFF7B68EE),
  route: '/users',
);
const _kTileCashierAccounting = _Tile(
  label: 'Cashier Accounting',
  icon: Icons.point_of_sale_outlined,
  accent: Color(0xFF8E44AD),
  route: '/cashier-accounting',
);

/// Max width the tile grid is allowed to stretch to, so very wide
/// screens (tablet landscape, desktop) don't turn tiles into oversized
/// slabs — content stays centered instead.
const double _kGridMaxWidth = 960;

String _greetingFor(DateTime now) {
  final hour = now.hour;
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

class DashboardScreen extends HookConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isAdmin = user?.isAdminOrSupervisor ?? false;

    final hasShownStoreDetailsDialog = useRef(false);
    final hasShownEmployeesDialog = useRef(false);
    final hasShownProductsDialog = useRef(false);

    void checkAndShowStoreDetailsDialog() {
      if (hasShownStoreDetailsDialog.value) return;
      if (user?.isAdmin != true) return;

      final storeState = ref.read(storeInfoProvider);
      if (storeState.isLoading || storeState.hasError) return;
      final info = storeState.value;
      if (info == null || info.storeName.trim().isNotEmpty) return;

      hasShownStoreDetailsDialog.value = true;
      unawaited(
        showStoreDetailsDialog(
          context,
          onSignOut: () => ref.read(authNotifierProvider.notifier).logout(),
        ),
      );
    }

    void checkAndShowEmployeesDialog() {
      if (hasShownEmployeesDialog.value) return;
      if (user?.isAdmin != true) return;

      final usersState = ref.read(usersProvider);
      if (usersState.isLoading || usersState.hasError) return;
      final users = usersState.value;
      if (users == null || users.length > 1) return;

      hasShownEmployeesDialog.value = true;
      unawaited(
        showSetupPromptDialog(
          context,
          title: 'No Employees Added',
          message:
              'No employee accounts have been set up yet. '
              'Add at least one employee before operating the system.',
          type: SetupPromptType.warning,
          primaryButtonText: 'Add Employee',
          secondaryButtonText: 'Sign Out',
          barrierDismissible: false,
          onPrimaryPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            context.push('/users');
          },
          onSecondaryPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            ref.read(authNotifierProvider.notifier).logout();
          },
        ),
      );
    }

    void checkAndShowProductsDialog() {
      if (hasShownProductsDialog.value) return;
      if (user?.isAdmin != true) return;

      final inventoryState = ref.read(inventoryNotifierProvider);
      if (inventoryState.isLoading || inventoryState.hasError) return;
      final products = inventoryState.value?.products;
      if (products == null || products.isNotEmpty) return;

      hasShownProductsDialog.value = true;
      unawaited(
        showSetupPromptDialog(
          context,
          title: 'No Products Found',
          message: 'Import your product catalog to get started.',
          type: SetupPromptType.warning,
          primaryButtonText: 'Import Products',
          secondaryButtonText: 'Sign Out',
          tertiaryButtonText: 'Skip for now',
          barrierDismissible: false,
          onPrimaryPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            context.push('/settings/csv-import');
          },
          onSecondaryPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            ref.read(authNotifierProvider.notifier).logout();
          },
          onTertiaryPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      );
    }

    ref.listen(storeInfoProvider, (prev, next) {
      checkAndShowStoreDetailsDialog();
      checkAndShowEmployeesDialog();
      checkAndShowProductsDialog();
    });
    ref.listen(usersProvider, (prev, next) {
      checkAndShowStoreDetailsDialog();
      checkAndShowEmployeesDialog();
      checkAndShowProductsDialog();
    });
    ref.listen(inventoryNotifierProvider, (prev, next) {
      checkAndShowStoreDetailsDialog();
      checkAndShowEmployeesDialog();
      checkAndShowProductsDialog();
    });

    // ref.listen only fires on state *changes*. If storeInfoProvider /
    // usersProvider / inventoryNotifierProvider already resolved during an
    // earlier session (they aren't autoDispose, so they stay cached across
    // logout/login), re-checking must also happen against the value already
    // in memory, not just future transitions.
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkAndShowStoreDetailsDialog();
        checkAndShowEmployeesDialog();
        checkAndShowProductsDialog();
      });
      return null;
    }, const []);

    // Runs once per screen mount so the tile grid animates in on arrival
    // without replaying every time the 30s clock tick rebuilds the screen.
    final entrance = useAnimationController(
      duration: const Duration(milliseconds: 420),
    );
    useEffect(() {
      entrance.forward();
      return null;
    }, const []);

    final tiles = [
      _kTileNew,
      _kTileTransactions,
      if (isAdmin) _kTileInventory,
      // _kTileReports hidden for now
      _kTileCashierAccounting,
      _kTileSettings,
      if (isAdmin) _kTileUsers,
    ];

    final firstName = (user?.name ?? '').trim().split(RegExp(r'\s+')).first;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1ED),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              userName: user?.name ?? '',
              userRole: user?.role ?? '',
              firstName: firstName,
              onSignOut: () => ref.read(authNotifierProvider.notifier).logout(),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final cols =
                      w > 900
                          ? 4
                          : w > 600
                          ? 3
                          : 2;
                  final pad =
                      w > 900
                          ? AppSpacing.xl
                          : w > 600
                          ? AppSpacing.lg
                          : AppSpacing.md;
                  final gap = w > 900 ? 20.0 : AppSpacing.md;
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.all(pad),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _kGridMaxWidth,
                        ),
                        child: _TileGrid(
                          tiles: tiles,
                          cols: cols,
                          gap: gap,
                          entrance: entrance,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Owns its own 30s clock tick, scoped to just this subtree — keeps the
// tile grid's entrance animation from being torn down and rebuilt every
// tick when it only ever needs to run once per screen mount.
class _Header extends HookWidget {
  final String userName;
  final String userRole;
  final String firstName;
  final VoidCallback onSignOut;

  const _Header({
    required this.userName,
    required this.userRole,
    required this.firstName,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final now = useState(DateTime.now());
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 30), (_) {
        now.value = DateTime.now();
      });
      return timer.cancel;
    }, const []);

    final greeting =
        firstName.isEmpty ? '' : '${_greetingFor(now.value)}, $firstName';

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final showDateTime = w >= 480;
        final iconOnlySignOut = w < 420;
        final showGreeting = greeting.isNotEmpty && w >= 340;
        final headerHeight = showGreeting ? 76.0 : 64.0;

        return Container(
          height: headerHeight,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE8E6E1))),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: w > 600 ? 28 : 16),
          child: Row(
            children: [
              // Brand (+ greeting, when there's room for it)
              Expanded(
                child: Row(
                  children: [
                    _BrandBlock(greeting: showGreeting ? greeting : ''),
                    if (showDateTime) ...[
                      const SizedBox(width: 16),
                      Container(
                        width: 1,
                        height: 28,
                        color: const Color(0xFFE8E6E1),
                      ),
                      const SizedBox(width: 16),
                      Flexible(child: _Clock(now: now.value)),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (userName.isNotEmpty) ...[
                      Flexible(child: _UserPill(name: userName, role: userRole)),
                      const SizedBox(width: 10),
                    ],
                    // Sign out
                    iconOnlySignOut
                        ? IconButton(
                          onPressed: onSignOut,
                          icon: const Icon(Icons.logout_rounded),
                          color: AppColors.error,
                          tooltip: 'Sign Out',
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.error.withValues(
                              alpha: 0.08,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        )
                        : SizedBox(
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: onSignOut,
                            icon: const Icon(Icons.logout_rounded, size: 15),
                            label: const Text('Sign Out'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: BorderSide(
                                color: AppColors.error.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                            ),
                          ),
                        ),
                  ],
                ),
              ),

              // User pill
            ],
          ),
        );
      },
    );
  }
}

class _BrandBlock extends StatelessWidget {
  final String greeting;

  const _BrandBlock({required this.greeting});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Brand(),
        if (greeting.isNotEmpty) ...[
          const SizedBox(height: 2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              greeting,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A9BB0), Color(0xFF1B7A8C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.shopping_cart_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 9),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Carti',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.4,
                ),
              ),
              TextSpan(
                text: 'vo',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B7A8C),
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Clock extends StatelessWidget {
  final DateTime now;

  const _Clock({required this.now});

  @override
  Widget build(BuildContext context) {
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final min = now.minute.toString().padLeft(2, '0');
    final period = now.hour < 12 ? 'AM' : 'PM';

    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dayStr = days[now.weekday - 1];
    final monStr = months[now.month - 1];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$hour:$min $period',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '$dayStr, $monStr ${now.day}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _UserPill extends StatelessWidget {
  final String name;
  final String role;

  const _UserPill({required this.name, required this.role});

  String get _initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8E6E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar with gradient
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF2A9BB0), Color(0xFF1B7A8C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                _initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  switch (role) {
                    'admin' => 'Admin',
                    'supervisor' => 'Supervisor',
                    _ => 'Cashier',
                  },
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: Color(0xFF1B7A8C),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TileGrid extends StatelessWidget {
  final List<_Tile> tiles;
  final int cols;
  final double gap;
  final Animation<double> entrance;

  const _TileGrid({
    required this.tiles,
    required this.cols,
    required this.gap,
    required this.entrance,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += cols) {
      final rowTiles = tiles.sublist(i, (i + cols).clamp(0, tiles.length));
      rows.add(
        Row(
          children: [
            for (var j = 0; j < rowTiles.length; j++) ...[
              if (j > 0) SizedBox(width: gap),
              Expanded(
                child: _TileCard(
                  tile: rowTiles[j],
                  index: i + j,
                  entrance: entrance,
                ),
              ),
            ],
            // fill remaining columns with invisible spacers
            for (var k = rowTiles.length; k < cols; k++) ...[
              SizedBox(width: gap),
              const Expanded(child: SizedBox()),
            ],
          ],
        ),
      );
      rows.add(SizedBox(height: gap));
    }

    return Column(children: rows);
  }
}

class _TileCard extends HookWidget {
  final _Tile tile;
  final int index;
  final Animation<double> entrance;

  const _TileCard({
    required this.tile,
    required this.index,
    required this.entrance,
  });

  @override
  Widget build(BuildContext context) {
    final isPressed = useState(false);
    final accent = tile.accent;

    // Staggers each tile's fade/rise-in a little behind the previous one,
    // capped so late tiles in a long grid don't wait too long to appear.
    final start = (index * 0.08).clamp(0.0, 0.6);
    final end = (start + 0.5).clamp(0.0, 1.0);
    final staggered = CurvedAnimation(
      parent: entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: staggered,
      builder: (context, child) {
        return Opacity(
          opacity: staggered.value,
          child: Transform.translate(
            offset: Offset(0, (1 - staggered.value) * 14),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => isPressed.value = true,
        onTapUp: (_) {
          isPressed.value = false;
          context.go(tile.route);
        },
        onTapCancel: () => isPressed.value = false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          constraints: const BoxConstraints(minHeight: 130),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color:
                  isPressed.value
                      ? accent.withValues(alpha: 0.5)
                      : Colors.transparent,
              width: 1.5,
            ),
            // Cards float permanently now (not just on press) so the grid
            // reads as a stack of elevated surfaces; press deepens it.
            boxShadow: [
              BoxShadow(
                color:
                    isPressed.value
                        ? accent.withValues(alpha: 0.22)
                        : Colors.black.withValues(alpha: 0.05),
                blurRadius: isPressed.value ? 22 : 14,
                offset: Offset(0, isPressed.value ? 8 : 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.md,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: accent.withValues(
                      alpha: isPressed.value ? 0.18 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Icon(tile.icon, size: 32, color: accent),
                ),
                const SizedBox(height: AppSpacing.sm + 6),
                Text(
                  tile.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.2,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
