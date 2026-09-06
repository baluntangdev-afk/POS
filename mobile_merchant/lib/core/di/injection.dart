import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

/// Global service locator.
///
/// Resolve dependencies with `getIt<T>()`. Riverpod notifiers must resolve
/// their dependencies at call-time inside methods, never as constructor
/// parameters (the Riverpod code-gen factory cannot pass constructor args).
final GetIt getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies({
  String environment = Environment.prod,
}) async =>
    getIt.init(environment: environment);
