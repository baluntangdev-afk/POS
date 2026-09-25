import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/image_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../../core/widgets/gradient_filled_button.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../entities/inventory_product.dart';
import '../state/inventory_notifier.dart';
import 'categories_tab.dart';
import 'modifier_groups_management_screen.dart';
import 'product_form_dialog.dart';
import 'product_quick_edit_sheet.dart';

class InventoryScreen extends HookConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.invalidate(inventoryNotifierProvider));
      return null;
    }, const []);

    final tabController = useTabController(initialLength: 3);
    final currentTab = useState(0);
    // Product ids picked in bulk-select mode; empty means normal mode.
    final selection = useState<Set<int>>(const {});
    useEffect(() {
      void listener() {
        currentTab.value = tabController.index;
        selection.value = const {};
      }
      tabController.addListener(listener);
      return () => tabController.removeListener(listener);
    }, [tabController]);

    final authState = ref.watch(authNotifierProvider);
    final isAdmin =
        authState is AuthAuthenticated && authState.user.isAdminOrSupervisor;
    final isSelecting = selection.value.isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (isSelecting) {
          selection.value = const {};
        } else {
          context.go('/dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: isSelecting
            ? _SelectionAppBar(selection: selection)
            : AppBar(
                title: const Text('Inventory'),
                leading: IconButton(
                  onPressed: () => context.go('/dashboard'),
                  icon: const Icon(Icons.arrow_back),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(64),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm + AppSpacing.xs),
                    child: _SegmentedTabs(
                      controller: tabController,
                      labels: const ['Products', 'Categories', 'Modifiers'],
                    ),
                  ),
                ),
              ),
        body: TabBarView(
          controller: tabController,
          physics: isSelecting ? const NeverScrollableScrollPhysics() : null,
          children: [
            _ProductsTab(selection: selection, isAdmin: isAdmin),
            const CategoriesTab(),
            const ModifierGroupsManagementScreen(),
          ],
        ),
        bottomNavigationBar: currentTab.value == 0 && isAdmin
            ? (isSelecting ? _BulkActionBar(selection: selection) : const _AddProductBar())
            : null,
      ),
    );
  }
}

void _showSnack(ScaffoldMessengerState messenger, String message, {VoidCallback? onUndo}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      action: onUndo == null ? null : SnackBarAction(label: 'UNDO', onPressed: onUndo),
    ));
}

// ── Header ───────────────────────────────────────────────────────────────

class _SegmentedTabs extends StatelessWidget {
  final TabController controller;
  final List<String> labels;

  const _SegmentedTabs({required this.controller, required this.labels});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: _SegmentButton(
                  label: labels[i],
                  isSelected: controller.index == i,
                  onTap: () => controller.animateTo(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: isSelected
                ? [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          child: Text(
            label,
            style: AppTextStyles.headingSm.copyWith(
              color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final ValueNotifier<Set<int>> selection;

  const _SelectionAppBar({required this.selection});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleIds =
        ref.watch(inventoryNotifierProvider).value?.filtered.map((p) => p.id).toSet() ?? {};
    final allSelected = visibleIds.isNotEmpty && selection.value.containsAll(visibleIds);

    return AppBar(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: AppColors.textOnPrimary,
      leading: IconButton(
        tooltip: 'Exit selection',
        onPressed: () => selection.value = const {},
        icon: const Icon(Icons.close_rounded),
      ),
      title: Text('${selection.value.length} selected'),
      actions: [
        TextButton(
          onPressed: () => selection.value = allSelected ? const {} : visibleIds,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textOnPrimary,
            minimumSize: const Size(0, 44),
          ),
          child: Text(allSelected ? 'Clear' : 'Select all'),
        ),
        const Gap(AppSpacing.sm),
      ],
    );
  }
}

// ── Bottom bars ──────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final Widget child;
  const _BottomBar({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md - AppSpacing.xs, AppSpacing.md, AppSpacing.md),
          child: child,
        ),
      ),
    );
  }
}

