import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';

// ─── Tile definition ──────────────────────────────────────────────────────────

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

const _kTileNew     = _Tile(label: 'New Order',     icon: Icons.shopping_cart_outlined,    accent: Color(0xFF1B7A8C), route: '/order');
const _kTileTransactions = _Tile(label: 'Transactions', icon: Icons.receipt_long_outlined, accent: Color(0xFF16A085), route: '/transactions');
const _kTileCatalog = _Tile(label: 'Inventory',     icon: Icons.storefront_outlined,       accent: Color(0xFFE67E22), route: '/catalog');
const _kTileReports = _Tile(label: 'Sales Reports', icon: Icons.bar_chart_rounded,         accent: Color(0xFF27AE60), route: '/reports');
const _kTileSettings= _Tile(label: 'Settings',      icon: Icons.settings_outlined,         accent: Color(0xFF6B7280), route: '/settings');
const _kTileUsers   = _Tile(label: 'Users',         icon: Icons.manage_accounts_outlined,  accent: Color(0xFF7B68EE), route: '/users');
const _kTileCashierAccounting = _Tile(label: 'Cashier Accounting', icon: Icons.point_of_sale_outlined, accent: Color(0xFF8E44AD), route: '/cashier-accounting');

// ─── Screen ───────────────────────────────────────────────────────────────────

class DashboardScreen extends HookConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isAdmin = user?.isAdmin ?? false;

    final now = useState(DateTime.now());
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 30), (_) {
        now.value = DateTime.now();
      });
      return timer.cancel;
    }, const []);

    final tiles = [
      _kTileNew,
      _kTileTransactions,
      _kTileCatalog,
      _kTileReports,
      _kTileCashierAccounting,
      _kTileSettings,
      if (isAdmin) _kTileUsers,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1ED),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              now: now.value,
              userName: user?.name ?? '',
              userRole: user?.role ?? '',
              onSignOut: () => ref.read(authNotifierProvider.notifier).logout(),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final cols = w > 900 ? 4 : w > 600 ? 3 : 2;
                  final pad = w > 900 ? 32.0 : w > 600 ? 24.0 : 16.0;
                  final gap = w > 900 ? 20.0 : 16.0;
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.all(pad),
                    child: _TileGrid(tiles: tiles, cols: cols, gap: gap),
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

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final DateTime now;
  final String userName;
  final String userRole;
  final VoidCallback onSignOut;

  const _Header({
    required this.now,
    required this.userName,
    required this.userRole,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final showDateTime = w >= 480;
        final iconOnlySignOut = w < 420;

        return Container(
          height: 64,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE8E6E1)),
            ),
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
              // Brand
              _Brand(),

              if (showDateTime) ...[
                const SizedBox(width: 16),
                Container(width: 1, height: 28, color: const Color(0xFFE8E6E1)),
                const SizedBox(width: 16),
                _Clock(now: now),
              ],

              const Spacer(),

              // User pill
              if (userName.isNotEmpty) ...[
                _UserPill(name: userName, role: userRole),
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
                        backgroundColor: AppColors.error.withValues(alpha: 0.08),
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
        );
      },
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
          child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 18),
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
        ),
        Text(
          '$dayStr, $monStr ${now.day}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: Color(0xFF9CA3AF),
            fontWeight: FontWeight.w400,
          ),
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
                  role == 'admin' ? 'Admin' : 'Cashier',
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

// ─── Grid ─────────────────────────────────────────────────────────────────────

class _TileGrid extends StatelessWidget {
  final List<_Tile> tiles;
  final int cols;
  final double gap;

  const _TileGrid({required this.tiles, required this.cols, required this.gap});

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
              Expanded(child: _TileCard(tile: rowTiles[j])),
            ],
            // fill remaining columns with invisible spacers
            for (var k = rowTiles.length; k < cols; k++) ...[
              SizedBox(width: gap),
              const Expanded(child: SizedBox()),
            ],
          ],
        ),
      );
      if (i + cols < tiles.length) SizedBox(height: gap);
      rows.add(SizedBox(height: gap));
    }

    return Column(children: rows);
  }
}

// ─── Tile Card ────────────────────────────────────────────────────────────────

class _TileCard extends HookWidget {
  final _Tile tile;
  const _TileCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    final isPressed = useState(false);
    final accent = tile.accent;

    return GestureDetector(
      onTapDown: (_) => isPressed.value = true,
      onTapUp: (_) {
        isPressed.value = false;
        context.push(tile.route);
      },
      onTapCancel: () => isPressed.value = false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        constraints: const BoxConstraints(minHeight: 130),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPressed.value
                ? accent.withValues(alpha: 0.5)
                : const Color(0xFFE8E6E1),
            width: 1.5,
          ),
          boxShadow: isPressed.value
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  const BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isPressed.value ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(tile.icon, size: 32, color: accent),
              ),
              const SizedBox(height: 14),
              Text(
                tile.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                  letterSpacing: -0.2,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
