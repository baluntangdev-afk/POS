extension StringExtensions on String {
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  String get titleCase => split(' ').map((w) => w.capitalized).join(' ');

  bool get isBlank => trim().isEmpty;

  String? get nullIfBlank => isBlank ? null : this;
}

extension NullableStringExtensions on String? {
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;

  String orEmpty() => this ?? '';
}
