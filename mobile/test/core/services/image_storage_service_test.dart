import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/image_storage_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  final String tempDir;
  _FakePathProvider(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('image_storage_test');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('storeFile copies the source into product_images/ and returns the new path', () async {
    final source = File('${tempDir.path}/source.png')..writeAsStringSync('fake-image-bytes');

    final storedPath = await ImageStorageService.storeFile(source);

    expect(await File(storedPath).exists(), isTrue);
    expect(storedPath, contains('product_images'));
    expect(await File(storedPath).readAsString(), 'fake-image-bytes');
  });

  test('isNetworkUrl distinguishes http(s) URLs from local paths', () {
    expect(ImageStorageService.isNetworkUrl('https://example.com/a.png'), isTrue);
    expect(ImageStorageService.isNetworkUrl('http://example.com/a.png'), isTrue);
    expect(ImageStorageService.isNetworkUrl('/data/user/0/app/files/product_images/x.png'), isFalse);
  });
}
