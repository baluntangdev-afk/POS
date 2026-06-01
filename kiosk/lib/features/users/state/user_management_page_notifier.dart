import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../entities/user.dart';
import 'user_management_state.dart';

final userManagementPageProvider = NotifierProvider.autoDispose(
  UserManagementPageNotifier.new,
  name: 'userManagementPageProvider',
);

class UserManagementPageNotifier extends Notifier<UserManagementPageState> {
  @override
  UserManagementPageState build() {
    // Initialize with empty state and load users asynchronously
    // getUsers();
    return UserManagementPageState.initial(const IList.empty());
  }

  void setUsers(IList<User> users) {
    state = state.copyWith(allUsers: users);
    _filterAndSortUsers();
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _filterAndSortUsers();
  }

  void updateUserTypeFilter({String? userType}) {
    state = state.copyWith(selectedUserType: userType);
    _filterAndSortUsers();
  }

  void clearUserTypeFilter() {
    state = state.copyWith(selectedUserType: null);
    _filterAndSortUsers();
  }

  void updateSort(String column) {
    if (state.sortColumn == column) {
      state = state.copyWith(sortAscending: !state.sortAscending);
    } else {
      state = state.copyWith(sortColumn: column, sortAscending: true);
    }
    _filterAndSortUsers();
  }

  Future<void> createUser(User user) async {
    final updatedUsers = [...state.allUsers, user].toIList();
    state = state.copyWith(allUsers: updatedUsers);
    _filterAndSortUsers();
  }

  Future<void> updateUser(User updatedUser) async {
    final updatedUsers =
        state.allUsers.map((user) {
          return user.id == updatedUser.id ? updatedUser : user;
        }).toIList();
    state = state.copyWith(allUsers: updatedUsers);
    _filterAndSortUsers();
  }

  Future<void> deleteUser(String userId) async {
    final updatedUsers = state.allUsers.where((u) => u.id != userId).toIList();
    state = state.copyWith(allUsers: updatedUsers);
    _filterAndSortUsers();
  }

  void _filterAndSortUsers() {
    final filtered = state.allUsers
        .where((user) {
          final searchTerm = state.searchQuery.toLowerCase();
          final matchesSearch =
              searchTerm.isEmpty ||
              user.firstName.toLowerCase().contains(searchTerm) ||
              user.lastName.toLowerCase().contains(searchTerm) ||
              user.email.toLowerCase().contains(searchTerm) ||
              user.userId.toLowerCase().contains(searchTerm);

          final matchesType =
              state.selectedUserType == null || user.role == state.selectedUserType;

          return matchesSearch && matchesType;
        })
        .toIList()
        .sort((a, b) {
          int comparison;
          switch (state.sortColumn) {
            case 'name':
              comparison = '${a.firstName} ${a.lastName}'.compareTo('${b.firstName} ${b.lastName}');
            case 'email':
              comparison = a.email.compareTo(b.email);
            case 'id':
              comparison = a.userId.compareTo(b.userId);
            case 'role':
              comparison = a.role.compareTo(b.role);
            default:
              comparison = 0;
          }
          return state.sortAscending ? comparison : -comparison;
        });

    state = state.copyWith(filteredUsers: filtered);
  }
}
