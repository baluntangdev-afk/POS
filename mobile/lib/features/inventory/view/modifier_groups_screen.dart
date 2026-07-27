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

/// Per-product modifier-group attachment: a checklist of every *active*
/// global group, with a switch to attach/detach it to/from this product.
/// Creating a brand-new group is not done here — it deep-links back to the
/// Inventory screen's Modifier Groups tab instead.
class ModifierGroupsScreen extends ConsumerWidget {
  final int productId;
  const ModifierGroupsScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allGroupsAsync = ref.watch(allModifierGroupsProvider);
    final attachedAsync = ref.watch(attachedModifierGroupsProvider(productId));
    final authState = ref.watch(authNotifierProvider);
    final isAdmin =
        authState is AuthAuthenticated && authState.user.isAdminOrSupervisor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Modifier Groups'),
        actions: [
          if (isAdmin)
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              label: const Text('Manage Groups', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: allGroupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(message: e.toString()),
        data: (allGroups) {
          final activeGroups = allGroups.where((g) => g.group.isActive).toList();
          if (activeGroups.isEmpty) {
            return EmptyStateWidget(
              title: 'No modifier groups yet',
              subtitle: 'Create one from the Modifier Groups tab, then attach it here.',
              icon: Icons.tune_rounded,
            );
          }
          return attachedAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorStateWidget(message: e.toString()),
            data: (attached) {
              final attachedIds = attached.map((g) => g.id).toSet();
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: activeGroups.length,
                separatorBuilder: (context, index) => const Gap(AppSpacing.sm),
                itemBuilder: (context, i) {
                  final entry = activeGroups[i];
                  final isAttached = attachedIds.contains(entry.group.id);
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.group.name, style: AppTextStyles.labelLg.copyWith(fontWeight: FontWeight.w700)),
                              Text(
                                '${entry.group.isRequired ? 'Required' : 'Optional'} · Max ${entry.group.maxSelections} · ${entry.options.length} option(s)',
                                style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isAttached,
                          onChanged: isAdmin
                              ? (v) {
                                  final actions = ref.read(productModifierGroupActionsProvider(productId));
                                  if (v) {
                                    actions.attach(entry.group.id);
                                  } else {
                                    actions.detach(entry.group.id);
                                  }
                                }
                              : null,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
