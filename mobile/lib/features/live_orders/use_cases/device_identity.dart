import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../data/backend_api/schemas/register_device_request.dart';
import '../../../data/secure_storage/sources/merchant_device_storage.dart';

final deviceIdentityProvider = Provider<DeviceIdentity>((ref) {
  return DeviceIdentity(ref.watch(merchantDeviceStorageProvider));
});

class DeviceIdentity {
  DeviceIdentity(this._storage);

  final MerchantDeviceStorage _storage;

  Future<RegisterDeviceRequest> describe({required String name}) async {
    final installId = await _storage.ensureInstallId();
    final appVersion = await _appVersion();
    final platform = await _platform();

    return RegisterDeviceRequest(
      platform: platform.platform,
      installId: installId,
      name: name.trim().isEmpty ? 'POS Device' : name.trim(),
      appVersion: appVersion,
      platformVersion: platform.version,
      deviceModel: platform.model,
      platformDetails: platform.details,
    );
  }

  Future<String> _appVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version.isEmpty ? 'unknown' : info.version;
    } catch (error, stackTrace) {
      debugPrint('[DeviceIdentity] package info failed: $error\n$stackTrace');
      return 'unknown';
    }
  }

  Future<_PlatformInfo> _platform() async {
    final plugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final a = await plugin.androidInfo;
        return _PlatformInfo(
          platform: 'android',
          version: 'Android ${a.version.release}',
          model: a.model,
          details: {
            'android_id': a.id,
            'manufacturer': a.manufacturer,
            'brand': a.brand,
            'device': a.device,
            'sdk_int': a.version.sdkInt,
            'is_physical_device': a.isPhysicalDevice,
          },
        );
      }
      if (Platform.isIOS) {
        final i = await plugin.iosInfo;
        return _PlatformInfo(
          platform: 'ios',
          version: '${i.systemName} ${i.systemVersion}',
          model: i.utsname.machine,
          details: {
            'identifier_for_vendor': i.identifierForVendor,
            'model': i.model,
            'name': i.name,
            'is_physical_device': i.isPhysicalDevice,
          },
        );
      }
    } catch (error, stackTrace) {
      debugPrint('[DeviceIdentity] device info failed: $error\n$stackTrace');
    }
    return _PlatformInfo(
      platform: Platform.operatingSystem,
      version: Platform.operatingSystemVersion,
      model: 'unknown',
      details: const {},
    );
  }
}

class _PlatformInfo {
  const _PlatformInfo({
    required this.platform,
    required this.version,
    required this.model,
    required this.details,
  });

  final String platform;
  final String version;
  final String model;
  final Map<String, dynamic> details;
}
