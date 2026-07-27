import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/error_state_widget.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../state/modifier_groups_notifier.dart';
import 'modifier_group_form_dialog.dart';
import 'modifier_option_form_dialog.dart';

/// Global modifier-group management: list every group (active or not) with
/// its options, create/edit groups and options, and soft-disable either via
/// an Active toggle. Add/Edit/toggle actions are hidden for non-admins.
class ModifierGroupsManagementScreen extends ConsumerWidget {
  const ModifierGroupsManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(allModifierGroupsProvider);
    final authState = ref.watch(authNotifierProvider);
    final isAdmin =
        authState is AuthAuthenticated && authState.user.isAdminOrSupervisor;

    return groupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorStateWidget(
        message: e.toString(),
        onRetry: () => ref.invalidate(allModifierGroupsProvider),
      ),
      data: (groups) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: groups.isEmpty
              ? EmptyStateWidget(
                  title: 'No modifier groups yet',
                  subtitle: 'Add a group so it can be attached to any product.',
                  icon: Icons.tune_rounded,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: groups.length,
                  separatorBuilder: (context, index) => const Gap(AppSpacing.md),
                  itemBuilder: (context, i) => _GroupCard(entry: groups[i], isAdmin: isAdmin),
                ),
          floatingActionButton: isAdmin
              ? FloatingActionButton.extended(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const ModifierGroupFormDialog(),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Group'),
                )
              : null,
        );
      },
    );
  }
}

class _GroupCard extends ConsumerWidget {
  final ModifierGroupWithOptions entry;
  final bool isAdmin;
  const _GroupCard({required this.entry, required this.isAdmin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = entry.group;
    return Opacity(
      opacity: group.isActive ? 1.0 : 0.55,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [BoxShadow(color: AppColors.shadow.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          title: Text(group.name, style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w700)),
          subtitle: Text(
            '${group.isRequired ? 'Required' : 'Optional'} · Max ${group.maxSelections}${group.isActive ? '' : ' · Inactive'}',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
          ),
          trailing: isAdmin
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                      tooltip: 'Edit group',
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => ModifierGroupFormDialog(existing: group),
                      ),
                    ),
                    Switch(
                      value: group.isActive,
                      onChanged: (v) => ref
                          .read(modifierGroupsManagementActionsProvider)
                          .toggleGroupActive(group.id, isActive: v),
                    ),
                  ],
                )
              : null,
          children: [
            if (entry.options.isEmpty)
              const Padding(padding: EdgeInsets.only(bottom: AppSpacing.md), child: Text('No options yet'))
            else
              for (final option in entry.options)
                Opacity(
                  opacity: option.isActive ? 1.0 : 0.55,
                  child: ListTile(
                    title: Text(option.name),
                    subtitle: Text('+ PHP ${option.additionalPrice.toStringAsFixed(2)}${option.isActive ? '' : ' · Inactive'}'),
                    trailing: isAdmin
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                                tooltip: 'Edit option',
                                onPressed: () => showDialog<void>(
                                  context: context,
                                  builder: (_) => ModifierOptionFormDialog(groupId: group.id, existing: option),
                                ),
                              ),
                              Switch(
                                value: option.isActive,
                                onChanged: (v) => ref
                                    .read(modifierGroupsManagementActionsProvider)
                                    .toggleOptionActive(option.id, isActive: v),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
            if (isAdmin)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => ModifierOptionFormDialog(groupId: group.id),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add Option'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
