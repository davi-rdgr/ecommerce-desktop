import 'dart:typed_data';

/// Codificação para a página de código **CP860 (Português)**, a que as
/// impressoras ESC/POS selecionam com `ESC t 3`.
///
/// Cupom térmico não é UTF-8: cada byte é um caractere da página de código
/// ativa. Mandar UTF-8 cru faz "Cartão" sair como "CartÃ£o", então o texto
/// passa por aqui antes de virar byte.
///
/// O fluxo é sempre **[sanitize] e depois [encode]**. `sanitize` devolve uma
/// string em que 1 code unit = 1 byte impresso, o que deixa a conta de largura
/// de coluna exata — emoji em observação de cliente viraria 2 code units e
/// desalinharia a coluna de preço se medido antes.
abstract final class Cp860 {
  /// Caracteres da metade alta do CP860 que interessam ao português.
  static const _highBytes = <String, int>{
    'Ç': 0x80, 'ü': 0x81, 'é': 0x82, 'â': 0x83, 'ã': 0x84, 'à': 0x85,
    'Á': 0x86, 'ç': 0x87, 'ê': 0x88, 'Ê': 0x89, 'è': 0x8A, 'Í': 0x8B,
    'Ô': 0x8C, 'ì': 0x8D, 'Ã': 0x8E, 'Â': 0x8F, 'É': 0x90, 'À': 0x91,
    'È': 0x92, 'ô': 0x93, 'õ': 0x94, 'ò': 0x95, 'Ú': 0x96, 'ù': 0x97,
    'Ì': 0x98, 'Õ': 0x99, 'Ü': 0x9A, '¢': 0x9B, '£': 0x9C, 'Ù': 0x9D,
    'Ó': 0x9F, 'á': 0xA0, 'í': 0xA1, 'ó': 0xA2, 'ú': 0xA3, 'ñ': 0xA4,
    'Ñ': 0xA5, 'ª': 0xA6, 'º': 0xA7, '¿': 0xA8, 'Ò': 0xA9, '¬': 0xAA,
    '½': 0xAB, '¼': 0xAC, '¡': 0xAD, '«': 0xAE, '»': 0xAF,
  };

  /// O que não existe no CP860 mas aparece em texto colado de celular:
  /// travessão, aspa curva, reticências. Cai para o equivalente ASCII em vez
  /// de virar `?`.
  static const _fallback = <String, String>{
    '–': '-', '—': '-', '‒': '-', '−': '-',
    '‘': "'", '’': "'", '‚': "'", '´': "'", '`': "'",
    '“': '"', '”': '"', '„': '"',
    '…': '...', '•': '-', '·': '-', '→': '->',
    ' ': ' ',
    'ä': 'a', 'å': 'a', 'ë': 'e', 'ï': 'i', 'ö': 'o', 'ø': 'o', 'ß': 'ss',
    'Ä': 'A', 'Å': 'A', 'Ë': 'E', 'Ï': 'I', 'Ö': 'O', 'Ø': 'O',
  };

  /// Deixa [text] com 1 code unit por byte impresso.
  ///
  /// Quebra de linha e tabulação viram espaço — quem monta o cupom decide onde
  /// a linha termina, senão o `\n` de uma observação estouraria o layout.
  /// O que não tem representação nem equivalente vira `?`.
  static String sanitize(String text) {
    final out = StringBuffer();

    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);

      if (rune == 0x0A || rune == 0x0D || rune == 0x09) {
        out.write(' ');
      } else if (rune >= 0x20 && rune <= 0x7E) {
        out.write(char);
      } else if (_highBytes.containsKey(char)) {
        out.write(char);
      } else if (_fallback.containsKey(char)) {
        out.write(_fallback[char]);
      } else {
        out.write('?');
      }
    }

    return out.toString();
  }

  /// Converte uma string **já passada por [sanitize]** em bytes CP860.
  static Uint8List encode(String sanitized) {
    final bytes = Uint8List(sanitized.length);

    for (var i = 0; i < sanitized.length; i++) {
      final char = sanitized[i];
      final code = sanitized.codeUnitAt(i);
      bytes[i] = code <= 0x7E ? code : (_highBytes[char] ?? 0x3F);
    }

    return bytes;
  }
}
