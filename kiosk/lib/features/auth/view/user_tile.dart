import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../entities/login_roster_item.dart';

class UserTile extends StatelessWidget {
  const UserTile({super.key, required this.user, required this.onTap});

  final LoginRosterItem user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final avatarSize = responsive.value<double>(phone: 56, tablet: 64, kiosk: 72);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(POSRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(POSRadius.lg),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: responsive.value<double>(phone: 16, tablet: 20, kiosk: 24),
            horizontal: responsive.value<double>(phone: 8, tablet: 10, kiosk: 12),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(POSRadius.lg),
            border: Border.all(color: POSColors.borderDefault),
            boxShadow: POSShadow.card,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Avatar(user: user, size: avatarSize),
              SizedBox(height: responsive.value<double>(phone: 10, tablet: 12, kiosk: 14)),
              Text(
                '${user.firstName} ${user.lastName.isNotEmpty ? '${user.lastName[0]}.' : ''}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: POSColors.textPrimary,
                  fontSize: responsive.value<double>(phone: 14, tablet: 15, kiosk: 16),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.size});

  final LoginRosterItem user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = user.image;

    Widget initialsCircle() => Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: ColorSet.primary, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        user.initials,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.36),
      ),
    );

    if (image == null || image.isEmpty) {
      return initialsCircle();
    }

    return ClipOval(
      child: Image.network(
        image,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => initialsCircle(),
      ),
    );
  }
}
