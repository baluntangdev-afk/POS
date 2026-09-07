import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/services/notifications/order_notifications_service.dart';
import 'core/services/settings_service.dart';
import 'core/utils/app_logger.dart';

/// Shared startup path. Call after `.env` has been loaded.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await configureDependencies();

  // Warm up the runtime endpoint override before the first request.
  await getIt<SettingsService>().init();

  // Sets up the Android notification channel + asks for the runtime permission.
  await getIt<OrderNotificationsService>().initialize();

  FlutterError.onError = (details) {
    AppLogger.logError('FlutterError', details.exception, details.stack);
  };

  runApp(const ProviderScope(child: App()));
}
