// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'cartivo_auth_dto.dart';

class CartivoAuthDtoMapper extends ClassMapperBase<CartivoAuthDto> {
  CartivoAuthDtoMapper._();

  static CartivoAuthDtoMapper? _instance;
  static CartivoAuthDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = CartivoAuthDtoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'CartivoAuthDto';

  static bool _$authenticated(CartivoAuthDto v) => v.authenticated;
  static const Field<CartivoAuthDto, bool> _f$authenticated = Field(
    'authenticated',
    _$authenticated,
  );
  static String? _$accessToken(CartivoAuthDto v) => v.accessToken;
  static const Field<CartivoAuthDto, String> _f$accessToken = Field(
    'accessToken',
    _$accessToken,
    key: r'access_token',
    opt: true,
  );

  @override
  final MappableFields<CartivoAuthDto> fields = const {
    #authenticated: _f$authenticated,
    #accessToken: _f$accessToken,
  };

  static CartivoAuthDto _instantiate(DecodingData data) {
    return CartivoAuthDto(
      authenticated: data.dec(_f$authenticated),
      accessToken: data.dec(_f$accessToken),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static CartivoAuthDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<CartivoAuthDto>(map);
  }

  static CartivoAuthDto fromJson(String json) {
    return ensureInitialized().decodeJson<CartivoAuthDto>(json);
  }
}

mixin CartivoAuthDtoMappable {
  String toJson() {
    return CartivoAuthDtoMapper.ensureInitialized().encodeJson<CartivoAuthDto>(
      this as CartivoAuthDto,
    );
  }

  Map<String, dynamic> toMap() {
    return CartivoAuthDtoMapper.ensureInitialized().encodeMap<CartivoAuthDto>(
      this as CartivoAuthDto,
    );
  }

  CartivoAuthDtoCopyWith<CartivoAuthDto, CartivoAuthDto, CartivoAuthDto>
  get copyWith => _CartivoAuthDtoCopyWithImpl<CartivoAuthDto, CartivoAuthDto>(
    this as CartivoAuthDto,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return CartivoAuthDtoMapper.ensureInitialized().stringifyValue(
      this as CartivoAuthDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return CartivoAuthDtoMapper.ensureInitialized().equalsValue(
      this as CartivoAuthDto,
      other,
    );
  }

  @override
  int get hashCode {
    return CartivoAuthDtoMapper.ensureInitialized().hashValue(
      this as CartivoAuthDto,
    );
  }
}

extension CartivoAuthDtoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, CartivoAuthDto, $Out> {
  CartivoAuthDtoCopyWith<$R, CartivoAuthDto, $Out> get $asCartivoAuthDto =>
      $base.as((v, t, t2) => _CartivoAuthDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class CartivoAuthDtoCopyWith<$R, $In extends CartivoAuthDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({bool? authenticated, String? accessToken});
  CartivoAuthDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _CartivoAuthDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, CartivoAuthDto, $Out>
    implements CartivoAuthDtoCopyWith<$R, CartivoAuthDto, $Out> {
  _CartivoAuthDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<CartivoAuthDto> $mapper =
      CartivoAuthDtoMapper.ensureInitialized();
  @override
  $R call({bool? authenticated, Object? accessToken = $none}) => $apply(
    FieldCopyWithData({
      if (authenticated != null) #authenticated: authenticated,
      if (accessToken != $none) #accessToken: accessToken,
    }),
  );
  @override
  CartivoAuthDto $make(CopyWithData data) => CartivoAuthDto(
    authenticated: data.get(#authenticated, or: $value.authenticated),
    accessToken: data.get(#accessToken, or: $value.accessToken),
  );

  @override
  CartivoAuthDtoCopyWith<$R2, CartivoAuthDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _CartivoAuthDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

