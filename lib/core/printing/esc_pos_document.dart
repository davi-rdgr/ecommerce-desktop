import 'dart:typed_data';

import 'package:romeu_lanches_admin/core/printing/cp860.dart';
import 'package:romeu_lanches_admin/core/printing/paper_width.dart';

enum EscPosAlign { left, center, right }

/// Monta o fluxo de bytes ESC/POS de um cupom.
///
/// Não sabe nada de pedido nem de impressora: recebe texto, devolve bytes.
/// Quem monta o conteúdo é [OrderTicket]; quem entrega é [WindowsRawPrinter].
///
/// Todo texto passa por [Cp860.sanitize] na entrada, então `length` de string
/// aqui dentro **é** a largura impressa — é o que faz o alinhamento de [row]
/// fechar na coluna certa.
class EscPosDocument {
  static const _esc = 0x1B;
  static const _gs = 0x1D;

  /// Caracteres por linha no tamanho atual — cai à metade em [doubleWidth].
  final int columns;

  final BytesBuilder _out = BytesBuilder();

  bool _doubleWidth = false;

  EscPosDocument(PaperWidth paper) : columns = paper.columns {
    // ESC @ zera negrito, tamanho e alinhamento que uma impressão anterior
    // possa ter deixado ligados; ESC t 3 escolhe o CP860 (português).
    _out.add([_esc, 0x40]);
    _out.add([_esc, 0x74, 3]);
  }

  int get _effectiveColumns => _doubleWidth ? columns ~/ 2 : columns;

  void align(EscPosAlign alignment) =>
      _out.add([_esc, 0x61, alignment.index]);

  void bold(bool on) => _out.add([_esc, 0x45, on ? 1 : 0]);

  /// `GS ! n` — os 4 bits altos multiplicam a largura, os baixos a altura.
  void size({bool doubleWidth = false, bool doubleHeight = false}) {
    _doubleWidth = doubleWidth;
    final n = (doubleWidth ? 0x10 : 0) | (doubleHeight ? 0x01 : 0);
    _out.add([_gs, 0x21, n]);
  }

  /// Uma linha de texto. Corta no limite da coluna em vez de deixar a
  /// impressora quebrar sozinha no meio da palavra.
  void text(String value) {
    for (final line in _wrap(Cp860.sanitize(value), _effectiveColumns)) {
      _writeRaw(line);
    }
  }

  /// Rótulo à esquerda, valor à direita, colados nas bordas do papel.
  ///
  /// Quando não cabem juntos, o rótulo quebra em linhas e o valor desce para a
  /// linha seguinte alinhado à direita — nunca some nem embola com o rótulo.
  void row(String left, String right) {
    final width = _effectiveColumns;
    final l = Cp860.sanitize(left);
    final r = Cp860.sanitize(right);
    final gap = width - l.length - r.length;

    if (gap >= 1) {
      _writeRaw('$l${' ' * gap}$r');
      return;
    }

    for (final line in _wrap(l, width)) {
      _writeRaw(line);
    }
    _writeRaw(r.padLeft(width));
  }

  /// Linha indentada, para adicional e observação pendurados num item.
  void indented(String value, {int by = 3}) {
    final prefix = ' ' * by;
    for (final line in _wrap(Cp860.sanitize(value), _effectiveColumns - by)) {
      _writeRaw('$prefix$line');
    }
  }

  void rule([String char = '-']) => _writeRaw(char * _effectiveColumns);

  void blank() => _writeRaw('');

  void feed(int lines) => _out.add([_esc, 0x64, lines]);

  /// `GS V 66 n` — avança o papel e aciona a guilhotina. `n` é o avanço antes
  /// do corte: sem ele a última linha fica presa dentro do mecanismo.
  void cut() => _out.add([_gs, 0x56, 66, 0x03]);

  Uint8List get bytes => _out.toBytes();

  void _writeRaw(String sanitized) {
    _out.add(Cp860.encode(sanitized));
    _out.add(const [0x0A]);
  }

  /// Quebra por palavra; palavra maior que a linha é fatiada na força.
  static List<String> _wrap(String text, int width) {
    if (width < 1) return [text];

    final lines = <String>[];

    for (final paragraph in text.split('\n')) {
      var current = '';

      for (final word in paragraph.split(' ').where((w) => w.isNotEmpty)) {
        var pending = word;

        while (pending.length > width) {
          if (current.isNotEmpty) {
            lines.add(current);
            current = '';
          }
          lines.add(pending.substring(0, width));
          pending = pending.substring(width);
        }

        if (current.isEmpty) {
          current = pending;
        } else if (current.length + 1 + pending.length <= width) {
          current = '$current $pending';
        } else {
          lines.add(current);
          current = pending;
        }
      }

      lines.add(current);
    }

    return lines;
  }
}
