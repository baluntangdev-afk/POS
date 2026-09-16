// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'transaction_sync_result_dto.dart';

class TransactionSyncResultDtoMapper
    extends ClassMapperBase<TransactionSyncResultDto> {
  TransactionSyncResultDtoMapper._();

  static TransactionSyncResultDtoMapper? _instance;
  static TransactionSyncResultDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(
        _instance = TransactionSyncResultDtoMapper._(),
      );
    }
    return _instance!;
  }

  @override
  final String id = 'TransactionSyncResultDto';

  static List<int> _$acceptedSaleIds(TransactionSyncResultDto v) =>
      v.acceptedSaleIds;
  static const Field<TransactionSyncResultDto, List<int>> _f$acceptedSaleIds =
      Field('acceptedSaleIds', _$acceptedSaleIds, key: r'accepted_sale_ids');
  static List<int> _$acceptedRefundIds(TransactionSyncResultDto v) =>
      v.acceptedRefundIds;
  static const Field<TransactionSyncResultDto, List<int>> _f$acceptedRefundIds =
      Field(
        'acceptedRefundIds',
        _$acceptedRefundIds,
        key: r'accepted_refund_ids',
      );

  @override
  final MappableFields<TransactionSyncResultDto> fields = const {
    #acceptedSaleIds: _f$acceptedSaleIds,
    #acceptedRefundIds: _f$acceptedRefundIds,
  };

  static TransactionSyncResultDto _instantiate(DecodingData data) {
    return TransactionSyncResultDto(
      acceptedSaleIds: data.dec(_f$acceptedSaleIds),
      acceptedRefundIds: data.dec(_f$acceptedRefundIds),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static TransactionSyncResultDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<TransactionSyncResultDto>(map);
  }

  static TransactionSyncResultDto fromJson(String json) {
    return ensureInitialized().decodeJson<TransactionSyncResultDto>(json);
  }
}

mixin TransactionSyncResultDtoMappable {
  String toJson() {
    return TransactionSyncResultDtoMapper.ensureInitialized()
        .encodeJson<TransactionSyncResultDto>(this as TransactionSyncResultDto);
  }

  Map<String, dynamic> toMap() {
    return TransactionSyncResultDtoMapper.ensureInitialized()
        .encodeMap<TransactionSyncResultDto>(this as TransactionSyncResultDto);
  }

  TransactionSyncResultDtoCopyWith<
    TransactionSyncResultDto,
    TransactionSyncResultDto,
    TransactionSyncResultDto
  >
  get copyWith =>
      _TransactionSyncResultDtoCopyWithImpl<
        TransactionSyncResultDto,
        TransactionSyncResultDto
      >(this as TransactionSyncResultDto, $identity, $identity);
  @override
  String toString() {
    return TransactionSyncResultDtoMapper.ensureInitialized().stringifyValue(
      this as TransactionSyncResultDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return TransactionSyncResultDtoMapper.ensureInitialized().equalsValue(
      this as TransactionSyncResultDto,
      other,
    );
  }

  @override
  int get hashCode {
    return TransactionSyncResultDtoMapper.ensureInitialized().hashValue(
      this as TransactionSyncResultDto,
    );
  }
}

extension TransactionSyncResultDtoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, TransactionSyncResultDto, $Out> {
  TransactionSyncResultDtoCopyWith<$R, TransactionSyncResultDto, $Out>
  get $asTransactionSyncResultDto => $base.as(
    (v, t, t2) => _TransactionSyncResultDtoCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class TransactionSyncResultDtoCopyWith<
  $R,
  $In extends TransactionSyncResultDto,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>> get acceptedSaleIds;
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>> get acceptedRefundIds;
  $R call({List<int>? acceptedSaleIds, List<int>? acceptedRefundIds});
  TransactionSyncResultDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _TransactionSyncResultDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, TransactionSyncResultDto, $Out>
    implements
        TransactionSyncResultDtoCopyWith<$R, TransactionSyncResultDto, $Out> {
  _TransactionSyncResultDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<TransactionSyncResultDto> $mapper =
      TransactionSyncResultDtoMapper.ensureInitialized();
  @override
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>> get acceptedSaleIds =>
      ListCopyWith(
        $value.acceptedSaleIds,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(acceptedSaleIds: v),
      );
  @override
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>> get acceptedRefundIds =>
      ListCopyWith(
        $value.acceptedRefundIds,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(acceptedRefundIds: v),
      );
  @override
  $R call({List<int>? acceptedSaleIds, List<int>? acceptedRefundIds}) => $apply(
    FieldCopyWithData({
      if (acceptedSaleIds != null) #acceptedSaleIds: acceptedSaleIds,
      if (acceptedRefundIds != null) #acceptedRefundIds: acceptedRefundIds,
    }),
  );
  @override
  TransactionSyncResultDto $make(CopyWithData data) => TransactionSyncResultDto(
    acceptedSaleIds: data.get(#acceptedSaleIds, or: $value.acceptedSaleIds),
    acceptedRefundIds: data.get(
      #acceptedRefundIds,
      or: $value.acceptedRefundIds,
    ),
  );

  @override
  TransactionSyncResultDtoCopyWith<$R2, TransactionSyncResultDto, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _TransactionSyncResultDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

