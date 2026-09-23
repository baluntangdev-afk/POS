import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/storage/merchant_device_storage.dart';
import '../data/models/register_device_request.dart';

class DeviceIdentity {
  const DeviceIdentity(this._storage);

  final MerchantDeviceStorage _storage;

  Future<RegisterDeviceRequest> describe({String name = ''}) async {
    final installId = await _storage.ensureInstallId();
    final pkg = await _packageInfo();
    final info = await _platformInfo();

    return RegisterDeviceRequest(
      platform: info.platform,
      installId: installId,
      name: name.trim().isEmpty ? 'Merchant App' : name.trim(),
      appName: pkg.appName,
      packageName: pkg.packageName,
      appVersion: pkg.appVersion,
      platformVersion: info.version,
      deviceModel: info.model,
      platformDetails: info.details,
    );
  }

  Future<_PackageInfo> _packageInfo() async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      return _PackageInfo(
        appName: pkg.appName.isEmpty ? 'unknown' : pkg.appName,
        packageName: pkg.packageName.isEmpty ? 'unknown' : pkg.packageName,
        appVersion: pkg.version.isEmpty ? 'unknown' : pkg.version,
      );
    } catch (e, s) {
      debugPrint('[DeviceIdentity] package info failed: $e\n$s');
      return const _PackageInfo(
        appName: 'unknown',
        packageName: 'unknown',
        appVersion: 'unknown',
      );
    }
  }

  Future<_PlatformInfo> _platformInfo() async {
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
    } catch (e, s) {
      debugPrint('[DeviceIdentity] device info failed: $e\n$s');
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
  const _PackageInfo({
    required this.appName,
    required this.packageName,
    required this.appVersion,
  });

  final String appName;
  final String packageName;
  final String appVersion;
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
