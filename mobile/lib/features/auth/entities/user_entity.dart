class UserEntity {
  final int id;
  final String name;
  final String role;
  final bool isPinChanged;
  final String? employeeId;
  final String? phone;
  final String? avatarUrl;

  const UserEntity({
    required this.id,
    required this.name,
    required this.role,
    this.isPinChanged = true,
    this.employeeId,
    this.phone,
    this.avatarUrl,
  });

  bool get isAdmin => role == 'admin';
  bool get isSupervisor => role == 'supervisor';
  bool get isAdminOrSupervisor => role == 'admin' || role == 'supervisor';
}
