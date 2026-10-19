import 'dart:convert';
import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:romeu_lanches_admin/core/auth/token_vault.dart';

/// Token do último login do admin, para a entrada com um clique.
///
/// Fica cifrado pelo [TokenVault] (DPAPI, chave da conta do Windows) numa box
/// do Hive. **Nunca** a senha — só o JWT, que expira sozinho (30 dias) e some
/// no "Sair" ou no primeiro 401.
///
/// Toda falha (box corrompida, cifra que não abre, plataforma sem DPAPI) vira
/// "não há sessão salva": no pior caso o Romeu digita a senha, o app nunca cai
/// por causa disso.
class SavedSession {
  static const _boxName = 'session';
  static const _key = 'admin';

  Future<Box> _box() => Hive.openBox(_boxName);

  Future<({String token, String adminName})?> read() async {
    try {
      final stored = (await _box()).get(_key);
      if (stored is! String) return null;

      final plain = TokenVault.unprotect(base64Decode(stored));
      if (plain == null) return null;

      final json = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
      final token = json['token'] as String?;
      if (token == null || token.isEmpty) return null;
      return (token: token, adminName: (json['nome'] as String?) ?? '');
    } catch (_) {
      return null;
    }
  }

  Future<void> save({required String token, required String adminName}) async {
    try {
      final plain = utf8.encode(
        jsonEncode({'token': token, 'nome': adminName}),
      );
      final sealed = TokenVault.protect(Uint8List.fromList(plain));
      // Sem cifra, não grava: token em texto puro no disco não entra.
      if (sealed == null) return;
      await (await _box()).put(_key, base64Encode(sealed));
    } catch (_) {
      // Sem storage, sem entrada rápida — o login em si já deu certo.
    }
  }

  Future<void> clear() async {
    try {
      await (await _box()).delete(_key);
    } catch (_) {
      // Nada a fazer: se não dá para apagar, também não dá para ler.
    }
  }

  /// Lê o `exp` do JWT sem validar a assinatura — só para não mandar ao
  /// servidor um token que já se sabe vencido. Quem decide de verdade é o
  /// backend (401). Token ilegível conta como vencido.
  static bool isExpired(String token, {DateTime? now}) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload =
          jsonDecode(
                utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
              )
              as Map<String, dynamic>;
      final exp = payload['exp'];
      if (exp is! int) return true;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return !(now ?? DateTime.now()).isBefore(expiresAt);
    } catch (_) {
      return true;
    }
  }
}
