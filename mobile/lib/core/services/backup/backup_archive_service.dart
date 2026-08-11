import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

class BackupArchiveException implements Exception {
  final String message;
  BackupArchiveException(this.message);

  @override
  String toString() => message;
}

class ExtractedBackup {
  final Map<String, List<Map<String, Object?>>> data;
  final List<File> imageFiles;

  ExtractedBackup({required this.data, required this.imageFiles});
}

abstract final class BackupArchiveService {
  static Future<File> buildArchive({
    required Map<String, List<Map<String, Object?>>> data,
    required Directory imagesDir,
    required File outputFile,
  }) async {
    final archive = Archive();
    final jsonBytes = utf8.encode(jsonEncode(data));
    archive.addFile(ArchiveFile.bytes('data.json', jsonBytes));

    if (await imagesDir.exists()) {
      await for (final entity in imagesDir.list()) {
        if (entity is File) {
          final bytes = await entity.readAsBytes();
          archive.addFile(
            ArchiveFile.bytes('product_images/${p.basename(entity.path)}', bytes),
          );
        }
      }
    }

    final zipBytes = ZipEncoder().encodeBytes(archive);
    await outputFile.writeAsBytes(zipBytes);
    return outputFile;
  }

  static Future<ExtractedBackup> extractArchive({
    required File zipFile,
    required Directory extractImagesTo,
  }) async {
    final bytes = await zipFile.readAsBytes();

    late final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw BackupArchiveException('Corrupted backup file.');
    }

    final dataEntry = archive.findFile('data.json');
    if (dataEntry == null) {
      throw BackupArchiveException('Corrupted backup file.');
    }

    late final Map<String, List<Map<String, Object?>>> data;
    try {
      final decoded = jsonDecode(utf8.decode(dataEntry.content)) as Map<String, dynamic>;
      data = decoded.map(
        (table, rows) => MapEntry(
          table,
          [for (final r in (rows as List)) Map<String, Object?>.from(r as Map)],
        ),
      );
    } catch (_) {
      throw BackupArchiveException('Corrupted backup file.');
    }

    if (!await extractImagesTo.exists()) {
      await extractImagesTo.create(recursive: true);
    }
    final imageFiles = <File>[];
    for (final entry in archive) {
      if (entry.isFile && entry.name.startsWith('product_images/')) {
        final destFile = File(p.join(extractImagesTo.path, p.basename(entry.name)));
        await destFile.writeAsBytes(entry.content);
        imageFiles.add(destFile);
      }
    }

    return ExtractedBackup(data: data, imageFiles: imageFiles);
  }
}
