import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract final class ImageStorageService {
  static Future<String?> pickAndStore() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null) return null;
    return storeFile(File(path));
  }

  static Future<String> storeFile(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, 'product_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final ext = p.extension(source.path);
    final fileName = '${DateTime.now().microsecondsSinceEpoch}$ext';
    final destPath = p.join(imagesDir.path, fileName);
    await source.copy(destPath);
    return destPath;
  }

  static bool isNetworkUrl(String imageUrl) =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
}
