import 'dart:ffi';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

typedef _EnumPrintersWNative = Int32 Function(
  Uint32 flags,
  Pointer<Utf16> name,
  Uint32 level,
  Pointer<Uint8> pPrinterEnum,
  Uint32 cbBuf,
  Pointer<Uint32> pcbNeeded,
  Pointer<Uint32> pcReturned,
);
typedef _EnumPrintersWDart = int Function(
  int flags,
  Pointer<Utf16> name,
  int level,
  Pointer<Uint8> pPrinterEnum,
  int cbBuf,
  Pointer<Uint32> pcbNeeded,
  Pointer<Uint32> pcReturned,
);

typedef _GetPrinterWNative = Int32 Function(
  IntPtr hPrinter,
  Uint32 level,
  Pointer<Uint8> pPrinter,
  Uint32 cbBuf,
  Pointer<Uint32> pcbNeeded,
);
typedef _GetPrinterWDart = int Function(
  int hPrinter,
  int level,
  Pointer<Uint8> pPrinter,
  int cbBuf,
  Pointer<Uint32> pcbNeeded,
);

typedef _OpenPrinterWNative = Int32 Function(
  Pointer<Utf16> pPrinterName,
  Pointer<IntPtr> phPrinter,
  Pointer<Void> pDefault,
);
typedef _OpenPrinterWDart = int Function(
  Pointer<Utf16> pPrinterName,
  Pointer<IntPtr> phPrinter,
  Pointer<Void> pDefault,
);

typedef _ClosePrinterNative = Int32 Function(IntPtr hPrinter);
typedef _ClosePrinterDart = int Function(int hPrinter);

typedef _StartDocPrinterWNative = Uint32 Function(
  IntPtr hPrinter,
  Uint32 level,
  Pointer<Uint8> pDocInfo,
);
typedef _StartDocPrinterWDart = int Function(
  int hPrinter,
  int level,
  Pointer<Uint8> pDocInfo,
);

typedef _EndDocPrinterNative = Int32 Function(IntPtr hPrinter);
typedef _EndDocPrinterDart = int Function(int hPrinter);

typedef _StartPagePrinterNative = Int32 Function(IntPtr hPrinter);
typedef _StartPagePrinterDart = int Function(int hPrinter);

typedef _EndPagePrinterNative = Int32 Function(IntPtr hPrinter);
typedef _EndPagePrinterDart = int Function(int hPrinter);

typedef _WritePrinterNative = Int32 Function(
  IntPtr hPrinter,
  Pointer<Void> pBuf,
  Uint32 cbBuf,
  Pointer<Uint32> pcbWritten,
);
typedef _WritePrinterDart = int Function(
  int hPrinter,
  Pointer<Void> pBuf,
  int cbBuf,
  Pointer<Uint32> pcbWritten,
);

typedef _GetLastErrorNative = Uint32 Function();
typedef _GetLastErrorDart = int Function();

final class PRINTER_INFO_5 extends Struct {
  external Pointer<Utf16> pPrinterName;
  external Pointer<Utf16> pPortName;
  @Uint32()
  external int Attributes;
  @Uint32()
  external int DeviceNotSelectedTimeout;
  @Uint32()
  external int TransmissionRetryTimeout;
}

final class PRINTER_INFO_6 extends Struct {
  @Uint32()
  external int dwStatus;
}

final class DOC_INFO_1 extends Struct {
  external Pointer<Utf16> pDocName;
  external Pointer<Utf16> pOutputFile;
  external Pointer<Utf16> pDatatype;
}

class WindowsRawPrinter {
  static const int _statusPaused = 0x00000001;
  static const int _statusError = 0x00000002;
  static const int _statusPendingDeletion = 0x00000004;
  static const int _statusPaperJam = 0x00000008;
  static const int _statusPaperOut = 0x00000010;
  static const int _statusManualFeed = 0x00000020;
  static const int _statusPaperProblem = 0x00000040;
  static const int _statusOffline = 0x00000080;
  static const int _statusIoActive = 0x00000100;
  static const int _statusBusy = 0x00000200;
  static const int _statusPrinting = 0x00000400;
  static const int _statusOutputBinFull = 0x00000800;
  static const int _statusNotAvailable = 0x00001000;
  static const int _statusWaiting = 0x00002000;
  static const int _statusProcessing = 0x00004000;
  static const int _statusInitializing = 0x00008000;
  static const int _statusWarmingUp = 0x00010000;
  static const int _statusTonerLow = 0x00020000;
  static const int _statusNoToner = 0x00040000;
  static const int _statusPagePunt = 0x00080000;
  static const int _statusUserIntervention = 0x00100000;
  static const int _statusOutOfMemory = 0x00200000;
  static const int _statusDoorOpen = 0x00400000;
  static const int _statusServerUnknown = 0x00800000;
  static const int _statusPowerSave = 0x01000000;
  static const int _statusDriverUpdateNeeded = 0x02000000;

