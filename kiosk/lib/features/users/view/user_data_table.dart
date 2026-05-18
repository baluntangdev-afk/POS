import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../entities/user.dart';
import 'user_role_badge.dart';

class UserDataTable extends StatelessWidget {
  const UserDataTable({
    required this.users,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<User> users;
  final String sortColumn;
  final bool sortAscending;
  final ValueChanged<String> onSort;
  final ValueChanged<User> onEdit;
  final ValueChanged<User> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          context.responsive.value<double>(kiosk: 12, tablet: 10, phone: 8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox.expand(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
                          showCheckboxColumn: false,
                          headingRowColor: WidgetStateProperty.all(
                            ColorSet.primary.withValues(alpha: 0.05),
                          ),
                          columnSpacing: context.responsive.scale(20),
                          horizontalMargin: context.responsive.scale(13),
                          columns: [
                            DataColumn(
                              label: _buildDataColumn(context, 'ID', 'id').label,
                              onSort: (columnIndex, ascending) => onSort('id'),
                            ),
                            DataColumn(
                              label: _buildDataColumn(context, 'Name', 'name').label,
                              onSort: (columnIndex, ascending) => onSort('name'),
                            ),
                            DataColumn(
                              label: _buildDataColumn(context, 'Email', 'email').label,
                              onSort: (columnIndex, ascending) => onSort('email'),
                            ),
                            DataColumn(
                              label: _buildDataColumn(context, 'Phone', 'phone').label,
                              onSort: (columnIndex, ascending) => onSort('phone'),
                            ),
                            DataColumn(
                              label: _buildDataColumn(context, 'Role', 'role').label,
                              onSort: (columnIndex, ascending) => onSort('role'),
                            ),
                            DataColumn(
                              label: _buildDataColumn(context, 'Actions', 'actions').label,
                            ),
                          ],
                          rows: users.map((user) => _buildDataRow(context, user, onEdit)).toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // _buildTableFooter(),
          ],
        ),
      ),
    );
  }

  DataColumn _buildDataColumn(BuildContext context, String label, String column) {
    return DataColumn(
      label: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: ColorSet.primary,
              fontSize: context.responsive.scale(20),
            ),
          ),
          if (sortColumn == column)
            Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: context.responsive.scale(20),
              color: ColorSet.primary,
            ),
        ],
      ),
      onSort: (columnIndex, ascending) => column != 'actions' ? onSort(column) : null,
    );
  }

  DataRow _buildDataRow(BuildContext context, User user, ValueChanged<User> onTap) {
    return DataRow(
      onSelectChanged: (selected) {
        if (selected == null) return;
        onTap(user);
      },
      cells: [
        DataCell(Text(user.userId, style: TextStyle(fontSize: context.responsive.scale(16)))),
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: context.responsive.value<double>(kiosk: 20, tablet: 15, phone: 12),
                backgroundColor: ColorSet.primary.withValues(alpha: 0.1),
                child: Text(
                  '${user.firstName[0]}${user.lastName[0]}',
                  style: TextStyle(
                    fontSize: context.responsive.scale(15),
                    fontWeight: FontWeight.bold,
                    color: ColorSet.primary,
                  ),
                ),
              ),
              SizedBox(width: context.responsive.value<double>(kiosk: 8, tablet: 6, phone: 4)),
              Flexible(
                child: Text(
                  '${user.firstName} ${user.lastName}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: context.responsive.scale(16)),
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(user.email, style: TextStyle(fontSize: context.responsive.scale(16)))),
        DataCell(Text(user.phone, style: TextStyle(fontSize: context.responsive.scale(16)))),
        DataCell(UserRoleBadge(isAdmin: user.systemAdmin)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.edit,
                  size: context.responsive.value<double>(kiosk: 25, tablet: 16, phone: 14),
                ),
                onPressed: () => onEdit(user),
                tooltip: 'Edit',
                color: ColorSet.primary,
                iconSize: context.responsive.value<double>(kiosk: 18, tablet: 16, phone: 14),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  size: context.responsive.value<double>(kiosk: 25, tablet: 16, phone: 14),
                ),
                onPressed: () => onDelete(user),
                tooltip: 'Delete',
                color: ColorSet.danger,
                iconSize: context.responsive.value<double>(kiosk: 18, tablet: 16, phone: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