class _AddProductBar extends ConsumerWidget {
  const _AddProductBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(inventoryNotifierProvider).value;
    return _BottomBar(
      // The Scaffold's bottomNavigationBar slot allows up to the full screen
      // height, and GradientFilledButton's aligned Container expands to fill
      // it; pin the height.
      child: SizedBox(
        height: 56,
        child: GradientFilledButton(
          minHeight: 56,
          onPressed: s == null
              ? null
              : () => ProductFormDialog.show(
                    context,
                    groupId: s.selectedGroupId ?? (s.groups.isNotEmpty ? s.groups.first.id : null),
                  ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded),
              const Gap(AppSpacing.sm),
              Text('Add product',
                  style: AppTextStyles.headingSm.copyWith(color: AppColors.textOnPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulkActionBar extends ConsumerWidget {
  final ValueNotifier<Set<int>> selection;

  const _BulkActionBar({required this.selection});

  Future<void> _setAvailability(BuildContext context, WidgetRef ref, bool isAvailable) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(inventoryNotifierProvider.notifier);
    final products = ref.read(inventoryNotifierProvider).value?.products ?? const [];
    final ids = selection.value;
    // Remember each item's prior state so UNDO restores mixed selections exactly.
    final wasOn = [for (final p in products) if (ids.contains(p.id) && p.isAvailable) p.id];
    final wasOff = [for (final p in products) if (ids.contains(p.id) && !p.isAvailable) p.id];

    selection.value = const {};
    try {
      await notifier.setAvailability(ids.toList(), isAvailable: isAvailable);
    } catch (e) {
      _showSnack(messenger, 'Could not update products: $e');
      return;
    }
    _showSnack(
      messenger,
      '${ids.length} ${ids.length == 1 ? 'item' : 'items'} '
      '${isAvailable ? 'back on menu' : 'hidden from menu'}',
      onUndo: () async {
        await notifier.setAvailability(wasOn, isAvailable: true);
        await notifier.setAvailability(wasOff, isAvailable: false);
      },
    );
  }

  Future<void> _move(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final groups = ref.read(inventoryNotifierProvider).value?.groups ?? const [];
    final target = await showModalBottomSheet<InventoryGroup>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                child: Text('Move ${selection.value.length} to…', style: AppTextStyles.headingMd),
              ),
              for (final g in groups)
                ListTile(
                  minTileHeight: 56,
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  leading: const Icon(Icons.folder_outlined, color: AppColors.primary),
                  title: Text(g.name, style: AppTextStyles.headingSm),
                  trailing: Text('${g.productCount}',
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
                  onTap: () => Navigator.pop(context, g),
                ),
            ],
          ),
        ),
      ),
    );
    if (target == null) return;

    final ids = selection.value.toList();
    try {
      await ref.read(inventoryNotifierProvider.notifier).moveToCategory(ids, target.id);
    } on StateError catch (e) {
      _showSnack(messenger, e.message);
      return;
    }
    selection.value = const {};
    _showSnack(messenger,
        'Moved ${ids.length} ${ids.length == 1 ? 'item' : 'items'} to ${target.name}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = selection.value.length;
    return _BottomBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _BulkButton(
                  icon: Icons.visibility_off_outlined,
                  label: 'Hide $count',
                  color: AppColors.warning,
                  background: AppColors.warningLight,
                  onPressed: () => _setAvailability(context, ref, false),
                ),
              ),
              const Gap(AppSpacing.sm),
              Expanded(
                child: _BulkButton(
                  icon: Icons.visibility_outlined,
                  label: 'Show $count',
                  color: AppColors.primaryDark,
                  background: AppColors.primary.withValues(alpha: 0.10),
                  onPressed: () => _setAvailability(context, ref, true),
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _move(context, ref),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            icon: const Icon(Icons.drive_file_move_outline),
            label: Text('Move to category…', style: AppTextStyles.headingSm),
          ),
        ],
      ),
    );
  }
}

class _BulkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onPressed;

  const _BulkButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: background,
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: color.withValues(alpha: 0.35), width: 1.5),
        ),
      ),
      icon: Icon(icon),
      label: Text(label, style: AppTextStyles.headingSm),
    );
  }
}

// ── Products tab ─────────────────────────────────────────────────────────

class _ProductsTab extends ConsumerWidget {
  final ValueNotifier<Set<int>> selection;
  final bool isAdmin;

  const _ProductsTab({required this.selection, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryNotifierProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorStateWidget(
        message: e.toString(),
        onRetry: () => ref.read(inventoryNotifierProvider.notifier).refresh(),
      ),
      data: (s) => _InventoryBody(state: s, selection: selection, isAdmin: isAdmin),
    );
  }
}

class _InventoryBody extends HookConsumerWidget {
  final InventoryState state;
  final ValueNotifier<Set<int>> selection;
  final bool isAdmin;

