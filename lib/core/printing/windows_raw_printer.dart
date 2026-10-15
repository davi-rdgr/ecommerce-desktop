// A impressão RAW depende de `dart:ffi` + win32, que não existem na web. Fora
// do Windows entra um stub, para o app ainda compilar no Chrome durante o
// desenvolvimento da interface.
export 'printer_exception.dart';
export 'windows_raw_printer_stub.dart'
    if (dart.library.ffi) 'windows_raw_printer_windows.dart';
