import 'package:logger/logger.dart';

import '../config/env_config.dart';

/// App-wide logging facade. Never use `print()` — always go through this.
class AppLogger {
  const AppLogger._();

  static final Logger _logger = Logger(
    filter: _EnvFilter(),
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: true,
    ),
  );

  static void logDebug(String message) => _logger.d(message);

  static void logInfo(String message) => _logger.i(message);

  static void logWarning(String message) => _logger.w(message);

  static void logError(String context, Object error, [StackTrace? stackTrace]) =>
      _logger.e(context, error: error, stackTrace: stackTrace);
}

class _EnvFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // if (EnvConfig.enableLogging) return true;
    // Always surface warnings and errors, even with logging disabled.
    return true;
  }
}
