import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';

class UserTypeFilter extends StatelessWidget {
  const UserTypeFilter({required this.selectedUserType, required this.onChanged, super.key});

  final bool? selectedUserType;
  final ValueChanged<bool?> onChanged;

  String get _label {
    if (selectedUserType == null) return 'All Roles';
    return selectedUserType! ? 'Admin' : 'User';
  }

  @override
  Widget build(BuildContext context) {
    final key = GlobalKey();

    return GestureDetector(
      key: key,
      onTap: () => _showFilterMenu(context, key),
      child: Container(
        padding: EdgeInsets.all(context.responsive.scale(17)),
        decoration: BoxDecoration(color: ColorSet.light, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Expanded(child: Text(_label)),
            const Icon(Icons.arrow_drop_down, color: ColorSet.primary),
          ],
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
        offset.dy + size.height,
        offset.dx + size.width,
        offset.dy,
      ),
      color: Colors.white,
      menuPadding: const EdgeInsets.symmetric(vertical: 10),
      items: const [
        PopupMenuItem<bool?>(child: Text('All Roles')),
        PopupMenuItem<bool?>(
          value: false,
          child: Text('User', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        PopupMenuItem<bool?>(
          value: true,
          child: Text('Admin', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );

    onChanged(selected);
  }
}
