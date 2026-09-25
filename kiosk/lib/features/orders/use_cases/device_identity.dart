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

/// Describes this install for `POST /devices/register`. The kiosk ships on
/// Windows (with Android as a secondary target), so those are the platforms
/// with rich details; anything else falls back to `Platform.operatingSystem`.
class DeviceIdentity {
  DeviceIdentity(this._storage);

  final MerchantDeviceStorage _storage;

  Future<RegisterDeviceRequest> describe({required String name}) async {
    final installId = await _storage.ensureInstallId();
    final packageInfo = await _packageInfo();
    final platform = await _platform();

    return RegisterDeviceRequest(
      platform: platform.platform,
      installId: installId,
      name: name.trim().isEmpty ? 'POS Kiosk' : name.trim(),
      appName: packageInfo.appName,
      packageName: packageInfo.packageName,
      appVersion: packageInfo.version,
      platformVersion: platform.version,
      deviceModel: platform.model,
      platformDetails: platform.details,
    );
  }

  Future<_PackageInfo> _packageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return _PackageInfo(
        appName: info.appName.isEmpty ? 'unknown' : info.appName,
        packageName: info.packageName.isEmpty ? 'unknown' : info.packageName,
        version: info.version.isEmpty ? 'unknown' : info.version,
      );
    } catch (error, stackTrace) {
      debugPrint('[DeviceIdentity] package info failed: $error\n$stackTrace');
      return const _PackageInfo(appName: 'unknown', packageName: 'unknown', version: 'unknown');
    }
  }

  Future<_PlatformInfo> _platform() async {
    final plugin = DeviceInfoPlugin();
    try {
      if (Platform.isWindows) {
        final w = await plugin.windowsInfo;
        return _PlatformInfo(
          platform: 'windows',
          version: '${w.productName} ${w.displayVersion}'.trim(),
          model: w.computerName,
          details: {
            'device_id': w.deviceId,
            'computer_name': w.computerName,
            'product_id': w.productId,
            'build_number': w.buildNumber,
            'edition_id': w.editionId,
            'system_memory_mb': w.systemMemoryInMegabytes,
            'number_of_cores': w.numberOfCores,
          },
        );
      }
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

class _PackageInfo {
  const _PackageInfo({required this.appName, required this.packageName, required this.version});

  final String appName;
  final String packageName;
  final String version;
}

class _PlatformInfo {
  const _PlatformInfo({required this.platform, required this.version, required this.model, required this.details});

  final String platform;
  final String version;
  final String model;
  final Map<String, dynamic> details;
}
