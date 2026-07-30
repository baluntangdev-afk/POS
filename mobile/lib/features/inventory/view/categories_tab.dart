import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../state/inventory_notifier.dart';
import 'category_form_dialog.dart';

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
    await showDialog<void>(
      context: context,
      builder: (_) => const CategoryFormDialog(),
    );
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _openEditDialog(ProductGroupsTableData group) async {
    await showDialog<void>(
      context: context,
      builder: (_) => CategoryFormDialog(existing: group),
    );
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
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: groups.length,
            separatorBuilder: (context, index) => const Gap(AppSpacing.sm),
            itemBuilder: (_, i) {
              final g = groups[i];
              return Opacity(
                opacity: g.isActive ? 1.0 : 0.55,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      title: Text(g.name, style: AppTextStyles.labelLg),
                      subtitle: g.isActive ? null : const Text('Inactive'),
                      trailing:
                          isAdmin
                              ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () => _openEditDialog(g),
                                  ),
                                  Switch(
                                    value: g.isActive,
                                    onChanged: (v) async {
                                      await ref
                                          .read(
                                            inventoryNotifierProvider.notifier,
                                          )
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
                              )
                              : null,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton:
          isAdmin
              ? FloatingActionButton.extended(
                onPressed: _openAddDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Category'),
              )
              : null,
    );
  }
}
