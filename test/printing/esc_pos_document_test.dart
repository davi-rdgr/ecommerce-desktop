import 'package:flutter_test/flutter_test.dart';
import 'package:romeu_lanches_admin/core/printing/esc_pos_document.dart';
import 'package:romeu_lanches_admin/core/printing/paper_width.dart';

import 'escpos_preview.dart';

void main() {
  group('cabeçalho do fluxo', () {
    test('abre com ESC @ e seleciona o CP860 com ESC t 3', () {
      final bytes = EscPosDocument(PaperWidth.mm80).bytes;
      expect(bytes.sublist(0, 5), [0x1B, 0x40, 0x1B, 0x74, 3]);
    });
  });

  group('row', () {
    test('cola rótulo e valor nas bordas, ocupando a linha inteira', () {
      final doc = EscPosDocument(PaperWidth.mm58)..row('Subtotal', 'R\$ 49,80');
      final line = previewLines(doc.bytes).single;

      expect(line.length, 32);
      expect(line, 'Subtotal                R\$ 49,80');
    });

    test('acento não encolhe a linha', () {
      // A conta de largura roda sobre o texto sanitizado, então "ã" ocupa 1.
      final doc = EscPosDocument(PaperWidth.mm58)..row('Cartão', 'R\$ 8,00');
      expect(previewLines(doc.bytes).single.length, 32);
    });

    test('quando não cabe junto, o valor desce alinhado à direita', () {
      final doc = EscPosDocument(PaperWidth.mm58)
        ..row('2x X-Tudo Especial da Casa', 'R\$ 49,80');
      final lines = previewLines(doc.bytes);

      expect(lines, ['2x X-Tudo Especial da Casa', '                        R\$ 49,80']);
      expect(lines.last.length, 32);
    });

    test('em largura dobrada a linha vale metade das colunas', () {
      final doc = EscPosDocument(PaperWidth.mm80)
        ..size(doubleWidth: true)
        ..row('TOTAL', 'R\$ 57,80');

      expect(previewLines(doc.bytes).single.length, 24);
    });
  });

  group('text', () {
    test('quebra por palavra sem estourar a coluna', () {
      final doc = EscPosDocument(PaperWidth.mm58)
        ..text('Avenida Presidente Getúlio Vargas, 1200 - Centro');

      for (final line in previewLines(doc.bytes)) {
        expect(line.length, lessThanOrEqualTo(32));
      }
    });

    test('palavra maior que a linha é fatiada em vez de sumir', () {
      final doc = EscPosDocument(PaperWidth.mm58)..text('A' * 70);
      final lines = previewLines(doc.bytes);

      expect(lines.map((l) => l.length), [32, 32, 6]);
      expect(lines.join(), 'A' * 70);
    });

    test('emoji em observação não desalinha nem some a linha', () {
      final doc = EscPosDocument(PaperWidth.mm58)..text('bebê dormindo 🙏');
      expect(previewLines(doc.bytes).single, 'bebê dormindo ?');
    });
  });

  group('indented', () {
    test('respeita o recuo e a coluna', () {
      final doc = EscPosDocument(PaperWidth.mm58)
        ..indented('+ Cheddar cremoso extra bem generoso (R\$ 3,00)');

      for (final line in previewLines(doc.bytes)) {
        expect(line, startsWith('   '));
        expect(line.length, lessThanOrEqualTo(32));
      }
    });
  });

  group('rule', () {
    test('preenche a largura exata do papel', () {
      expect(
        previewLines((EscPosDocument(PaperWidth.mm80)..rule('=')).bytes).single,
        '=' * 48,
      );
    });
  });

  group('cut', () {
    test('termina com GS V 66 e avanço, senão a última linha fica presa', () {
      final doc = EscPosDocument(PaperWidth.mm80)..cut();
      expect(doc.bytes.sublist(doc.bytes.length - 4), [0x1D, 0x56, 66, 0x03]);
    });
  });
}
