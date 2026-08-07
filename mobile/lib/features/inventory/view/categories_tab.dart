import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/gradient_fab.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../state/inventory_notifier.dart';
import 'category_form_dialog.dart';

/// Deterministic colors for the category avatar so rows are visually
/// distinct without needing a color field on the category itself.
const _avatarPalette = [
  AppColors.primary,
  AppColors.secondaryDark,
  AppColors.primaryDark,
  AppColors.secondary,
  AppColors.primaryLight,
];

class CategoriesTab extends ConsumerStatefulWidget {
  const CategoriesTab({super.key});

  @override
  ConsumerState<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends ConsumerState<CategoriesTab> {
  late Future<List<ProductGroupsTableData>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  void _loadGroups() {
    final db = ref.read(databaseProvider);
    _groupsFuture = db.productsDao.getAllGroups();
  }

  Future<void> _refresh() async {
    setState(_loadGroups);
    await _groupsFuture;
    await ref.read(inventoryNotifierProvider.notifier).refresh();
  }

  Future<void> _openAddDialog() async {
    await CategoryFormDialog.show(context);
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _openEditDialog(ProductGroupsTableData group) async {
    await CategoryFormDialog.show(context, existing: group);
    if (!mounted) return;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isAdmin =
        authState is AuthAuthenticated && authState.user.isAdminOrSupervisor;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<ProductGroupsTableData>>(
        future: _groupsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups = snapshot.data!;
          if (groups.isEmpty) {
            return EmptyStateWidget(
              title: 'No categories yet',
              subtitle:
                  isAdmin
                      ? 'Tap the + button to add one.'
                      : 'Ask an admin to add one.',
              icon: Icons.category_outlined,
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl + AppSpacing.xl),
              itemCount: groups.length,
              separatorBuilder: (context, index) => const Gap(AppSpacing.sm),
              itemBuilder: (_, i) {
                final g = groups[i];
                final avatarColor = _avatarPalette[i % _avatarPalette.length];
                return Opacity(
                  opacity: g.isActive ? 1.0 : 0.55,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: AppShadows.card,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: avatarColor,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: Text(
                            g.name.isNotEmpty ? g.name[0].toUpperCase() : '?',
                            style: AppTextStyles.labelLg
                                .copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const Gap(AppSpacing.md),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g.name, style: AppTextStyles.labelLg),
                              if (!g.isActive) ...[
                                const Gap(2),
                                Text('Inactive',
                                    style: AppTextStyles.bodySm
                                        .copyWith(color: AppColors.textSecondary)),
                              ],
                            ],
                          ),
                        ),
                        if (isAdmin) ...[
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                              onPressed: () => _openEditDialog(g),
                            ),
                          ),
                          Switch(
                            value: g.isActive,
                            onChanged: (v) async {
                              await ref
                                  .read(inventoryNotifierProvider.notifier)
                                  .updateCategory(
                                    id: g.id,
                                    name: g.name,
                                    isActive: v,
                                  );
                              if (!mounted) return;
                              await _refresh();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: isAdmin
          ? GradientFab(
              icon: Icons.add_rounded,
              label: 'Add Category',
              onPressed: _openAddDialog,
            )
          : null,
    );
  }
}
