import 'dart:typed_data';

import 'package:romeu_lanches_admin/core/printing/printer_exception.dart';

/// Substituto de [WindowsRawPrinter] em plataformas sem `dart:ffi` (web):
/// não há impressoras, e imprimir avisa que só funciona no app do Windows.
abstract final class WindowsRawPrinter {
  static List<String> list() => const <String>[];

  static String? defaultPrinter() => null;

  static void send({
    required String printer,
    required String docName,
    required Uint8List bytes,
  }) {
    throw const PrinterException(
      'A impressão só está disponível no aplicativo para Windows.',
    );
  }
}
