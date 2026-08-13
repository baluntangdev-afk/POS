enum ReplenishmentOrderStatus {
  pending,
  paid,
  cancelled,
  unknown;

  static ReplenishmentOrderStatus fromValue(String value) {
    return ReplenishmentOrderStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ReplenishmentOrderStatus.unknown,
    );
  }
}
