import 'package:dart_mappable/dart_mappable.dart';

part 'cartivo_auth_doc.mapper.dart';

@MappableClass()
class CartivoAuthDoc with CartivoAuthDocMappable {
  const CartivoAuthDoc({
    required this.token,
    required this.expiresAt,
    required this.userId,
    required this.userEmail,
    this.userName,
  });

  final String token;
  final DateTime expiresAt;
  final String userId;
  final String userEmail;
  final String? userName;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  static const fromJson = CartivoAuthDocMapper.fromJson;
}
