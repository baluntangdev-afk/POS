// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'webhook_auth_doc.dart';

class WebhookAuthDocMapper extends ClassMapperBase<WebhookAuthDoc> {
  WebhookAuthDocMapper._();

  static WebhookAuthDocMapper? _instance;
  static WebhookAuthDocMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = WebhookAuthDocMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'WebhookAuthDoc';

  static String _$merchantId(WebhookAuthDoc v) => v.merchantId;
  static const Field<WebhookAuthDoc, String> _f$merchantId = Field(
    'merchantId',
    _$merchantId,
  );
  static String _$token(WebhookAuthDoc v) => v.token;
  static const Field<WebhookAuthDoc, String> _f$token = Field('token', _$token);
  static DateTime _$expiresAt(WebhookAuthDoc v) => v.expiresAt;
  static const Field<WebhookAuthDoc, DateTime> _f$expiresAt = Field(
    'expiresAt',
    _$expiresAt,
  );

  @override
  final MappableFields<WebhookAuthDoc> fields = const {
    #merchantId: _f$merchantId,
    #token: _f$token,
    #expiresAt: _f$expiresAt,
  };

  static WebhookAuthDoc _instantiate(DecodingData data) {
    return WebhookAuthDoc(
      merchantId: data.dec(_f$merchantId),
      token: data.dec(_f$token),
      expiresAt: data.dec(_f$expiresAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static WebhookAuthDoc fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<WebhookAuthDoc>(map);
  }

  static WebhookAuthDoc fromJson(String json) {
    return ensureInitialized().decodeJson<WebhookAuthDoc>(json);
  }
}

mixin WebhookAuthDocMappable {
  String toJson() {
    return WebhookAuthDocMapper.ensureInitialized().encodeJson<WebhookAuthDoc>(
      this as WebhookAuthDoc,
    );
  }

  Map<String, dynamic> toMap() {
    return WebhookAuthDocMapper.ensureInitialized().encodeMap<WebhookAuthDoc>(
      this as WebhookAuthDoc,
    );
  }

  WebhookAuthDocCopyWith<WebhookAuthDoc, WebhookAuthDoc, WebhookAuthDoc>
  get copyWith => _WebhookAuthDocCopyWithImpl<WebhookAuthDoc, WebhookAuthDoc>(
    this as WebhookAuthDoc,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return WebhookAuthDocMapper.ensureInitialized().stringifyValue(
      this as WebhookAuthDoc,
    );
  }

  @override
  bool operator ==(Object other) {
    return WebhookAuthDocMapper.ensureInitialized().equalsValue(
      this as WebhookAuthDoc,
      other,
    );
  }

  @override
  int get hashCode {
    return WebhookAuthDocMapper.ensureInitialized().hashValue(
      this as WebhookAuthDoc,
    );
  }
}

extension WebhookAuthDocValueCopy<$R, $Out>
    on ObjectCopyWith<$R, WebhookAuthDoc, $Out> {
  WebhookAuthDocCopyWith<$R, WebhookAuthDoc, $Out> get $asWebhookAuthDoc =>
      $base.as((v, t, t2) => _WebhookAuthDocCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class WebhookAuthDocCopyWith<$R, $In extends WebhookAuthDoc, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? merchantId, String? token, DateTime? expiresAt});
  WebhookAuthDocCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _WebhookAuthDocCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, WebhookAuthDoc, $Out>
    implements WebhookAuthDocCopyWith<$R, WebhookAuthDoc, $Out> {
  _WebhookAuthDocCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<WebhookAuthDoc> $mapper =
      WebhookAuthDocMapper.ensureInitialized();
  @override
  $R call({String? merchantId, String? token, DateTime? expiresAt}) => $apply(
    FieldCopyWithData({
      if (merchantId != null) #merchantId: merchantId,
      if (token != null) #token: token,
      if (expiresAt != null) #expiresAt: expiresAt,
    }),
  );
  @override
  WebhookAuthDoc $make(CopyWithData data) => WebhookAuthDoc(
    merchantId: data.get(#merchantId, or: $value.merchantId),
    token: data.get(#token, or: $value.token),
    expiresAt: data.get(#expiresAt, or: $value.expiresAt),
  );

  @override
  WebhookAuthDocCopyWith<$R2, WebhookAuthDoc, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _WebhookAuthDocCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

