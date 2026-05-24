import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';

class UserTypeFilter extends StatelessWidget {
  const UserTypeFilter({required this.selectedUserType, required this.onChanged, super.key});

  final bool? selectedUserType;
  final ValueChanged<bool?> onChanged;

  String get _label {
    if (selectedUserType == null) return 'All Roles';
    return selectedUserType! ? 'Admin' : 'User';
  }

  bool get _isFiltered => selectedUserType != null;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final key = GlobalKey();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: () => _showFilterMenu(context, key),
        borderRadius: BorderRadius.circular(POSRadius.lg),
        child: Container(
          height: r.value<double>(kiosk: 48, tablet: 44, phone: 44),
          padding: EdgeInsets.symmetric(horizontal: r.scale(14)),
          decoration: BoxDecoration(
            color: _isFiltered ? ColorSet.primary.withValues(alpha: 0.08) : POSColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(POSRadius.lg),
            border: Border.all(
              color: _isFiltered ? ColorSet.primary.withValues(alpha: 0.4) : POSColors.borderDefault,
              width: _isFiltered ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: r.value<double>(kiosk: 18, tablet: 16, phone: 14),
                color: _isFiltered ? ColorSet.primary : POSColors.iconSubtle,
              ),
              SizedBox(width: r.scale(8)),
              Expanded(
                child: Text(
                  _label,
                  style: TextStyle(
                    fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
                    color: _isFiltered ? ColorSet.primary : POSColors.textSecondary,
                    fontWeight: _isFiltered ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: r.value<double>(kiosk: 18, tablet: 16, phone: 14),
                color: _isFiltered ? ColorSet.primary : POSColors.iconSubtle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showFilterMenu(BuildContext context, GlobalKey key) async {
    final renderBox = key.currentContext!.findRenderObject()! as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    if (!context.mounted) return;

    final selected = await showMenu<bool?>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4,
        offset.dx + size.width,
        offset.dy,
      ),
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.md)),
      menuPadding: const EdgeInsets.symmetric(vertical: 8),
      items: [
        _menuItem(context, null, 'All Roles', Icons.people_rounded),
        _menuItem(context, false, 'User', Icons.person_rounded),
        _menuItem(context, true, 'Admin', Icons.admin_panel_settings_rounded),
      ],
    );

    onChanged(selected);
  }

  PopupMenuItem<bool?> _menuItem(
    BuildContext context,
    bool? value,
    String label,
    IconData icon,
  ) {
    final isSelected = selectedUserType == value;
    return PopupMenuItem<bool?>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isSelected ? ColorSet.primary : POSColors.iconSubtle),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              color: isSelected ? ColorSet.primary : POSColors.textPrimary,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check_rounded, size: 16, color: ColorSet.primary),
          ],
        ],
      ),
    );
  }
}
