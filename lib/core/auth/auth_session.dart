import 'package:signals_flutter/signals_flutter.dart';

/// Sessão do admin aberta agora, em memória.
///
/// O token também fica guardado, cifrado com o DPAPI do Windows
/// (`SavedSession`), para a entrada com um clique — a senha, nunca. O JWT do
/// admin dura 30 dias e não existe refresh token: venceu, a próxima chamada
/// volta 401 e o app manda para o login.
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
