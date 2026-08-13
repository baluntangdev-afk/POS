import 'package:dart_mappable/dart_mappable.dart';

import 'replenishment_order_dto.dart';
import 'replenishment_payment_dto.dart';

part 'replenishment_pay_order_response_dto.mapper.dart';

@MappableClass()
class ReplenishmentPayOrderResponseDto with ReplenishmentPayOrderResponseDtoMappable {
  const ReplenishmentPayOrderResponseDto({required this.order, required this.payment});

  final ReplenishmentOrderDto order;
  final ReplenishmentPaymentDto payment;

  static const fromJson = ReplenishmentPayOrderResponseDtoMapper.fromJson;
  static const fromMap = ReplenishmentPayOrderResponseDtoMapper.fromMap;
}
