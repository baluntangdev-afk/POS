enum CartivoOrderStatus {
  pending,
  paid,
  cancelled,
  unknown;

  static CartivoOrderStatus fromValue(String value) {
    return CartivoOrderStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => CartivoOrderStatus.unknown,
    );
  }
}
