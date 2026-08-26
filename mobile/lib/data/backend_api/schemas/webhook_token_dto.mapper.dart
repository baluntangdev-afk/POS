// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'webhook_token_dto.dart';

class WebhookTokenDtoMapper extends ClassMapperBase<WebhookTokenDto> {
  WebhookTokenDtoMapper._();

  static WebhookTokenDtoMapper? _instance;
  static WebhookTokenDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = WebhookTokenDtoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'WebhookTokenDto';

  static String _$merchantId(WebhookTokenDto v) => v.merchantId;
  static const Field<WebhookTokenDto, String> _f$merchantId = Field(
    'merchantId',
    _$merchantId,
    key: r'merchant_id',
  );
  static String _$token(WebhookTokenDto v) => v.token;
  static const Field<WebhookTokenDto, String> _f$token = Field(
    'token',
    _$token,
  );
  static int _$exp(WebhookTokenDto v) => v.exp;
  static const Field<WebhookTokenDto, int> _f$exp = Field('exp', _$exp);

  @override
  final MappableFields<WebhookTokenDto> fields = const {
    #merchantId: _f$merchantId,
    #token: _f$token,
    #exp: _f$exp,
  };

  static WebhookTokenDto _instantiate(DecodingData data) {
    return WebhookTokenDto(
      merchantId: data.dec(_f$merchantId),
      token: data.dec(_f$token),
      exp: data.dec(_f$exp),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static WebhookTokenDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<WebhookTokenDto>(map);
  }

  static WebhookTokenDto fromJson(String json) {
    return ensureInitialized().decodeJson<WebhookTokenDto>(json);
  }
}

mixin WebhookTokenDtoMappable {
  String toJson() {
    return WebhookTokenDtoMapper.ensureInitialized()
        .encodeJson<WebhookTokenDto>(this as WebhookTokenDto);
  }

  Map<String, dynamic> toMap() {
    return WebhookTokenDtoMapper.ensureInitialized().encodeMap<WebhookTokenDto>(
      this as WebhookTokenDto,
    );
  }

  WebhookTokenDtoCopyWith<WebhookTokenDto, WebhookTokenDto, WebhookTokenDto>
  get copyWith =>
      _WebhookTokenDtoCopyWithImpl<WebhookTokenDto, WebhookTokenDto>(
        this as WebhookTokenDto,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return WebhookTokenDtoMapper.ensureInitialized().stringifyValue(
      this as WebhookTokenDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return WebhookTokenDtoMapper.ensureInitialized().equalsValue(
      this as WebhookTokenDto,
      other,
    );
  }

  @override
  int get hashCode {
    return WebhookTokenDtoMapper.ensureInitialized().hashValue(
      this as WebhookTokenDto,
    );
  }
}

extension WebhookTokenDtoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, WebhookTokenDto, $Out> {
  WebhookTokenDtoCopyWith<$R, WebhookTokenDto, $Out> get $asWebhookTokenDto =>
      $base.as((v, t, t2) => _WebhookTokenDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class WebhookTokenDtoCopyWith<$R, $In extends WebhookTokenDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? merchantId, String? token, int? exp});
  WebhookTokenDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _WebhookTokenDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, WebhookTokenDto, $Out>
    implements WebhookTokenDtoCopyWith<$R, WebhookTokenDto, $Out> {
  _WebhookTokenDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<WebhookTokenDto> $mapper =
      WebhookTokenDtoMapper.ensureInitialized();
  @override
  $R call({String? merchantId, String? token, int? exp}) => $apply(
    FieldCopyWithData({
      if (merchantId != null) #merchantId: merchantId,
      if (token != null) #token: token,
      if (exp != null) #exp: exp,
    }),
  );
  @override
  WebhookTokenDto $make(CopyWithData data) => WebhookTokenDto(
    merchantId: data.get(#merchantId, or: $value.merchantId),
    token: data.get(#token, or: $value.token),
    exp: data.get(#exp, or: $value.exp),
  );

  @override
  WebhookTokenDtoCopyWith<$R2, WebhookTokenDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _WebhookTokenDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

