import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/services/image_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/state/auth_providers.dart';
import '../../auth/state/auth_state.dart';
import '../state/users_notifier.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final authState = ref.watch(authNotifierProvider);
    final canManage =
        authState is AuthAuthenticated && authState.user.isAdminOrSupervisor;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/dashboard');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Users'),
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: () {
              context.go('/dashboard');
            },
            icon: Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: () => ref.read(usersProvider.notifier).refresh(),
            ),
          ],
        ),
        floatingActionButton:
            canManage
                ? FloatingActionButton.extended(
                  onPressed: () => _showAddUserDialog(context, ref),
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('Add User'),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                )
                : null,
        body: usersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const Gap(AppSpacing.md),
                    Text(
                      'Failed to load users',
                      style: AppTextStyles.headingSm.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    Text(
                      e.toString(),
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(AppSpacing.lg),
                    FilledButton(
                      onPressed: () => ref.read(usersProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
          data: (users) {
            if (users.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.group_outlined,
                      size: 64,
                      color: AppColors.textDisabled,
                    ),
                    const Gap(AppSpacing.md),
                    Text(
                      'No users yet',
                      style: AppTextStyles.headingSm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Gap(AppSpacing.xs),
                    Text(
                      'Tap + to add a user',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                canManage ? AppSpacing.xxl + AppSpacing.lg : AppSpacing.lg,
              ),
              itemCount: users.length,
              separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
              itemBuilder:
                  (context, index) => _UserCard(
                    user: users[index],
                    canManage: canManage,
                    onEdit: () => _showEditUserDialog(context, ref, users[index]),
                    onResetPin:
                        () => _confirmResetPin(context, ref, users[index]),
                    onDelete: () => _confirmDelete(context, ref, users[index]),
                  ),
            );
          },
        ),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (ctx) => _UserFormDialog(
            onSubmit: (
              name,
              role,
              employeeId,
              phone,
              avatarUrl, {
              isActive = true,
            }) async {
              await ref
                  .read(usersProvider.notifier)
                  .addUser(
                    name: name,
                    role: role,
                    employeeId: employeeId,
                    phone: phone,
                    avatarUrl: avatarUrl,
                  );
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
          ),
    );
  }

  void _showEditUserDialog(
    BuildContext context,
    WidgetRef ref,
    UsersTableData user,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => _UserFormDialog(
            existing: user,
            onSubmit: (
              name,
              role,
              employeeId,
              phone,
              avatarUrl, {
              isActive = true,
            }) async {
              await ref
                  .read(usersProvider.notifier)
                  .editUser(
                    id: user.id,
                    name: name,
                    role: role,
                    isActive: isActive,
                    employeeId: employeeId,
                    phone: phone,
                    avatarUrl: avatarUrl,
                  );
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
          ),
    );
  }

  void _confirmResetPin(
    BuildContext context,
    WidgetRef ref,
    UsersTableData user,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Reset PIN'),
            content: Text(
              'Reset "${user.name}"\'s PIN to the default? They\'ll be asked to set a new PIN on next login.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  await ref.read(usersProvider.notifier).resetPin(user.id);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Reset PIN'),
              ),
            ],
          ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    UsersTableData user,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete User'),
            content: Text(
              'Delete "${user.name}"? This permanently removes their account and cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () async {
                  await ref.read(usersProvider.notifier).deleteUser(user.id);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}

// ── User Card ───────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final UsersTableData user;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onResetPin;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.canManage,
    required this.onEdit,
    required this.onResetPin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleParts = [
      if (user.employeeId != null && user.employeeId!.isNotEmpty)
        user.employeeId!,
      if (user.phone != null && user.phone!.isNotEmpty) user.phone!,
    ];

    return Opacity(
      opacity: user.isActive ? 1 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            leading: _UserAvatar(user: user),
            title: Text(user.name, style: AppTextStyles.headingSm),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _RoleBadge(role: user.role),
                  if (!user.isActive)
                    Text(
                      'Inactive',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  if (subtitleParts.isNotEmpty)
                    Text(
                      subtitleParts.join(' • '),
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            trailing:
                canManage
                    ? PopupMenuButton<String>(
                      onSelected: (action) {
                        switch (action) {
                          case 'edit':
                            onEdit();
                          case 'reset_pin':
                            onResetPin();
                          case 'delete':
                            onDelete();
                        }
                      },
                      itemBuilder:
                          (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  Gap(AppSpacing.sm),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'reset_pin',
                              child: Row(
                                children: [
                                  Icon(Icons.pin_outlined, size: 18),
                                  Gap(AppSpacing.sm),
                                  Text('Reset PIN'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: AppColors.error,
                                  ),
                                  Gap(AppSpacing.sm),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                    )
                    : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final UsersTableData user;
  const _UserAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final url = user.avatarUrl;
    final isAdmin = user.role == 'admin';
    final bg =
        isAdmin
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.secondary.withValues(alpha: 0.15);

    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: bg,
        backgroundImage:
            ImageStorageService.isNetworkUrl(url)
                ? NetworkImage(url) as ImageProvider
                : FileImage(File(url)),
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: bg,
      child: Text(
        user.name.substring(0, 1).toUpperCase(),
        style: AppTextStyles.headingSm.copyWith(
          color: isAdmin ? AppColors.primary : AppColors.secondaryDark,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      'admin' => ('Admin', AppColors.primary),
      'supervisor' => ('Supervisor', AppColors.warning),
      _ => ('Cashier', AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(label, style: AppTextStyles.labelMd.copyWith(color: color)),
    );
  }
}

// ── User Form Dialog (Add / Edit) ────────────────────────────────────────────

typedef _UserFormSubmit =
    Future<void> Function(
      String name,
      String role,
      String? employeeId,
      String? phone,
      String? avatarUrl, {
      bool isActive,
    });

class _UserFormDialog extends HookWidget {
  final UsersTableData? existing;
  final _UserFormSubmit onSubmit;
  const _UserFormDialog({this.existing, required this.onSubmit});

  bool get isEditing => existing != null;

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final nameCtrl = useTextEditingController(text: existing?.name ?? '');
    final employeeIdCtrl = useTextEditingController(
      text: existing?.employeeId ?? '',
    );
    final phoneCtrl = useTextEditingController(text: existing?.phone ?? '');
    final role = useState(existing?.role ?? 'cashier');
    final isActive = useState(existing?.isActive ?? true);
    final avatarUrl = useState(existing?.avatarUrl);
    final loading = useState(false);

    Future<void> pickAvatar() async {
      final picked = await ImageStorageService.pickAndStore();
      if (picked == null) return;
      avatarUrl.value = picked;
    }

    Future<void> submit() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      loading.value = true;
      try {
        await onSubmit(
          nameCtrl.text.trim(),
          role.value,
          employeeIdCtrl.text.trim().isEmpty
              ? null
              : employeeIdCtrl.text.trim(),
          phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
          avatarUrl.value,
          isActive: isActive.value,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        loading.value = false;
      }
    }

    return AlertDialog(
      title: Text(isEditing ? 'Edit User' : 'Add User'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _AvatarThumbnail(url: avatarUrl.value),
                    const Gap(AppSpacing.md),
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          OutlinedButton.icon(
                            onPressed: pickAvatar,
                            icon: const Icon(Icons.image_outlined, size: 18),
                            label: Text(
                              avatarUrl.value == null
                                  ? 'Choose Photo'
                                  : 'Change Photo',
                            ),
                          ),
                          if (avatarUrl.value != null)
                            TextButton.icon(
                              onPressed: () => avatarUrl.value = null,
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: AppColors.error,
                              ),
                              label: const Text(
                                'Remove',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator:
                      (v) =>
                          (v?.trim().isEmpty ?? true)
                              ? 'Name is required'
                              : null,
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: employeeIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Employee ID (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const Gap(AppSpacing.md),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const Gap(AppSpacing.md),
                Text(
                  'Role',
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Gap(AppSpacing.xs),
                _RoleToggle(
                  selected: role.value,
                  onChanged: (r) => role.value = r,
                ),
                if (isEditing) ...[
                  const Gap(AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    value: isActive.value,
                    onChanged: (v) => isActive.value = v,
                  ),
                ],
                if (!isEditing) ...[
                  const Gap(AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const Gap(AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'New users start with a default PIN and will set their own on first login.',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: loading.value ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: loading.value ? null : submit,
          child:
              loading.value
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : Text(isEditing ? 'Save' : 'Add User'),
        ),
      ],
    );
  }
}

class _AvatarThumbnail extends StatelessWidget {
  final String? url;
  const _AvatarThumbnail({this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        width: 56,
        height: 56,
        color: AppColors.surfaceVariant,
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    final u = url;
    if (u == null || u.isEmpty) {
      return const Icon(Icons.person_outline, color: AppColors.textDisabled);
    }
    if (ImageStorageService.isNetworkUrl(u)) {
      return Image.network(
        u,
        fit: BoxFit.cover,
        errorBuilder:
            (context, e, st) => const Icon(
              Icons.broken_image_outlined,
              color: AppColors.textDisabled,
            ),
      );
    }
    return Image.file(
      File(u),
      fit: BoxFit.cover,
      errorBuilder:
          (context, e, st) => const Icon(
            Icons.broken_image_outlined,
            color: AppColors.textDisabled,
          ),
    );
  }
}

// ── Role Toggle ──────────────────────────────────────────────────────────────

class _RoleToggle extends StatelessWidget {
  final String selected;
  final void Function(String) onChanged;
  const _RoleToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _RoleChip(
          label: 'Cashier',
          selected: selected == 'cashier',
          onTap: () => onChanged('cashier'),
        ),
        _RoleChip(
          label: 'Supervisor',
          selected: selected == 'supervisor',
          onTap: () => onChanged('supervisor'),
        ),
        _RoleChip(
          label: 'Admin',
          selected: selected == 'admin',
          onTap: () => onChanged('admin'),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
