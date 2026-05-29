import 'package:dart_mappable/dart_mappable.dart';

import 'payment_method_entry_dto.dart';

part 'pos_terminal_dto.mapper.dart';

@MappableClass()
class PosTerminalDto with PosTerminalDtoMappable {
  const PosTerminalDto({
    required this.id,
    required this.kioskId,
    this.legalName,
    required this.address,
    required this.tinNumber,
    required this.paymentMethods,
  });

  final int id;
  final String kioskId;
  final String? legalName;
  final String address;
  final String tinNumber;
  final List<PaymentMethodEntryDto> paymentMethods;

  static const fromJson = PosTerminalDtoMapper.fromJson;
}
