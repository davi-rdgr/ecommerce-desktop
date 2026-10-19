// Cifrar com a conta do Windows usa o DPAPI via `dart:ffi`, que não existe na
// web. Fora do Windows entra um stub que não guarda nada (sem entrada rápida).
export 'token_vault_stub.dart' if (dart.library.ffi) 'token_vault_windows.dart';
