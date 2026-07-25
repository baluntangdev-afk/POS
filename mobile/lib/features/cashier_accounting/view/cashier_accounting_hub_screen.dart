import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class _HubTile {
  final String label;
  final String description;
  final IconData icon;
  final Color accent;
  final String route;
  final String historyRoute;

  const _HubTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.accent,
    required this.route,
    required this.historyRoute,
  });
}

const _kTiles = [
  _HubTile(
    label: 'X-Reading',
    description: 'Per-cashier running sales snapshot',
    icon: Icons.receipt_long_rounded,
    accent: Color(0xFF1B7A8C),
    route: '/cashier-accounting/x-reading',
    historyRoute: '/cashier-accounting/x-reading/history',
  ),
  _HubTile(
    label: 'Daily Report',
    description: 'Per-cashier VAT & cash summary',
    icon: Icons.summarize_rounded,
    accent: Color(0xFF27AE60),
    route: '/cashier-accounting/daily-report',
    historyRoute: '/cashier-accounting/daily-report/history',
  ),
  _HubTile(
    label: 'Z-Reading',
    description: 'Store-wide end-of-day closing',
    icon: Icons.point_of_sale_rounded,
    accent: Color(0xFF8E44AD),
    route: '/cashier-accounting/z-reading',
    historyRoute: '/cashier-accounting/z-reading/history',
  ),
];

class CashierAccountingHubScreen extends StatelessWidget {
  const CashierAccountingHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cashier Accounting'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _kTiles.length,
        separatorBuilder: (_, _) => const Gap(AppSpacing.md),
        itemBuilder: (context, i) => _HubCard(tile: _kTiles[i]),
      ),
    );
  }
}

class _HubCard extends HookWidget {
  final _HubTile tile;
  const _HubCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    final isPressed = useState(false);

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
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isPressed.value ? tile.accent.withValues(alpha: 0.5) : AppColors.border,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(color: AppColors.shadow.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: tile.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(tile.icon, size: 28, color: tile.accent),
            ),
            const Gap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tile.label, style: AppTextStyles.headingSm),
                  const Gap(2),
                  Text(tile.description, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push(tile.historyRoute),
              icon: const Icon(Icons.history_rounded, size: 18),
              label: const Text('History'),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
