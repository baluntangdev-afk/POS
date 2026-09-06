/// Pure form-field validators. Return `null` when valid, else an error string.
class Validators {
  const Validators._();

  static final RegExp _email = RegExp(r'^[\w.\-+]+@([\w\-]+\.)+[\w\-]{2,}$');

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    if (!_email.hasMatch(value.trim())) return 'Enter a valid email address.';
    return null;
  }

  static String? minLength(String? value, int length, {String field = 'This field'}) {
    if (value == null || value.length < length) {
      return '$field must be at least $length characters.';
    }
    return null;
  }
}