  const _InventoryBody({required this.state, required this.selection, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Seeded from the notifier: the tab is rebuilt when swiping back to it,
    // and the notifier keeps the query across that.
    final searchController = useTextEditingController(text: state.search);
    useListenable(searchController);
    final notifier = ref.read(inventoryNotifierProvider.notifier);

    if (state.products.isEmpty && state.groups.isEmpty) {
      return EmptyStateWidget(
        title: 'No products yet',
        subtitle: 'Import a products CSV in Settings to get started.',
        icon: Icons.inventory_2_outlined,
      );
    }

    final filtered = state.filtered;
    final isSelecting = selection.value.isNotEmpty;
    final total = state.products.length;
    final onMenu = state.availableCount;

    void toggleSelected(int id) {
      final next = {...selection.value};
      if (!next.remove(id)) next.add(id);
      selection.value = next;
    }

    Future<void> toggleAvailability(InventoryProduct product) async {
      final messenger = ScaffoldMessenger.of(context);
      final nowAvailable = !product.isAvailable;
      try {
        await notifier.toggleAvailability(product);
      } catch (e) {
        _showSnack(messenger, 'Could not update ${product.name}: $e');
        return;
      }
      _showSnack(
        messenger,
        nowAvailable ? '${product.name} back on menu' : '${product.name} hidden from menu',
        onUndo: () => notifier.setAvailability([product.id], isAvailable: product.isAvailable),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
              child: _SearchField(
                controller: searchController,
                onChanged: notifier.setSearch,
                onClear: () {
                  searchController.clear();
                  notifier.setSearch(null);
                },
              ),
            ),
            const Gap(AppSpacing.md - AppSpacing.xs),
            _ChipRow(
              children: [
                for (final (filter, label, count) in [
                  (InventoryStatusFilter.all, 'All', total),
                  (InventoryStatusFilter.onMenu, 'On menu', onMenu),
                  (InventoryStatusFilter.hidden, 'Hidden', total - onMenu),
                ])
                  _FilterPill(
                    label: label,
                    count: count,
                    isSelected: state.statusFilter == filter,
                    selectedColor: AppColors.textPrimary,
                    accent: filter == InventoryStatusFilter.hidden && count > 0
                        ? AppColors.warning
                        : null,
                    onTap: () => notifier.setStatusFilter(filter),
                  ),
              ],
            ),
            if (state.groups.isNotEmpty) ...[
              const Gap(AppSpacing.sm),
              _ChipRow(
                children: [
                  _FilterPill(
                    label: 'All categories',
                    isSelected: state.selectedGroupId == null,
                    onTap: () => notifier.selectGroup(null),
                  ),
                  for (final g in state.groups)
                    _FilterPill(
                      label: g.name,
                      count: g.productCount,
                      isSelected: state.selectedGroupId == g.id,
                      onTap: () => notifier.selectGroup(g.id),
                    ),
                ],
              ),
            ],
            const Gap(AppSpacing.md - AppSpacing.xs),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: notifier.refresh,
                child: filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          Gap(AppSpacing.xl),
                          EmptyStateWidget(
                            title: 'No products match',
                            subtitle: 'Try another name, or change the filters above.',
                            icon: Icons.search_off_rounded,
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                        itemCount: filtered.length + 1,
                        itemBuilder: (context, i) {
                          if (i == filtered.length) {
                            return _ListFooterHint(isAdmin: isAdmin);
                          }
                          final product = filtered[i];
                          return RepaintBoundary(
                            child: _ProductRow(
                              product: product,
                              isFirst: i == 0,
                              isLast: i == filtered.length - 1,
                              showSwitch: isAdmin && !isSelecting,
                              isSelecting: isSelecting,
                              isSelected: selection.value.contains(product.id),
                              onTap: !isAdmin
                                  ? null
                                  : isSelecting
                                      ? () => toggleSelected(product.id)
                                      : () => ProductQuickEditSheet.show(context, product),
                              onLongPress: isAdmin ? () => toggleSelected(product.id) : null,
                              onToggle: () => toggleAvailability(product),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({required this.controller, required this.onChanged, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: AppTextStyles.bodyLg,
      decoration: InputDecoration(
        hintText: 'Search product name',
        hintStyle: AppTextStyles.bodyLg.copyWith(color: AppColors.textSecondary),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: onClear,
                icon: const Icon(Icons.cancel_rounded, color: AppColors.border),
              ),
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

// ── Filter chips ─────────────────────────────────────────────────────────

class _ChipRow extends StatelessWidget {
  final List<Widget> children;
  const _ChipRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (context, index) => const Gap(AppSpacing.sm),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final int? count;
  final bool isSelected;
  final Color selectedColor;
  final Color? accent;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    this.count,
    required this.isSelected,
    this.selectedColor = AppColors.primary,
    this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isSelected ? AppColors.textOnPrimary : (accent ?? AppColors.textPrimary);
    final border = isSelected
        ? selectedColor
        : (accent?.withValues(alpha: 0.45) ?? AppColors.border);

    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: isSelected ? selectedColor : AppColors.surface,
        shape: StadiumBorder(side: BorderSide(color: border, width: 1.5)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Center(
              widthFactor: 1,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: label),
                  if (count != null)
                    TextSpan(
                      text: '  $count',
                      style: TextStyle(color: fg.withValues(alpha: 0.75)),
                    ),
                ]),
                style: AppTextStyles.labelLg.copyWith(
                  color: fg,
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Product rows ─────────────────────────────────────────────────────────

class _ProductRow extends StatelessWidget {
  final InventoryProduct product;
  final bool isFirst;
  final bool isLast;
  final bool showSwitch;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onToggle;

  const _ProductRow({
    required this.product,
    required this.isFirst,
    required this.isLast,
    required this.showSwitch,
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const r = Radius.circular(AppSpacing.radiusLg);
    final radius = BorderRadius.vertical(
      top: isFirst ? r : Radius.zero,
      bottom: isLast ? r : Radius.zero,
    );
    final hidden = !product.isAvailable;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isFirst)
          const ColoredBox(
            color: AppColors.surface,
            child: Divider(height: 1, indent: 72, color: AppColors.surfaceVariant),
          ),
        Material(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            onLongPress: onLongPress,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.md - AppSpacing.xs, AppSpacing.sm + 2,
                    showSwitch ? AppSpacing.xs : AppSpacing.md, AppSpacing.sm + 2),
                child: Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: isSelecting
                          ? _SelectBox(key: const ValueKey('check'), isSelected: isSelected)
                          : _Thumbnail(key: const ValueKey('thumb'), product: product),
                    ),
                    const Gap(AppSpacing.md - AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.headingSm.copyWith(
                              fontWeight: FontWeight.w700,
                              color: hidden ? AppColors.textSecondary : AppColors.textPrimary,
                            ),
                          ),
                          const Gap(2),
                          Row(
                            children: [
                              if (hidden) ...[
                                const _HiddenTag(),
                                const Gap(6),
                              ],
                              if (product.group != null)
                                Flexible(
                                  child: Text(
                                    product.group!.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyMd
                                        .copyWith(color: AppColors.textSecondary),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    Text(
                      'PHP ${product.price.toStringAsFixed(2)}',
                      style: AppTextStyles.headingSm.copyWith(
                        fontWeight: FontWeight.w800,
                        color: hidden ? AppColors.textSecondary : AppColors.primaryDark,
                      ),
                    ),
                    if (showSwitch)
                      Semantics(
                        label: '${product.name} available on menu',
                        child: Switch(
                          value: product.isAvailable,
                          activeTrackColor: AppColors.primary,
                          onChanged: (_) => onToggle(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HiddenTag extends StatelessWidget {
  const _HiddenTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        'Hidden',
        style: AppTextStyles.labelMd.copyWith(
          color: AppColors.warning,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _SelectBox extends StatelessWidget {
  final bool isSelected;
  const _SelectBox({super.key, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 2,
            ),
          ),
          child: isSelected
              ? const Icon(Icons.check_rounded, size: 18, color: AppColors.textOnPrimary)
              : null,
        ),
      ),
    );
  }
}

// Tints for the initials placeholder, picked by category so items from the
// same category read as a group without needing a color field on it.
const _thumbTints = [
  AppColors.primary,
  AppColors.secondaryDark,
  AppColors.warning,
  AppColors.primaryDark,
  AppColors.success,
];

// Desaturates the photo of hidden items — grayscale reads as "intentionally
// off the menu" rather than a broken/loading thumbnail.
const _greyscaleMatrix = <double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
];

class _Thumbnail extends StatelessWidget {
  final InventoryProduct product;
  const _Thumbnail({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final url = product.imageUrl;
    Widget child;
    if (url != null && url.isNotEmpty) {
      Widget errorBuilder(BuildContext context, Object e, StackTrace? st) =>
          _Initials(product: product);
      child = ImageStorageService.isNetworkUrl(url)
          ? Image.network(url, fit: BoxFit.cover, cacheWidth: 144, errorBuilder: errorBuilder)
          : Image.file(File(url), fit: BoxFit.cover, cacheWidth: 144, errorBuilder: errorBuilder);
    } else {
      child = _Initials(product: product);
    }
    if (!product.isAvailable) {
      child = ColorFiltered(colorFilter: const ColorFilter.matrix(_greyscaleMatrix), child: child);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: SizedBox(width: 48, height: 48, child: child),
    );
  }
}

class _Initials extends StatelessWidget {
  final InventoryProduct product;
  const _Initials({required this.product});

  @override
  Widget build(BuildContext context) {
    final tint = _thumbTints[product.groupId % _thumbTints.length];
    final initials = product.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return ColoredBox(
      color: tint.withValues(alpha: 0.14),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.headingSm.copyWith(color: tint, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _ListFooterHint extends StatelessWidget {
  final bool isAdmin;
  const _ListFooterHint({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Text(
        isAdmin
            ? 'Tap a product to edit · Hold to select several · Pull down to refresh'
            : 'Pull down to refresh',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
