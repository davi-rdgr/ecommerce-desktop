import 'package:romeu_lanches_admin/core/auth/auth_session.dart';
import 'package:romeu_lanches_admin/core/network/api_client.dart';
import 'package:romeu_lanches_admin/features/login/data/auth_service.dart';
import 'package:romeu_lanches_admin/features/login/view/login_controller.dart';

class LoginFullDependencies {
  late final AuthService authService;
  late final LoginController login;

  LoginFullDependencies(ApiClient api, AuthSession session) {
    authService = AuthService(api);
    login = LoginController(authService, session);
  }
}
