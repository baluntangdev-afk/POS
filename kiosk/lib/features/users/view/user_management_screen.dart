import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../styles/color_set.dart';
import '../../../styles/responsive/breakpoint.dart';
import '../../../styles/responsive/responsive_builder.dart';
import '../../../styles/responsive/responsive_value.dart';
import '../../../theme/pos_design.dart';
import '../../../widgets/android_scaffold.dart';
import '../../../widgets/message_dialog.dart';
import '../../../widgets/network_error_dialog.dart';
import '../../../widgets/top_app_bar.dart';
import '../../../widgets/windows_scaffold.dart';
import '../entities/user.dart';
import '../state/get_users_notifier.dart';
import '../state/modify_user_notifier.dart';
import '../state/user_management_page_notifier.dart';
import '../state/user_state.dart';
import 'user_data_table.dart';
import 'user_form_dialog.dart';
import 'user_mobile_card.dart';
import 'user_stats_card.dart';
import 'user_type_filter.dart';

class UserManagementScreen extends HookConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final notifier = ref.read(userManagementPageProvider.notifier);
    final searchFocusNode = useFocusNode();
    final isUsersLoadingShowing = useRef(false);
    final isModifyLoadingShowing = useRef(false);
    final isFormDialogOpen = useRef(false);

    useEffect(() {
      Future(() {
        ref.read(getUsersProvider.notifier).getUsers();
      });
      return null;
    }, []);

    useEffect(() {
      void listener() {
        notifier.updateSearchQuery(searchController.text);
      }

      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController]);

    ref.listen(getUsersProvider, (previous, next) {
      if (next.isLoading) {
        isUsersLoadingShowing.value = true;
        showDialog<void>(
          barrierDismissible: false,
          context: context,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
        return;
      }

      if (isUsersLoadingShowing.value) {
        isUsersLoadingShowing.value = false;
        Navigator.of(context, rootNavigator: true).pop();
      }

      next.whenOrNull(
        data: (results) {
          ref.read(userManagementPageProvider.notifier).setUsers(results);
        },
        error: (error, stackTrace) {
          showNetworkErrorDialog(context, error: error);
        },
      );
    });

    ref.listen(modifyUserProvider, (prev, next) {
      // While the form dialog is open it manages its own loading/error/success UX.
      // Skipping here prevents double overlays and mis-ordered navigator pops.
      if (isFormDialogOpen.value) return;

      if (next.isLoading) {
        isModifyLoadingShowing.value = true;
        showDialog<void>(
          barrierDismissible: false,
          context: context,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
        return;
      }

      if (isModifyLoadingShowing.value) {
        isModifyLoadingShowing.value = false;
        Navigator.of(context, rootNavigator: true).pop();
      }

      next.whenOrNull(
        data: (result) {
          if (result case UserSuccessGet(:final user)) {
            _showEditUserDialog(context, ref, user, isFormDialogOpen);
          }
          if (result case UserSuccessDelete(:final userId)) {
            showMessageDialog(context, message: 'User has been deleted', type: DialogType.success);
            ref.read(userManagementPageProvider.notifier).deleteUser(userId);
          }
        },
        error: (error, stackTrace) {
          showNetworkErrorDialog(context, error: error);
        },
      );
    });
    final isAndroid = context.breakpoint.isAndroid;
    final body = SizedBox.expand(
      child: Column(
        children: [
          TopAppBar(
            title: 'User Management',
            trailing: SizedBox(
              height: context.responsive.value<double>(kiosk: 44, tablet: 40, phone: 36),
              child: OutlinedButton.icon(
                onPressed: () => _showAddUserDialog(context, ref, isFormDialogOpen),
                icon: Icon(
                  Icons.person_add_rounded,
                  size: context.responsive.value<double>(kiosk: 17, tablet: 15, phone: 13),
                ),
                label: Text(
                  'Add User',
                  style: TextStyle(
                    fontSize: context.responsive.value<double>(kiosk: 14, tablet: 13, phone: 12),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.7), width: 1.5),
                  padding: EdgeInsets.symmetric(
                    horizontal: context.responsive.value<double>(kiosk: 16, tablet: 12, phone: 10),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(POSRadius.md),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ResponsiveBuilder(
              kiosk:
                  (context) => _buildDesktopLayout(context, ref, searchController, searchFocusNode),
              tablet:
                  (context) => _buildDesktopLayout(context, ref, searchController, searchFocusNode),
              phone:
                  (context) => _buildMobileLayout(context, ref, searchController, searchFocusNode),
            ),
          ),
        ],
      ),
    );
    if (isAndroid) {
      return AndroidScaffold(backgroundColor: ColorSet.background, body: body);
    }
    return WindowsScaffold(backgroundColor: ColorSet.background, body: body);
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    TextEditingController searchController,
    FocusNode searchFocusNode,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchAndFilters(context, ref, searchController, searchFocusNode),
          const SizedBox(height: 24),
          _buildStatsCards(ref),
          const SizedBox(height: 24),
          Expanded(child: _buildDesktopTable(ref, context)),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    TextEditingController searchController,
    FocusNode searchFocusNode,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildSearchBar(context, searchController, searchFocusNode),
              const SizedBox(height: 12),
              _buildMobileFilters(ref),
              const SizedBox(height: 12),
              _buildStatsCards(ref),
            ],
          ),
        ),
        Expanded(child: _buildMobileList(ref)),
      ],
    );
  }

  Widget _buildSearchAndFilters(
    BuildContext context,
    WidgetRef ref,
    TextEditingController searchController,
    FocusNode searchFocusNode,
  ) {
    final state = ref.watch(userManagementPageProvider);
    final notifier = ref.read(userManagementPageProvider.notifier);
    return Row(
      children: [
        Expanded(flex: 2, child: _buildSearchBar(context, searchController, searchFocusNode)),
        SizedBox(width: context.responsive.scale(20)),
        Expanded(
          child: UserTypeFilter(
            selectedUserType: state.selectedUserType,
            onChanged: (type) => notifier.updateUserTypeFilter(userType: type),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    TextEditingController searchController,
    FocusNode searchFocusNode,
  ) {
    final r = context.responsive;
    return TextField(
      focusNode: searchFocusNode,
      controller: searchController,
      style: TextStyle(
        fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
        color: POSColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Search by name, email, or ID...',
        hintStyle: TextStyle(
          fontSize: r.value<double>(kiosk: 14, tablet: 13, phone: 12),
          color: POSColors.textTertiary,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: POSColors.iconSubtle,
          size: r.value<double>(kiosk: 20, tablet: 18, phone: 16),
        ),
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.close_rounded, size: r.value<double>(kiosk: 18, tablet: 16, phone: 14)),
                color: POSColors.iconSubtle,
                onPressed: () => searchController.clear(),
              )
            : null,
        filled: true,
        fillColor: POSColors.surfaceSubtle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(POSRadius.lg),
          borderSide: const BorderSide(color: POSColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(POSRadius.lg),
          borderSide: const BorderSide(color: POSColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(POSRadius.lg),
          borderSide: const BorderSide(color: ColorSet.primary, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: r.value<double>(kiosk: 14, tablet: 12, phone: 10),
          horizontal: r.value<double>(kiosk: 16, tablet: 14, phone: 12),
        ),
      ),
    );
  }

  Widget _buildMobileFilters(WidgetRef ref) {
    final state = ref.watch(userManagementPageProvider);
    final notifier = ref.read(userManagementPageProvider.notifier);

    return UserTypeFilter(
      selectedUserType: state.selectedUserType,
      onChanged: (type) => notifier.updateUserTypeFilter(userType: type),
    );
  }

  Widget _buildStatsCards(WidgetRef ref) {
    final state = ref.watch(userManagementPageProvider);
    final totalUsers = state.allUsers.length;
    final adminUsers = state.allUsers.where((u) => u.systemAdmin).length;
    final regularUsers = state.allUsers.where((u) => !u.systemAdmin).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: UserStatsCard(
                label: 'Total Users',
                value: totalUsers.toString(),
                icon: Icons.people,
                color: ColorSet.primary,
                compact: context.breakpoint.isPhone,
              ),
            ),
            SizedBox(width: context.responsive.scale(20)),
            Expanded(
              child: UserStatsCard(
                label: 'Admins',
                value: adminUsers.toString(),
                icon: Icons.admin_panel_settings,
                color: ColorSet.secondary,
                compact: context.breakpoint.isPhone,
              ),
            ),
            SizedBox(width: context.responsive.scale(12)),
            Expanded(
              child: UserStatsCard(
                label: 'Users',
                value: regularUsers.toString(),
                icon: Icons.person,
                color: ColorSet.success,
                compact: context.breakpoint.isPhone,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopTable(WidgetRef ref, BuildContext context) {
    final state = ref.watch(userManagementPageProvider);
    final notifier = ref.read(userManagementPageProvider.notifier);

    return UserDataTable(
      users: state.filteredUsers.toList(),
      sortColumn: state.sortColumn,
      sortAscending: state.sortAscending,
      onSort: (column) => notifier.updateSort(column),
      onEdit: (user) => ref.read(modifyUserProvider.notifier).getUser(user),
      onDelete: (user) => _showDeleteConfirmation(context, ref, user),
    );
  }

  Widget _buildMobileList(WidgetRef ref) {
    final state = ref.watch(userManagementPageProvider);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.filteredUsers.length,
      itemBuilder: (context, index) {
        final user = state.filteredUsers[index];
        return UserMobileCard(
          user: user,
          onTap: () => ref.read(modifyUserProvider.notifier).getUser(user),
          onEdit: () => ref.read(modifyUserProvider.notifier).getUser(user),
          onDelete: () => _showDeleteConfirmation(context, ref, user),
        );
      },
    );
  }

  Future<void> _showUserDialog(
    BuildContext context,
    WidgetRef ref,
    ObjectRef<bool> isFormDialogOpen, {
    User? user,
  }) async {
    isFormDialogOpen.value = true;
    try {
      final result = await showDialog<User?>(
        context: context,
        builder: (context) => UserFormDialog(user: user),
      );
      if (result != null) {
        await ref.read(getUsersProvider.notifier).refresh();
      }
    } finally {
      isFormDialogOpen.value = false;
    }
  }

  Future<void> _showAddUserDialog(
    BuildContext context,
    WidgetRef ref,
    ObjectRef<bool> isFormDialogOpen,
  ) async {
    await _showUserDialog(context, ref, isFormDialogOpen);
  }

  Future<void> _showEditUserDialog(
    BuildContext context,
    WidgetRef ref,
    User user,
    ObjectRef<bool> isFormDialogOpen,
  ) async {
    await _showUserDialog(context, ref, isFormDialogOpen, user: user);
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, User user) {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete User'),
            content: Text('Are you sure you want to delete ${user.firstName} ${user.lastName}?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await ref.read(modifyUserProvider.notifier).deleteUser(user);
                },
                style: FilledButton.styleFrom(backgroundColor: ColorSet.danger),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
