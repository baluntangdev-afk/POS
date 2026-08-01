import 'package:dart_mappable/dart_mappable.dart';

part 'apply_discount_item_discount_dto.mapper.dart';

@MappableClass()
class ApplyDiscountItemDiscountDto with ApplyDiscountItemDiscountDtoMappable {
  const ApplyDiscountItemDiscountDto({
    required this.id,
    required this.name,
    required this.value,
    this.idNumber,
    this.beneficiaryName,
  });

  final int id;
  final String name;
  final double value;
  final String? idNumber;
  final String? beneficiaryName;

  static const fromJson = ApplyDiscountItemDiscountDtoMapper.fromJson;
}
