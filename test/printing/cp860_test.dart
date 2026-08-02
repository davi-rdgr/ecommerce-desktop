import 'package:flutter_test/flutter_test.dart';
import 'package:romeu_lanches_admin/core/printing/cp860.dart';

void main() {
  group('sanitize', () {
    test('mantém ASCII imprimível intacto', () {
      expect(Cp860.sanitize('X-Tudo 2x R\$ 49,80'), 'X-Tudo 2x R\$ 49,80');
    });

    test('mantém acento do português', () {
      expect(Cp860.sanitize('Cartão açúcar coração'), 'Cartão açúcar coração');
    });

    test('emoji vira um único caractere, não dois', () {
      // É o ponto todo do sanitize: 🙏 é um par surrogate (2 code units).
      // Se escapasse assim, a conta de largura da coluna erraria por um.
      const emoji = '🙏';
      expect(emoji.length, 2);
      expect(Cp860.sanitize('ok $emoji').length, 'ok ?'.length);
    });

    test('pontuação de celular cai para ASCII em vez de virar ?', () {
      expect(Cp860.sanitize('não — “urgente”…'), 'não - "urgente"...');
    });

    test('quebra de linha e tabulação viram espaço', () {
      expect(Cp860.sanitize('a\nb\tc\r\nd'), 'a b c  d');
    });

    test('resultado tem sempre 1 code unit por byte impresso', () {
      const messy = 'Pão 🍔 — “x” \n açaí ß 你好';
      final clean = Cp860.sanitize(messy);
      expect(Cp860.encode(clean).length, clean.length);
    });
  });

  group('encode', () {
    test('ASCII vira o próprio code point', () {
      expect(Cp860.encode('AZ az 09'), 'AZ az 09'.codeUnits);
    });

    test('acentos viram os bytes da página CP860', () {
      // Sem isso "Cartão" sai como "CartÃ£o" no cupom.
      expect(Cp860.encode(Cp860.sanitize('ã')), [0x84]);
      expect(Cp860.encode(Cp860.sanitize('ç')), [0x87]);
      expect(Cp860.encode(Cp860.sanitize('é')), [0x82]);
      expect(Cp860.encode(Cp860.sanitize('á')), [0xA0]);
      expect(Cp860.encode(Cp860.sanitize('ú')), [0xA3]);
      expect(Cp860.encode(Cp860.sanitize('Ç')), [0x80]);
      expect(Cp860.encode(Cp860.sanitize('õ')), [0x94]);
    });

    test('Cartão inteiro', () {
      expect(Cp860.encode(Cp860.sanitize('Cartão')), [
        0x43, 0x61, 0x72, 0x74, 0x84, 0x6F, //
      ]);
    });
  });
}
