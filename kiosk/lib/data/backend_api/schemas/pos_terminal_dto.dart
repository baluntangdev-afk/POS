import 'package:dart_mappable/dart_mappable.dart';

part 'pos_terminal_dto.mapper.dart';

@MappableClass()
class PosTerminalDto with PosTerminalDtoMappable {
  const PosTerminalDto({
    required this.id,
    required this.kioskId,
    this.legalName,
    required this.address,
    required this.tinNumber,
    required this.paymentMethod,
    this.paymentNumber,
  });

  final int id;
  final String kioskId;
  final String? legalName;
  final String address;
  final String tinNumber;
  final String paymentMethod;
  final String? paymentNumber;

  static const fromJson = PosTerminalDtoMapper.fromJson;
}
