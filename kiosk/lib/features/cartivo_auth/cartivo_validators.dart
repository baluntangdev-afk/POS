class CartivoValidators {
  const CartivoValidators._();

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Email is required.';
    if (!_emailRegex.hasMatch(trimmed)) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }

  static String? confirmPassword(String value, String password) {
    if (value.isEmpty) return 'Please confirm your password.';
    if (value != password) return 'Passwords do not match.';
    return null;
  }
}
