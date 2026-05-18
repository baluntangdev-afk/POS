import 'package:dart_mappable/dart_mappable.dart';

part 'auth_doc.mapper.dart';

@MappableClass()
class AuthDoc with AuthDocMappable {
  const AuthDoc({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  static const fromJson = AuthDocMapper.fromJson;
}
