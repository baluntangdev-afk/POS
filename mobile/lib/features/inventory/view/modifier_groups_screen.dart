import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../state/modifier_groups_notifier.dart';
import 'modifier_group_form_dialog.dart';
import 'modifier_option_form_dialog.dart';

/// Lists a single product's modifier groups (each expandable to show its
/// options), with create/edit/delete affordances for both groups and options.
///
/// Scoped to one [productId] since mobile's modifier groups are 1:1-owned by
/// a single product (Phase 3 Design Decision #2) — unlike kiosk's
/// reusable-across-products model.
class ModifierGroupsScreen extends ConsumerWidget {
  final int productId;
  const ModifierGroupsScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(modifierGroupsProvider(productId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Modifier Groups')),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(modifierGroupsProvider(productId)),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return EmptyStateWidget(
              title: 'No modifier groups yet',
              subtitle: 'Add a group to let customers customize this product.',
              icon: Icons.tune_rounded,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: groups.length,
            separatorBuilder: (context, index) => const Gap(AppSpacing.md),
            itemBuilder: (context, i) => _ModifierGroupCard(
              productId: productId,
              entry: groups[i],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => ModifierGroupFormDialog(productId: productId),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Group'),
      ),
    );
  }
}

class _ModifierGroupCard extends ConsumerWidget {
  final int productId;
  final ModifierGroupWithOptions entry;

  const _ModifierGroupCard({required this.productId, required this.entry});

  Future<void> _confirmDeleteGroup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this modifier group?'),
        content: Text(
            '"${entry.group.name}" and all of its options will be permanently removed. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(modifierGroupsActionsProvider(productId)).deleteGroup(entry.group.id);
  }

  Future<void> _confirmDeleteOption(
    BuildContext context,
    WidgetRef ref,
    int optionId,
    String optionName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this option?'),
        content: Text('"$optionName" will be permanently removed. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(modifierGroupsActionsProvider(productId)).deleteOption(optionId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = entry.group;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          group.name,
          style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${group.isRequired ? 'Required' : 'Optional'} · Max ${group.maxSelections}',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              tooltip: 'Edit group',
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => ModifierGroupFormDialog(productId: productId, existing: group),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              tooltip: 'Delete group',
              onPressed: () => _confirmDeleteGroup(context, ref),
            ),
          ],
        ),
        children: [
          if (entry.options.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: Text('No options yet'),
            )
          else
            for (final option in entry.options)
              ListTile(
                title: Text(option.name),
                subtitle: Text('+ PHP ${option.additionalPrice.toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                      tooltip: 'Edit option',
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => ModifierOptionFormDialog(
                          productId: productId,
                          groupId: group.id,
                          existing: option,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                      tooltip: 'Delete option',
                      onPressed: () => _confirmDeleteOption(context, ref, option.id, option.name),
                    ),
                  ],
                ),
              ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => ModifierOptionFormDialog(productId: productId, groupId: group.id),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Option'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
