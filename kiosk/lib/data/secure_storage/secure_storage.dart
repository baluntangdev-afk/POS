import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    mOptions: _FixedMacOsOptions(usesDataProtectionKeychain: false),
  );
});

/// Workaround for key name mismatch in flutter_secure_storage_darwin v0.2.0.
/// Dart sends 'usesDataProtectionKeychain' but Swift expects 'useDataProtectionKeyChain'.
class _FixedMacOsOptions extends MacOsOptions {
  const _FixedMacOsOptions({super.usesDataProtectionKeychain});

  @override
  Map<String, String> toMap() => <String, String>{
    ...super.toMap(),
    'useDataProtectionKeyChain': '$usesDataProtectionKeychain',
  };
}
