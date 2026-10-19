import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Cifra e decifra bytes com o **DPAPI** do Windows (`CryptProtectData`).
///
/// A chave é da conta do Windows logada: o arquivo cifrado copiado para outra
/// máquina, ou lido por outro usuário do mesmo PC, não abre. É o mesmo cofre
/// que o Windows usa para senhas de Wi-Fi e do navegador — e não pede pacote
/// nativo extra (o `flutter_secure_storage` exige o ATL do Visual Studio para
/// compilar).
///
/// Devolve `null` em qualquer falha; quem chama trata como "sem token".
abstract final class TokenVault {
  /// Nunca abrir diálogo do sistema: o painel roda sozinho no balcão.
  static const _uiForbidden = 0x1;

  static Uint8List? protect(Uint8List data) => _run(
    data,
    (input, output) =>
        CryptProtectData(input, null, null, null, _uiForbidden, output).value,
  );

  static Uint8List? unprotect(Uint8List data) => _run(
    data,
    (input, output) =>
        CryptUnprotectData(input, null, null, null, _uiForbidden, output).value,
  );

  static Uint8List? _run(
    Uint8List data,
    bool Function(
      Pointer<CRYPT_INTEGER_BLOB> input,
      Pointer<CRYPT_INTEGER_BLOB> output,
    )
    call,
  ) {
    if (data.isEmpty) return null;

    return using((arena) {
      final buffer = arena<Uint8>(data.length);
      buffer.asTypedList(data.length).setAll(0, data);

      final input = arena<CRYPT_INTEGER_BLOB>();
      input.ref
        ..cbData = data.length
        ..pbData = buffer;
      final output = arena<CRYPT_INTEGER_BLOB>();

      if (!call(input, output)) return null;

      final result = Uint8List.fromList(
        output.ref.pbData.asTypedList(output.ref.cbData),
      );
      // O buffer de saída é alocado pelo próprio Windows (LocalAlloc).
      LocalFree(HLOCAL(output.ref.pbData));
      return result;
    });
  }
}
