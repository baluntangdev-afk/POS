import 'package:dart_mappable/dart_mappable.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../entities/user.dart';

part 'user_management_state.mapper.dart';

@MappableClass()
class UserManagementPageState with UserManagementPageStateMappable {
  const UserManagementPageState({
    required this.allUsers,
    required this.filteredUsers,
    required this.searchQuery,
    this.selectedUserType,
    this.sortColumn = 'name',
    this.sortAscending = true,
  });

  factory UserManagementPageState.initial(IList<User> users) {
    return UserManagementPageState(allUsers: users, filteredUsers: users, searchQuery: '');
  }

  final IList<User> allUsers;
  final IList<User> filteredUsers;
  final String searchQuery;
  final String? selectedUserType;
  final String sortColumn;
  final bool sortAscending;
}
