import 'dart:typed_data';

import 'package:romeu_lanches_admin/core/printing/cp860.dart';

/// Descarta os comandos ESC/POS e devolve as linhas de texto do cupom.
///
/// É o "olho" dos testes de layout: o que sobra aqui é exatamente o que sai
/// impresso no papel, coluna por coluna.
List<String> previewLines(Uint8List bytes) {
  final reverse = <int, String>{};
  for (var code = 0x20; code <= 0x7E; code++) {
    reverse[code] = String.fromCharCode(code);
  }
  for (final char in _accents) {
    reverse[Cp860.encode(char).single] = char;
  }

  final out = StringBuffer();

  for (var i = 0; i < bytes.length; i++) {
    final byte = bytes[i];

    if (byte == 0x1B) {
      // ESC @ não tem argumento; ESC t/a/E/d têm um.
      i += bytes[i + 1] == 0x40 ? 1 : 2;
      continue;
    }
    if (byte == 0x1D) {
      // GS V (corte) tem 2 argumentos; GS ! (tamanho) tem 1.
      i += bytes[i + 1] == 0x56 ? 3 : 2;
      continue;
    }
    if (byte == 0x0A) {
      out.write('\n');
      continue;
    }

    out.write(reverse[byte] ?? '¿');
  }

  final text = out.toString();
  return text.endsWith('\n')
      ? text.substring(0, text.length - 1).split('\n')
      : text.split('\n');
}

const _accents = [
  'á', 'à', 'ã', 'â', 'é', 'ê', 'í', 'ó', 'õ', 'ô', 'ú', 'ü', 'ç', //
  'Á', 'À', 'Ã', 'Â', 'É', 'Ê', 'Í', 'Ó', 'Õ', 'Ô', 'Ú', 'Ü', 'Ç',
];