  static List<Map<String, String>> listPrinters() {
    if (!Platform.isWindows) {
      return [];
    }

    final winspool = DynamicLibrary.open('winspool.drv');
    final enumPrinters =
        winspool.lookupFunction<_EnumPrintersWNative, _EnumPrintersWDart>(
      'EnumPrintersW',
    );

    const int flags = 2 | 4; // PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS
    const int level = 5; // PRINTER_INFO_5 (includes port name)

    final needed = calloc<Uint32>();
    final returned = calloc<Uint32>();
    Pointer<Uint8>? buffer;

    try {
      enumPrinters(flags, nullptr, level, nullptr, 0, needed, returned);
      final size = needed.value;
      if (size == 0) {
        return [];
      }

      buffer = calloc<Uint8>(size);
      final success =
          enumPrinters(flags, nullptr, level, buffer, size, needed, returned);
      if (success == 0) {
        return [];
      }

      final printers = <Map<String, String>>[];
      final infoPtr = buffer.cast<PRINTER_INFO_5>();
      for (var i = 0; i < returned.value; i++) {
        final info = infoPtr.elementAt(i).ref;
        final namePtr = info.pPrinterName;
        final portPtr = info.pPortName;
        final name = namePtr == nullptr ? '' : namePtr.toDartString();
        final port = portPtr == nullptr ? '' : portPtr.toDartString();
        if (name.trim().isEmpty) continue;
        printers.add({
          'name': name,
          'port': port,
        });
      }

      return printers;
    } finally {
      if (buffer != null) {
        calloc.free(buffer!);
      }
      calloc.free(needed);
      calloc.free(returned);
    }
  }

  static String? getPrinterPort(String printerName) {
    if (!Platform.isWindows) return null;
    final normalized = printerName.trim().toLowerCase();
    for (final printer in listPrinters()) {
      final name = (printer['name'] ?? '').trim().toLowerCase();
      if (name == normalized) {
        return printer['port'];
      }
    }
    return null;
  }

  static String? findPrinterNameByPort(String portName) {
    if (!Platform.isWindows) return null;
    final normalized = portName.trim().toLowerCase();
    for (final printer in listPrinters()) {
      final port = (printer['port'] ?? '').trim().toLowerCase();
      if (port == normalized) {
        return printer['name'];
      }
    }
    return null;
  }

  static int? getPrinterStatusFlags(String printerName) {
    if (!Platform.isWindows) {
      return null;
    }

    final winspool = DynamicLibrary.open('winspool.drv');
    final openPrinter = winspool.lookupFunction<_OpenPrinterWNative, _OpenPrinterWDart>('OpenPrinterW');
    final closePrinter = winspool.lookupFunction<_ClosePrinterNative, _ClosePrinterDart>('ClosePrinter');
    final getPrinter = winspool.lookupFunction<_GetPrinterWNative, _GetPrinterWDart>('GetPrinterW');

    final printerNamePtr = printerName.toNativeUtf16();
    final hPrinter = calloc<IntPtr>();
    final needed = calloc<Uint32>();
    Pointer<Uint8>? buffer;

    try {
      if (openPrinter(printerNamePtr, hPrinter, nullptr) == 0) {
        return null;
      }

      getPrinter(hPrinter.value, 6, nullptr, 0, needed);
      if (needed.value == 0) {
        return null;
      }

      buffer = calloc<Uint8>(needed.value);
      final success = getPrinter(hPrinter.value, 6, buffer, needed.value, needed);
      if (success == 0) {
        return null;
      }

      final info = buffer.cast<PRINTER_INFO_6>().ref;
      return info.dwStatus;
    } finally {
      try {
        if (hPrinter.value != 0) {
          closePrinter(hPrinter.value);
        }
      } catch (_) {}
      if (buffer != null) {
        calloc.free(buffer!);
      }
      calloc.free(needed);
      calloc.free(hPrinter);
      calloc.free(printerNamePtr);
    }
  }

