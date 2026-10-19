import 'package:romeu_lanches_admin/core/network/api_client.dart';
import 'package:romeu_lanches_admin/features/login/data/login_response.dart';

class AuthService {
  final ApiClient _api;

  const AuthService(this._api);

  /// `POST /auth/admin/login` — 401 quando as credenciais não conferem.
  Future<LoginResponse> loginAdmin({
    required String email,
    required String password,
  }) async {
    final json = await _api.post(
      '/auth/admin/login',
      body: {'email': email, 'senha': password},
    );
    return LoginResponse.fromJson(json as Map<String, dynamic>);
  }

  /// Confere se um token salvo ainda é aceito, sem abrir sessão com ele.
  /// `GET /admin/config` é a chamada de admin mais leve que existe; lança
  /// [ApiException] com 401 se o token venceu ou foi invalidado.
  Future<void> checkToken(String token) =>
      _api.get('/admin/config', bearer: token);
}
