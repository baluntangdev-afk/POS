import 'package:shared_preferences/shared_preferences.dart';

/// Persists the last-used list of report-email recipients so the Email dialog
/// can pre-populate it on the next export. Not sensitive → plain
/// SharedPreferences, mirroring `PrintService`'s storage style.
abstract final class ReportEmailRecipients {
  static const _key = 'report_email_recipients';

  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? const [];
  }

  static Future<void> save(List<String> recipients) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, recipients);
  }
}
