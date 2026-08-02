import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class PrinterException implements Exception {
  final String message;

  const PrinterException(this.message);

  @override
  String toString() => message;
}

/// Manda bytes crus para uma impressora instalada no Windows, via spooler.
///
/// O truque é o datatype **`RAW`** no `StartDocPrinter`: com ele o spooler não
/// chama o driver para renderizar nada, só repassa os bytes ao dispositivo. É
/// assim que os comandos ESC/POS chegam intactos — negrito, página de código e
/// guilhotina. Renderizar como documento (PDF, `Canvas`) não acionaria o corte
/// e sairia lento e serrilhado em 203dpi.
///
/// Funciona igual para USB, rede ou Bluetooth: o que importa é a impressora
/// aparecer na lista de impressoras do Windows.
abstract final class WindowsRawPrinter {
  static const _enumFlags = PRINTER_ENUM_LOCAL | PRINTER_ENUM_CONNECTIONS;

  /// Impressoras instaladas na máquina, locais e de rede já mapeadas.
  static List<String> list() => using((arena) {
    final needed = arena<Uint32>();
    final returned = arena<Uint32>();

    // Primeira chamada só para descobrir o tamanho do buffer — ela falha com
    // ERROR_INSUFFICIENT_BUFFER de propósito, não é erro de verdade.
    EnumPrinters(_enumFlags, null, 4, null, 0, needed, returned);
    if (needed.value == 0) return const <String>[];

    final buffer = arena<Uint8>(needed.value);
    final result = EnumPrinters(
      _enumFlags,
      null,
      4,
      buffer,
      needed.value,
      needed,
      returned,
    );
    if (!result.value) {
      throw PrinterException(
        'Não foi possível listar as impressoras do Windows '
        '(erro ${result.error.toInt()}).',
      );
    }

    final info = buffer.cast<PRINTER_INFO_4>();
    return [
      for (var i = 0; i < returned.value; i++)
        (info + i).ref.pPrinterName.toDartString(),
    ];
  });

  /// A impressora padrão do sistema, ou `null` se não houver nenhuma.
  static String? defaultPrinter() => using((arena) {
    final length = arena<Uint32>();

    GetDefaultPrinter(null, length);
    if (length.value == 0) return null;

    final buffer = wsalloc(length.value, arena);
    if (!GetDefaultPrinter(buffer, length)) return null;

    final name = buffer.toDartString();
    return name.isEmpty ? null : name;
  });

  /// Envia [bytes] para [printer]. [docName] é o que aparece na fila de
  /// impressão do Windows.
  static void send({
    required String printer,
    required String docName,
    required Uint8List bytes,
  }) {
    if (bytes.isEmpty) return;

    using((arena) {
      final handle = arena<Pointer>();
      final opened = OpenPrinter(
        printer.toPcwstr(allocator: arena),
        handle,
        null,
      );
      if (!opened.value) {
        throw PrinterException(
          'Não foi possível abrir a impressora "$printer" '
          '(erro ${opened.error.toInt()}). Confira se ela está instalada e '
          'ligada.',
        );
      }

      final printerHandle = PRINTER_HANDLE(handle.value);

      try {
        final doc = arena<DOC_INFO_1>();
        doc.ref.pDocName = docName.toPwstr(allocator: arena);
        doc.ref.pDatatype = 'RAW'.toPwstr(allocator: arena);

        if (StartDocPrinter(printerHandle, 1, doc) == 0) {
          throw PrinterException(
            'A impressora "$printer" recusou o trabalho de impressão.',
          );
        }

        try {
          if (!StartPagePrinter(printerHandle)) {
            throw PrinterException('Falha ao iniciar a página de impressão.');
          }

          final buffer = arena<Uint8>(bytes.length);
          buffer.asTypedList(bytes.length).setAll(0, bytes);

          final written = arena<Uint32>();
          final ok = WritePrinter(
            printerHandle,
            buffer,
            bytes.length,
            written,
          );

          if (!ok || written.value != bytes.length) {
            throw PrinterException(
              'A comanda foi enviada só pela metade '
              '(${written.value} de ${bytes.length} bytes).',
            );
          }

          EndPagePrinter(printerHandle);
        } finally {
          EndDocPrinter(printerHandle);
        }
      } finally {
        ClosePrinter(printerHandle);
      }
    });
  }
}
