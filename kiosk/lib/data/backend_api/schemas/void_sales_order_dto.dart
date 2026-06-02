class VoidSalesOrderDto {
  const VoidSalesOrderDto({
    required this.reason,
    required this.authorizerUserId,
    required this.authorizerPin,
  });

  final String reason;
  final String authorizerUserId;
  final String authorizerPin;

  Map<String, dynamic> toJson() => {
    'reason': reason,
    'authorizer_user_id': authorizerUserId,
    'authorizer_pin': authorizerPin,
  };
}
