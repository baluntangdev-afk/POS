class UserEntity {
  final int id;
  final String name;
  final String role;

  const UserEntity({
    required this.id,
    required this.name,
    required this.role,
  });

  bool get isAdmin => role == 'admin';
}
