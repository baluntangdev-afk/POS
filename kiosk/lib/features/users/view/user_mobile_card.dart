import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../entities/user.dart';
import 'user_role_badge.dart';

class UserMobileCard extends StatelessWidget {
  const UserMobileCard({
    required this.user,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.canDelete = true,
    super.key,
  });

  final User user;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final fn = user.firstName.isNotEmpty ? user.firstName[0] : '';
    final ln = user.lastName.isNotEmpty ? user.lastName[0] : '';
    final initials = '$fn$ln'.toUpperCase();
    final r = context.responsive;

    return Container(
      margin: EdgeInsets.only(bottom: r.value<double>(kiosk: 16, tablet: 14, phone: 12)),
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
              padding: EdgeInsets.all(r.value<double>(kiosk: 20, tablet: 18, phone: 16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Avatar(initials: initials, size: r.value<double>(kiosk: 52, tablet: 48, phone: 44)),
                      SizedBox(width: r.value<double>(kiosk: 16, tablet: 14, phone: 12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.firstName} ${user.lastName}',
                              style: TextStyle(
                                fontSize: r.value<double>(kiosk: 18, tablet: 16, phone: 15),
                                fontWeight: FontWeight.w700,
                                color: POSColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.userId,
                              style: TextStyle(
                                fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                                color: POSColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      UserRoleBadge(role: user.role),
                    ],
                  ),
                  SizedBox(height: r.value<double>(kiosk: 16, tablet: 14, phone: 12)),
                  Container(height: 1, color: POSColors.borderSubtle),
                  SizedBox(height: r.value<double>(kiosk: 16, tablet: 14, phone: 12)),
                  _buildInfoRow(context, Icons.email_rounded, user.email),
                  if (user.phone.isNotEmpty) ...[
                    SizedBox(height: r.value<double>(kiosk: 8, tablet: 7, phone: 6)),
                    _buildInfoRow(context, Icons.phone_rounded, user.phone),
                  ],
                  SizedBox(height: r.value<double>(kiosk: 16, tablet: 14, phone: 12)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _ActionButton(
                        icon: Icons.edit_rounded,
                        label: 'Edit',
                        color: ColorSet.primary,
                        onPressed: onEdit,
                      ),
                      if (canDelete) ...[
                        SizedBox(width: r.value<double>(kiosk: 12, tablet: 10, phone: 8)),
                        _ActionButton(
                          icon: Icons.delete_rounded,
                          label: 'Delete',
                          color: ColorSet.danger,
                          onPressed: onDelete,
                        ),
                      ],
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

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    final r = context.responsive;
    return Row(
      children: [
        Icon(icon, size: r.value<double>(kiosk: 16, tablet: 15, phone: 14), color: POSColors.iconSubtle),
        SizedBox(width: r.value<double>(kiosk: 10, tablet: 9, phone: 8)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: r.value<double>(kiosk: 15, tablet: 14, phone: 13),
              color: POSColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fontSize = size * 0.34;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ColorSet.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(POSRadius.md),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: fontSize,
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
    final r = context.responsive;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: r.value<double>(kiosk: 20, tablet: 18, phone: 18)),
      label: Text(
        label,
        style: TextStyle(
          fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 13),
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: EdgeInsets.symmetric(
          horizontal: r.value<double>(kiosk: 16, tablet: 14, phone: 14),
          vertical: r.value<double>(kiosk: 12, tablet: 11, phone: 10),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.sm)),
        minimumSize: const Size(80, 44),
      ),
    );
  }
}
