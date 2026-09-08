import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/models/order_event_dto.dart';
import '../../state/orders_notifier.dart';
import 'order_card.dart';
import 'order_detail_sheet.dart';

class OrdersBody extends ConsumerStatefulWidget {
  const OrdersBody({super.key});

  @override
  ConsumerState<OrdersBody> createState() => _OrdersBodyState();
}

class _OrdersBodyState extends ConsumerState<OrdersBody> {
  String _selectedTab = 'all';

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _ErrorState(
        onRetry: () => ref.read(ordersProvider.notifier).refresh(),
      ),
      data: (ordersState) {
        final deduped = _deduplicateByOrderId(ordersState.events);
        final tabs = _buildTabs(deduped);

        // If the active tab was removed (e.g. after refresh cleared its orders),
        // fall back to 'all' without triggering a rebuild.
        final effectiveTab =
            tabs.any((t) => t.key == _selectedTab) ? _selectedTab : 'all';

        final filtered = effectiveTab == 'all'
            ? deduped
            : deduped
                .where(
                  (e) => e.data.status.toLowerCase() == effectiveTab,
                )
                .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ordersState.isStale)
              _StaleBanner(
                onRetry: () => ref.read(ordersProvider.notifier).refresh(),
              ),
            _SectionHeader(
              onRefresh: () => ref.read(ordersProvider.notifier).refresh(),
            ),
            _TabsRow(
              tabs: tabs,
              selected: effectiveTab,
              onSelect: (key) => setState(() => _selectedTab = key),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.border),
            Expanded(
              child: filtered.isEmpty
                  ? const _EmptyState()
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(ordersProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, i) {
                          final event = filtered[i];
                          return OrderCard(
                            key: ValueKey(event.data.id),
                            event: event,
                            onTap: () => showOrderDetailSheet(context, event),
                            onStatusChange: (newStatus) => ref
                                .read(ordersProvider.notifier)
                                .updateStatus(event.data.id, newStatus),
                            onCancel: () => ref
                                .read(ordersProvider.notifier)
                                .cancelOrder(event.data.id),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  /// Keeps only the most recent event per order ID (highest event id).
  List<OrderEventDto> _deduplicateByOrderId(List<OrderEventDto> events) {
    final map = <String, OrderEventDto>{};
    for (final e in events) {
      final existing = map[e.data.id];
      if (existing == null || e.id > existing.id) {
        map[e.data.id] = e;
      }
    }
    return map.values.toList()..sort((a, b) => b.id.compareTo(a.id));
  }

  /// Builds tab descriptors: 'All' first, then one per unique status in data.
  List<_TabData> _buildTabs(List<OrderEventDto> events) {
    final counts = <String, int>{};
    for (final e in events) {
      final s = e.data.status.toLowerCase();
      counts[s] = (counts[s] ?? 0) + 1;
    }
    return [
      _TabData(key: 'all', label: 'All', count: events.length),
      for (final entry in counts.entries)
        _TabData(
          key: entry.key,
          label: _capitalize(entry.key),
          count: entry.value,
        ),
    ];
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ---------------------------------------------------------------------------
// Internal data & widgets
// ---------------------------------------------------------------------------

class _TabData {
  const _TabData({
    required this.key,
    required this.label,
    required this.count,
  });
  final String key;
  final String label;
  final int count;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Orders', style: AppTextStyles.titleLarge),
          GestureDetector(
            onTap: onRefresh,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.refresh_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 3),
                Text(
                  'Refresh',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabsRow extends StatelessWidget {
  const _TabsRow({
    required this.tabs,
    required this.selected,
    required this.onSelect,
  });

  final List<_TabData> tabs;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (_, i) {
          final tab = tabs[i];
          final isActive = tab.key == selected;
          return GestureDetector(
            onTap: () => onSelect(tab.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isActive ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tab.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? AppColors.textOnPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.22)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${tab.count}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? AppColors.textOnPrimary
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 14,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              "Couldn't refresh — showing cached data",
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Retry',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.border,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No orders yet',
              style: AppTextStyles.titleLarge
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text("Couldn't load orders", style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Try Again',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
