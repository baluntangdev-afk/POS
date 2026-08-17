import 'package:dart_mappable/dart_mappable.dart';

part 'cartivo_auth.mapper.dart';

@MappableClass()
class CartivoAuth with CartivoAuthMappable {
  const CartivoAuth({
    required this.id,
    required this.email,
    this.name,
    required this.tokenExpiresAt,
  });

  final String id;
  final String email;
  final String? name;
  final DateTime tokenExpiresAt;

  String get displayName => (name != null && name!.trim().isNotEmpty) ? name! : email;
}
