class AuthorizerDto {
  const AuthorizerDto({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  factory AuthorizerDto.fromMap(Map<String, dynamic> map) {
    return AuthorizerDto(
      id: map['id'] as int,
      userId: map['userId'] as String,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      role: map['role'] as String? ?? 'user',
    );
  }

  final int id;
  final String userId;
  final String firstName;
  final String lastName;
  final String role;

  String get fullName => '$firstName $lastName';
}
