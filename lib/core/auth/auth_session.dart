import 'package:signals_flutter/signals_flutter.dart';

/// Sessão do admin, mantida **apenas em memória**.
///
/// O turno vai das 18h à meia-noite e o JWT dura 24h, então não há expiração
/// durante o uso e não existe refresh token no backend. Nada é gravado em disco:
/// fechou o app, precisa logar de novo — o que evita credencial em repouso na
/// máquina do balcão.
class AuthSession {
  final token = signal<String?>(null);
  final adminName = signal<String?>(null);

  late final isAuthenticated = computed(() => token.value != null);

  /// Header pronto para as chamadas autenticadas; vazio quando não há sessão.
  Map<String, String> get authHeader {
    final value = token.value;
    return value == null ? const {} : {'Authorization': 'Bearer $value'};
  }

  void start({required String token, required String adminName}) {
    this.token.value = token;
    this.adminName.value = adminName;
  }

  void clear() {
    token.value = null;
    adminName.value = null;
  }

  void dispose() {
    token.dispose();
    adminName.dispose();
    isAuthenticated.dispose();
  }
}
