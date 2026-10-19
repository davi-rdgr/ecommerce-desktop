import 'package:romeu_lanches_admin/core/auth/auth_session.dart';
import 'package:romeu_lanches_admin/core/auth/saved_session.dart';
import 'package:romeu_lanches_admin/core/network/api_exception.dart';
import 'package:romeu_lanches_admin/features/login/data/auth_service.dart';
import 'package:signals_flutter/signals_flutter.dart';

class LoginController {
  final AuthService _auth;
  final AuthSession _session;
  final SavedSession _saved;

  LoginController(this._auth, this._session, this._saved);

  final isLoading = signal(false);
  final errorMessage = signal<String?>(null);

  /// Token do último login, se houver — é o que liga o botão de entrada
  /// rápida. `null` = só o formulário.
  final savedLogin = signal<({String token, String adminName})?>(null);

  /// Lê o token guardado. Chamado toda vez que a tela de login abre: depois de
  /// "Sair" o storage já está vazio e o botão não aparece.
  Future<void> loadSaved() async {
    final saved = await _saved.read();
    // Vencido nem vira botão: clicar só para ouvir "expirou" seria pior.
    if (saved != null && SavedSession.isExpired(saved.token)) {
      await _saved.clear();
      savedLogin.value = null;
      return;
    }
    savedLogin.value = saved;
  }

  /// Abre a sessão e devolve `true` em caso de sucesso — quem navega é a view.
  Future<bool> login({required String email, required String password}) async {
    if (isLoading.value) return false;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final response = await _auth.loginAdmin(
        email: email.trim(),
        password: password,
      );
      _session.start(token: response.token, adminName: response.adminName);
      await _saved.save(token: response.token, adminName: response.adminName);
      return true;
    } on ApiException catch (e) {
      errorMessage.value = _messageFor(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Entrada com um clique usando o token guardado. O token é conferido no
  /// servidor **antes** de abrir a sessão: se venceu, o botão some e sobra o
  /// formulário, com um aviso — sem entrar no painel para cair de volta.
  Future<bool> quickLogin() async {
    final saved = savedLogin.value;
    if (saved == null || isLoading.value) return false;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      if (SavedSession.isExpired(saved.token)) {
        await _forgetExpired();
        return false;
      }
      await _auth.checkToken(saved.token);
      _session.start(token: saved.token, adminName: saved.adminName);
      return true;
    } on ApiException catch (e) {
      if (e.isUnauthorized || e.isForbidden) {
        await _forgetExpired();
      } else {
        // Rede fora ou servidor caído: o token pode estar bom, então fica.
        errorMessage.value = e.message;
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  static const expiredMessage =
      'Sua sessão expirou. Entre de novo com e-mail e senha.';

  Future<void> _forgetExpired() async {
    await _saved.clear();
    savedLogin.value = null;
    errorMessage.value = expiredMessage;
  }

  String _messageFor(ApiException e) {
    if (e.isNetworkFailure) return e.message;
    // No login, 401 é sempre credencial errada — não sessão expirada.
    if (e.isUnauthorized) return 'E-mail ou senha incorretos.';
    return e.message;
  }

  void clearError() => errorMessage.value = null;

  void dispose() {
    isLoading.dispose();
    errorMessage.dispose();
    savedLogin.dispose();
  }
}
