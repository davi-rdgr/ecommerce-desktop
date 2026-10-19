import 'dart:typed_data';

/// Substituto de [TokenVault] em plataformas sem `dart:ffi` (web): não cifra,
/// então nada é guardado e a tela de login mostra só o formulário.
abstract final class TokenVault {
  static Uint8List? protect(Uint8List data) => null;

  static Uint8List? unprotect(Uint8List data) => null;
}
