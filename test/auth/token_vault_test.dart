import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:romeu_lanches_admin/core/auth/token_vault.dart';

void main() {
  test(
    'DPAPI cifra e decifra de volta o mesmo conteúdo',
    () {
      final plain = Uint8List.fromList(utf8.encode('{"token":"abc.def.ghi"}'));

      final sealed = TokenVault.protect(plain);
      expect(sealed, isNotNull);
      expect(sealed, isNot(equals(plain)));
      expect(TokenVault.unprotect(sealed!), equals(plain));
    },
    skip: !Platform.isWindows,
  );

  test('blob adulterado não decifra', () {
    final sealed = TokenVault.protect(Uint8List.fromList([1, 2, 3]))!;
    sealed[sealed.length - 1] ^= 0xFF;
    expect(TokenVault.unprotect(sealed), isNull);
  }, skip: !Platform.isWindows);
}
