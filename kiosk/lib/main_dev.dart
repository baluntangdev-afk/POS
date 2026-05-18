import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'app.dart';
import 'bootstrap.dart';
import 'config/environment/env_dev.dart';

Future<void> main() async {
  final container = await bootstrap(EnvDev());
  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
