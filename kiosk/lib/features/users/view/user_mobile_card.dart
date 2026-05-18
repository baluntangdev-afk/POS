import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: ColorSet.primary.withValues(alpha: 0.1),
                    child: Text(
                      '${user.firstName[0]}${user.lastName[0]}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColorSet.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.firstName} ${user.lastName}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user.userId,
                          style: TextStyle(
                            fontSize: 12,
                            color: ColorSet.text.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  UserRoleBadge(isAdmin: user.systemAdmin),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.email, user.email),
              const SizedBox(height: 8),
              if (user.phone.isNotEmpty) _buildInfoRow(Icons.phone, user.phone),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(foregroundColor: ColorSet.primary),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: ColorSet.danger),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ColorSet.text.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: ColorSet.text.withValues(alpha: 0.8)),
          ),
        ),
      ],
    );
  }
}
