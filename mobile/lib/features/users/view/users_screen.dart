import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/database/app_database.dart';
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
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.read(usersProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: isAdmin
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
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const Gap(AppSpacing.md),
              Text('Failed to load users',
                  style: AppTextStyles.headingSm.copyWith(color: AppColors.error)),
              const Gap(AppSpacing.sm),
              Text(e.toString(),
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
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
                  const Icon(Icons.group_outlined, size: 64, color: AppColors.textDisabled),
                  const Gap(AppSpacing.md),
                  Text('No users yet',
                      style: AppTextStyles.headingSm.copyWith(color: AppColors.textSecondary)),
                  const Gap(AppSpacing.xs),
                  Text('Tap + to add a user',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              isAdmin ? AppSpacing.xxl + AppSpacing.lg : AppSpacing.lg,
            ),
            itemCount: users.length,
            separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
            itemBuilder: (context, index) => _UserCard(
              user: users[index],
              isAdmin: isAdmin,
              onEdit: () => _showEditUserDialog(context, ref, users[index]),
              onChangePin: () => _showChangePinDialog(context, ref, users[index]),
              onDeactivate: () => _confirmDeactivate(context, ref, users[index]),
            ),
          );
        },
      ),
    );
  }

  void _showAddUserDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _AddUserDialog(
        onAdd: (name, role, pin) async {
          await ref.read(usersProvider.notifier).addUser(
            name: name,
            role: role,
            pin: pin,
          );
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, WidgetRef ref, UsersTableData user) {
    showDialog(
      context: context,
      builder: (ctx) => _EditUserDialog(
        user: user,
        onSave: (name, role) async {
          await ref.read(usersProvider.notifier).editUser(
            id: user.id,
            name: name,
            role: role,
          );
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _showChangePinDialog(BuildContext context, WidgetRef ref, UsersTableData user) {
    showDialog(
      context: context,
      builder: (ctx) => _ChangePinDialog(
        userName: user.name,
        onChangePin: (newPin) async {
          await ref.read(usersProvider.notifier).changePin(
            userId: user.id,
            newPin: newPin,
          );
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _confirmDeactivate(BuildContext context, WidgetRef ref, UsersTableData user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate User'),
        content:
            Text('Deactivate "${user.name}"? They will no longer be able to log in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ref.read(usersProvider.notifier).deactivateUser(user.id);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }
}

// ── User Card ───────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final UsersTableData user;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onChangePin;
  final VoidCallback onDeactivate;

  const _UserCard({
    required this.user,
    required this.isAdmin,
    required this.onEdit,
    required this.onChangePin,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.role == 'admin';
    return Container(
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: isAdmin
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.secondary.withValues(alpha: 0.15),
          child: Text(
            user.name.substring(0, 1).toUpperCase(),
            style: AppTextStyles.headingSm.copyWith(
              color: isAdmin ? AppColors.primary : AppColors.secondaryDark,
            ),
          ),
        ),
        title: Text(user.name, style: AppTextStyles.headingSm),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _RoleBadge(role: user.role),
        ),
        trailing: isAdmin
            ? PopupMenuButton<String>(
                onSelected: (action) {
                  switch (action) {
                    case 'edit':
                      onEdit();
                    case 'pin':
                      onChangePin();
                    case 'deactivate':
                      onDeactivate();
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 18),
                      Gap(AppSpacing.sm),
                      Text('Edit'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'pin',
                    child: Row(children: [
                      Icon(Icons.pin_outlined, size: 18),
                      Gap(AppSpacing.sm),
                      Text('Change PIN'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'deactivate',
                    child: Row(children: [
                      Icon(Icons.person_off_outlined, size: 18, color: AppColors.error),
                      Gap(AppSpacing.sm),
                      Text('Deactivate', style: TextStyle(color: AppColors.error)),
                    ]),
                  ),
                ],
              )
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
    final isAdmin = role == 'admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: isAdmin
            ? AppColors.primary.withValues(alpha: 0.1)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'Cashier',
        style: AppTextStyles.labelMd.copyWith(
          color: isAdmin ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Add User Dialog ──────────────────────────────────────────────────────────

class _AddUserDialog extends HookWidget {
  final Future<void> Function(String name, String role, String pin) onAdd;
  const _AddUserDialog({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final nameCtrl = useTextEditingController();
    final pinCtrl = useTextEditingController();
    final confirmCtrl = useTextEditingController();
    final role = useState('cashier');
    final loading = useState(false);
    final nameError = useState<String?>(null);
    final pinError = useState<String?>(null);

    bool validate() {
      nameError.value = nameCtrl.text.trim().isEmpty ? 'Name is required' : null;
      if (pinCtrl.text.length != 6) {
        pinError.value = 'PIN must be exactly 6 digits';
      } else if (pinCtrl.text != confirmCtrl.text) {
        pinError.value = 'PINs do not match';
      } else {
        pinError.value = null;
      }
      return nameError.value == null && pinError.value == null;
    }

    Future<void> submit() async {
      if (!validate()) return;
      loading.value = true;
      try {
        await onAdd(nameCtrl.text.trim(), role.value, pinCtrl.text);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      } finally {
        loading.value = false;
      }
    }

    return AlertDialog(
      title: const Text('Add User'),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  errorText: nameError.value,
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const Gap(AppSpacing.md),
              Text('Role',
                  style: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary)),
              const Gap(AppSpacing.xs),
              _RoleToggle(selected: role.value, onChanged: (r) => role.value = r),
              const Gap(AppSpacing.md),
              TextFormField(
                controller: pinCtrl,
                decoration: InputDecoration(
                  labelText: '6-Digit PIN',
                  errorText: pinError.value,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
              ),
              const Gap(AppSpacing.sm),
              TextField(
                controller: confirmCtrl,
                decoration: const InputDecoration(
                  labelText: 'Confirm PIN',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
              ),
            ],
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
          child: loading.value
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Add User'),
        ),
      ],
    );
  }
}

// ── Edit User Dialog ─────────────────────────────────────────────────────────

class _EditUserDialog extends HookWidget {
  final UsersTableData user;
  final Future<void> Function(String name, String role) onSave;
  const _EditUserDialog({required this.user, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final nameCtrl = useTextEditingController(text: user.name);
    final role = useState(user.role);
    final loading = useState(false);
    final nameError = useState<String?>(null);

    Future<void> submit() async {
      if (nameCtrl.text.trim().isEmpty) {
        nameError.value = 'Name is required';
        return;
      }
      nameError.value = null;
      loading.value = true;
      try {
        await onSave(nameCtrl.text.trim(), role.value);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      } finally {
        loading.value = false;
      }
    }

    return AlertDialog(
      title: const Text('Edit User'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Full Name',
                errorText: nameError.value,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const Gap(AppSpacing.md),
            Text('Role',
                style: AppTextStyles.labelMd.copyWith(color: AppColors.textSecondary)),
            const Gap(AppSpacing.xs),
            _RoleToggle(selected: role.value, onChanged: (r) => role.value = r),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: loading.value ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: loading.value ? null : submit,
          child: loading.value
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ── Change PIN Dialog ────────────────────────────────────────────────────────

class _ChangePinDialog extends HookWidget {
  final String userName;
  final Future<void> Function(String newPin) onChangePin;
  const _ChangePinDialog({required this.userName, required this.onChangePin});

  @override
  Widget build(BuildContext context) {
    final pinCtrl = useTextEditingController();
    final confirmCtrl = useTextEditingController();
    final loading = useState(false);
    final pinError = useState<String?>(null);

    Future<void> submit() async {
      if (pinCtrl.text.length != 6) {
        pinError.value = 'PIN must be exactly 6 digits';
        return;
      }
      if (pinCtrl.text != confirmCtrl.text) {
        pinError.value = 'PINs do not match';
        return;
      }
      pinError.value = null;
      loading.value = true;
      try {
        await onChangePin(pinCtrl.text);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      } finally {
        loading.value = false;
      }
    }

    return AlertDialog(
      title: Text('Change PIN — $userName'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: pinCtrl,
              decoration: InputDecoration(
                labelText: 'New 6-Digit PIN',
                errorText: pinError.value,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
            ),
            const Gap(AppSpacing.md),
            TextField(
              controller: confirmCtrl,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: loading.value ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: loading.value ? null : submit,
          child: loading.value
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Update PIN'),
        ),
      ],
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
    return Row(
      children: [
        _RoleChip(
          label: 'Cashier',
          selected: selected == 'cashier',
          onTap: () => onChanged('cashier'),
        ),
        const Gap(AppSpacing.sm),
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
  const _RoleChip({required this.label, required this.selected, required this.onTap});

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
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
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
