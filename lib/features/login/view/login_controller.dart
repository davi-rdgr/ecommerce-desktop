import 'package:romeu_lanches_admin/core/auth/auth_session.dart';
import 'package:romeu_lanches_admin/core/network/api_exception.dart';
import 'package:romeu_lanches_admin/features/login/data/auth_service.dart';
import 'package:signals_flutter/signals_flutter.dart';

class LoginController {
  final AuthService _auth;
  final AuthSession _session;

  LoginController(this._auth, this._session);

  final isLoading = signal(false);
  final errorMessage = signal<String?>(null);

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
      return true;
    } on ApiException catch (e) {
      errorMessage.value = _messageFor(e);
      return false;
    } finally {
      isLoading.value = false;
    }
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
  }
}