  static List<String> describeStatusProblems(int statusFlags) {
    final issues = <String>[];
    if ((statusFlags & _statusOffline) != 0) {
      issues.add('OFFLINE');
    }
    if ((statusFlags & _statusPaperOut) != 0) {
      issues.add('PAPER_OUT');
    }
    if ((statusFlags & _statusPaperJam) != 0) {
      issues.add('PAPER_JAM');
    }
    if ((statusFlags & _statusPaperProblem) != 0) {
      issues.add('PAPER_PROBLEM');
    }
    if ((statusFlags & _statusDoorOpen) != 0) {
      issues.add('DOOR_OPEN');
    }
    if ((statusFlags & _statusNoToner) != 0) {
      issues.add('NO_TONER');
    }
    if ((statusFlags & _statusTonerLow) != 0) {
      issues.add('TONER_LOW');
    }
    if ((statusFlags & _statusManualFeed) != 0) {
      issues.add('MANUAL_FEED');
    }
    if ((statusFlags & _statusOutputBinFull) != 0) {
      issues.add('OUTPUT_BIN_FULL');
    }
    if ((statusFlags & _statusUserIntervention) != 0) {
      issues.add('USER_INTERVENTION');
    }
    if ((statusFlags & _statusNotAvailable) != 0) {
      issues.add('NOT_AVAILABLE');
    }
    if ((statusFlags & _statusError) != 0) {
      issues.add('ERROR');
    }
    if ((statusFlags & _statusOutOfMemory) != 0) {
      issues.add('OUT_OF_MEMORY');
    }
    if ((statusFlags & _statusPaused) != 0) {
      issues.add('PAUSED');
    }
    if ((statusFlags & _statusDriverUpdateNeeded) != 0) {
      issues.add('DRIVER_UPDATE_NEEDED');
    }
    if ((statusFlags & _statusServerUnknown) != 0) {
      issues.add('SERVER_UNKNOWN');
    }
    return issues;
  }

  static void printBytes(String printerName, Uint8List bytes, {String? jobName}) {
    if (!Platform.isWindows) {
      throw UnsupportedError('Windows raw printing is only supported on Windows.');
    }

    final winspool = DynamicLibrary.open('winspool.drv');
    final kernel32 = DynamicLibrary.open('kernel32.dll');

    final openPrinter = winspool.lookupFunction<_OpenPrinterWNative, _OpenPrinterWDart>('OpenPrinterW');
    final closePrinter = winspool.lookupFunction<_ClosePrinterNative, _ClosePrinterDart>('ClosePrinter');
    final startDocPrinter = winspool.lookupFunction<_StartDocPrinterWNative, _StartDocPrinterWDart>('StartDocPrinterW');
    final endDocPrinter = winspool.lookupFunction<_EndDocPrinterNative, _EndDocPrinterDart>('EndDocPrinter');
    final startPagePrinter = winspool.lookupFunction<_StartPagePrinterNative, _StartPagePrinterDart>('StartPagePrinter');
    final endPagePrinter = winspool.lookupFunction<_EndPagePrinterNative, _EndPagePrinterDart>('EndPagePrinter');
    final writePrinter = winspool.lookupFunction<_WritePrinterNative, _WritePrinterDart>('WritePrinter');
    final getLastError = kernel32.lookupFunction<_GetLastErrorNative, _GetLastErrorDart>('GetLastError');

    final printerNamePtr = printerName.toNativeUtf16();
    final jobNamePtr = (jobName ?? 'Tawsil POS').toNativeUtf16();
    final dataTypePtr = 'RAW'.toNativeUtf16();
    final hPrinter = calloc<IntPtr>();
    final docInfo = calloc<DOC_INFO_1>();
    final bytesWritten = calloc<Uint32>();
    Pointer<Uint8>? dataPtr;

    try {
      if (openPrinter(printerNamePtr, hPrinter, nullptr) == 0) {
        throw Exception('OpenPrinter failed: ${getLastError()}');
      }

      docInfo.ref.pDocName = jobNamePtr;
      docInfo.ref.pOutputFile = nullptr;
      docInfo.ref.pDatatype = dataTypePtr;

      final jobId = startDocPrinter(hPrinter.value, 1, docInfo.cast<Uint8>());
      if (jobId == 0) {
        throw Exception('StartDocPrinter failed: ${getLastError()}');
      }

      if (startPagePrinter(hPrinter.value) == 0) {
        throw Exception('StartPagePrinter failed: ${getLastError()}');
      }

      dataPtr = calloc<Uint8>(bytes.length);
      dataPtr.asTypedList(bytes.length).setAll(0, bytes);

      if (writePrinter(hPrinter.value, dataPtr.cast<Void>(), bytes.length, bytesWritten) == 0) {
        throw Exception('WritePrinter failed: ${getLastError()}');
      }

      endPagePrinter(hPrinter.value);
      endDocPrinter(hPrinter.value);
    } finally {
      try {
        if (hPrinter.value != 0) {
          closePrinter(hPrinter.value);
        }
      } catch (_) {}
      if (dataPtr != null) {
        calloc.free(dataPtr!);
      }
      calloc.free(printerNamePtr);
      calloc.free(jobNamePtr);
      calloc.free(dataTypePtr);
      calloc.free(docInfo);
      calloc.free(hPrinter);
      calloc.free(bytesWritten);
    }
  }
}
