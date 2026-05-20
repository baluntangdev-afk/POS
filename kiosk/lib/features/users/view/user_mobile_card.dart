import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../theme/pos_design.dart';
import '../entities/user.dart';
import 'user_role_badge.dart';

class UserMobileCard extends StatelessWidget {
  const UserMobileCard({
    required this.user,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final User user;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final initials = '${user.firstName[0]}${user.lastName[0]}'.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(POSRadius.xl),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Avatar(initials: initials),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.firstName} ${user.lastName}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: POSColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.userId,
                              style: const TextStyle(
                                fontSize: 12,
                                color: POSColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      UserRoleBadge(isAdmin: user.systemAdmin),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: POSColors.borderSubtle),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.email_rounded, user.email),
                  if (user.phone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildInfoRow(Icons.phone_rounded, user.phone),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _ActionButton(
                        icon: Icons.edit_rounded,
                        label: 'Edit',
                        color: ColorSet.primary,
                        onPressed: onEdit,
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.delete_rounded,
                        label: 'Delete',
                        color: ColorSet.danger,
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: POSColors.iconSubtle),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: POSColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: ColorSet.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(POSRadius.md),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: ColorSet.primary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.sm)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
      ),
    );
  }
}
