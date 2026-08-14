import 'package:flutter/material.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
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
    this.currentUserId,
    super.key,
  });

  final List<User> users;
  final String sortColumn;
  final bool sortAscending;
  final ValueChanged<String> onSort;
  final ValueChanged<User> onEdit;
  final ValueChanged<User> onDelete;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(POSRadius.xl),
        boxShadow: POSShadow.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(POSRadius.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTableHeader(context),
            Expanded(
              child: users.isEmpty ? _buildEmptyState(context) : _buildTable(context, r),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Container(
      height: context.responsive.value<double>(kiosk: 56, tablet: 48, phone: 44),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: ColorSet.gradientBg,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.value<double>(kiosk: 20, tablet: 16, phone: 12),
      ),
      child: Row(
        children: [
          const Icon(Icons.people_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Text(
            'Users',
            style: TextStyle(
              color: Colors.white,
              fontSize: context.responsive.value<double>(kiosk: 15, tablet: 14, phone: 13),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Text(
            '${users.length} total',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: context.responsive.value<double>(kiosk: 13, tablet: 12, phone: 11),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline_rounded, size: 48, color: POSColors.textDisabled),
          const SizedBox(height: 12),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: context.responsive.scale(16),
              color: POSColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: context.responsive.scale(13),
              color: POSColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, ResponsiveValue r) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                showCheckboxColumn: false,
                headingRowColor: WidgetStateProperty.all(POSColors.surfaceSubtle),
                headingRowHeight: r.value<double>(kiosk: 48, tablet: 44, phone: 40),
                dataRowMaxHeight: r.value<double>(kiosk: 60, tablet: 54, phone: 50),
                dataRowMinHeight: r.value<double>(kiosk: 56, tablet: 50, phone: 46),
                columnSpacing: r.scale(16),
                horizontalMargin: r.scale(16),
                dividerThickness: 1,
                columns: [
                  _sortableColumn(context, 'ID', 'id'),
                  _sortableColumn(context, 'Name', 'name'),
                  _sortableColumn(context, 'Email', 'email'),
                  _sortableColumn(context, 'Phone', 'phone'),
                  _sortableColumn(context, 'Role', 'role'),
                  _staticColumn(context, 'Actions'),
                ],
                rows: users.map((user) => _buildRow(context, user, r)).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  /// The tap is handled by [DataColumn.onSort] rather than by an [InkWell]
  /// around the label. Both would work, but nesting one inside the label breaks
  /// the table's accessibility tree: [DataTable] tags the label with
  /// `SemanticsRole.columnHeader`, and that annotation only merges into the
  /// heading's own InkWell node while the label produces no semantics node of
  /// its own. An InkWell in the label forces the columnHeader onto a separate
  /// node nested under the heading InkWell, and Flutter then asserts
  /// "A columnHeader must be a child or another cell" on every frame once a
  /// screen reader (or any UI Automation client, which the Windows touch
  /// keyboard is) turns semantics on. Letting DataTable own the tap also makes
  /// the whole heading cell the touch target instead of just the label.
  DataColumn _sortableColumn(BuildContext context, String label, String column) {
    final isSorted = sortColumn == column;
    return DataColumn(
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: context.responsive.scale(14),
                color: isSorted ? ColorSet.primary : POSColors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isSorted
                  ? (sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)
                  : Icons.unfold_more_rounded,
              size: 14,
              color: isSorted ? ColorSet.primary : POSColors.textDisabled,
            ),
          ],
        ),
      ),
      onSort: (_, _) => onSort(column),
    );
  }

  DataColumn _staticColumn(BuildContext context, String label) {
    return DataColumn(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: context.responsive.scale(14),
          color: POSColors.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, User user, ResponsiveValue r) {
    final fn = user.firstName.isNotEmpty ? user.firstName[0] : '';
    final ln = user.lastName.isNotEmpty ? user.lastName[0] : '';
    final initials = '$fn$ln'.toUpperCase();

    return DataRow(
      onSelectChanged: (selected) {
        if (selected == null) return;
        onEdit(user);
      },
      cells: [
        DataCell(
          Text(
            user.userId,
            style: TextStyle(
              fontSize: r.scale(14),
              color: POSColors.textSecondary,
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: r.value<double>(kiosk: 36, tablet: 30, phone: 26),
                height: r.value<double>(kiosk: 36, tablet: 30, phone: 26),
                decoration: BoxDecoration(
                  color: ColorSet.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(POSRadius.sm),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: r.scale(13),
                      fontWeight: FontWeight.w800,
                      color: ColorSet.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: r.scale(8)),
              Flexible(
                child: Text(
                  '${user.firstName} ${user.lastName}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: r.scale(14),
                    fontWeight: FontWeight.w600,
                    color: POSColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            user.email,
            style: TextStyle(fontSize: r.scale(14), color: POSColors.textSecondary),
          ),
        ),
        DataCell(
          Text(
            user.phone.isNotEmpty ? user.phone : '—',
            style: TextStyle(fontSize: r.scale(14), color: POSColors.textSecondary),
          ),
        ),
        DataCell(UserRoleBadge(role: user.role)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TableActionBtn(
                icon: Icons.edit_rounded,
                label: 'Edit',
                color: ColorSet.primary,
                onPressed: () => onEdit(user),
              ),
              if (user.id != currentUserId) ...[
                const SizedBox(width: 6),
                _TableActionBtn(
                  icon: Icons.delete_rounded,
                  label: 'Delete',
                  color: ColorSet.danger,
                  onPressed: () => onDelete(user),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TableActionBtn extends StatelessWidget {
  const _TableActionBtn({
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
      icon: Icon(icon, size: 13),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(POSRadius.sm)),
        minimumSize: const Size(64, 36),
      ),
    );
  }
}
