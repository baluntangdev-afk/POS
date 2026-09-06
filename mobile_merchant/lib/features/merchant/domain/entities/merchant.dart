import 'package:freezed_annotation/freezed_annotation.dart';

part 'merchant.freezed.dart';

@freezed
abstract class Merchant with _$Merchant {
  const factory Merchant({
    required int id,
    required String merchantId,
    required String merchantName,
  }) = _Merchant;
}
