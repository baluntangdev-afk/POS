import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/tables/cartivo_sync_state_table.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../state/cartivo_products_sync_provider.dart';

/// Shows that Cartivo products are still downloading, or that the last sync failed.
class CartivoSyncBanner extends ConsumerWidget {
  const CartivoSyncBanner({super.key, this.showFailure = true});

  final bool showFailure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(cartivoProductsSyncProvider);
    final state = ref.watch(cartivoSyncStateProvider).value;
    final count = ref.watch(cartivoProductCountProvider).value ?? 0;

    if (progress != null) {
      final label =
          count == 0 ? 'Downloading products…' : 'Updating prices and stock…';
      return _Bar(
        color: AppColors.primary,
        background: AppColors.primary.withValues(alpha: 0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: _style(AppColors.primary))),
                if (progress.total > 0)
                  Text(
                    '${progress.fetched} / ${progress.total}',
                    style: _style(AppColors.primary).copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              child: LinearProgressIndicator(
                value: progress.fraction,
                minHeight: 5,
                color: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      );
    }

    if (showFailure && state?.status == CartivoSyncStatus.failed) {
      final reason = state?.lastError ?? 'Could not reach Cartivo.';
      final suffix = count > 0 ? ' Showing saved products.' : '';
      return _Bar(
        color: AppColors.warning,
        background: AppColors.warningLight,
        child: Row(
          children: [
            Expanded(
              child: Text('$reason$suffix', style: _style(AppColors.warning)),
            ),
            TextButton(
              onPressed:
                  () => ref.read(cartivoProductsSyncProvider.notifier).retry(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  TextStyle _style(Color color) =>
      AppTextStyles.labelLg.copyWith(color: color);
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.color,
    required this.background,
    required this.child,
  });

  final Color color;
  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: child,
    );
  }
}
