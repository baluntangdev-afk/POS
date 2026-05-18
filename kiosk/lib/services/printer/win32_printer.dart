import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:win32/win32.dart';

final win32PrinterTransportProvider = Provider<Win32PrinterTransport>((ref) {
  return Win32PrinterTransport();
});

class Win32PrinterTransport {
  Future<String?> get defaultPrinterName async {
    return using((arena) {
      final bufferSize = arena<DWORD>();

      GetDefaultPrinter(nullptr, bufferSize);

      if (bufferSize.value == 0) return null;

      final buffer = arena<Uint16>(bufferSize.value).cast<Utf16>();

      final result = GetDefaultPrinter(buffer, bufferSize);
      if (result != 0) {
        return buffer.toDartString();
      }
      return null;
    });
  }

  Future<void> sendData(
    Uint8List data, {
    String? printerName,
    String jobTitle = 'Untitled Document',
  }) async {
    final effectivePrinterName = printerName ?? await defaultPrinterName;

    if (effectivePrinterName == null) {
      throw Win32PrinterException('No default printer found and no printer name specified.');
    }

    await _dispatchToSpooler(printerName: effectivePrinterName, jobTitle: jobTitle, data: data);
  }

  Future<void> _dispatchToSpooler({
    required String printerName,
    required String jobTitle,
    required Uint8List data,
  }) async {
    await using((arena) async {
      final pPrinterName = printerName.toNativeUtf16(allocator: arena);
      final phPrinter = arena<HANDLE>();
      final pDocInfo = arena<DOC_INFO_1>();
      final bytesWritten = arena<DWORD>();

      if (OpenPrinter(pPrinterName, phPrinter, nullptr) == 0) {
        throw Win32PrinterException.fromGetLastError('Failed to open printer');
      }

      try {
        pDocInfo.ref.pDocName = jobTitle.toNativeUtf16(allocator: arena);
        pDocInfo.ref.pDatatype = 'RAW'.toNativeUtf16(allocator: arena);
        pDocInfo.ref.pOutputFile = nullptr;

        if (StartDocPrinter(phPrinter.value, 1, pDocInfo) == 0) {
          throw Win32PrinterException.fromGetLastError('Failed to start document');
        }

        try {
          if (StartPagePrinter(phPrinter.value) == 0) {
            throw Win32PrinterException.fromGetLastError('Failed to start page');
          }

          try {
            final pData = arena<Uint8>(data.length);
            final nativeList = pData.asTypedList(data.length);
            nativeList.setAll(0, data);

            final result = WritePrinter(
              phPrinter.value,
              pData.cast<Void>(),
              data.length,
              bytesWritten,
            );

            if (result == 0) {
              throw Win32PrinterException.fromGetLastError('Failed to write bytes');
            }
          } finally {
            EndPagePrinter(phPrinter.value);
          }
        } finally {
          EndDocPrinter(phPrinter.value);
        }
      } finally {
        ClosePrinter(phPrinter.value);
      }
    });
  }
}

class Win32PrinterException implements Exception {
  Win32PrinterException(this.message, [this.errorCode]);

  factory Win32PrinterException.fromGetLastError(String prefix) {
    final code = GetLastError();
    return Win32PrinterException('$prefix. Win32 Error: $code', code);
  }

  final String message;
  final int? errorCode;

  @override
  String toString() => 'PrinterException: $message';
}
