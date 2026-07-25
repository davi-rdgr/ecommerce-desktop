import 'package:romeu_lanches_admin/core/auth/auth_session.dart';
import 'package:romeu_lanches_admin/core/di/home_full_dependencies.dart';
import 'package:romeu_lanches_admin/core/di/login_full_dependencies.dart';
import 'package:romeu_lanches_admin/core/di/scaffold_full_dependencies.dart';
import 'package:romeu_lanches_admin/core/di/shop_full_dependencies.dart';
import 'package:romeu_lanches_admin/core/navigation/app_navigator.dart';
import 'package:romeu_lanches_admin/core/navigation/fade_route.dart';
import 'package:romeu_lanches_admin/core/network/api_client.dart';
import 'package:romeu_lanches_admin/features/login/view/login_route.dart';
import 'package:signals_flutter/signals_flutter.dart';

late final AppDependencies deps;

class AppDependencies {
  late final AuthSession session;
  late final ApiClient apiClient;
  late final ScaffoldFullDependencies scaffoldFullDependencies;
  late final LoginFullDependencies loginFullDependencies;
  late final HomeFullDependencies homeFullDependencies;
  late final ShopFullDependencies shopFullDependencies;

  AppDependencies() {
    session = AuthSession();
    apiClient = ApiClient(session);
    scaffoldFullDependencies = ScaffoldFullDependencies();
    loginFullDependencies = LoginFullDependencies(apiClient, session);
    homeFullDependencies = HomeFullDependencies(apiClient);
    shopFullDependencies = ShopFullDependencies(scaffoldFullDependencies.scaffold);

    // Sessão derrubada no meio do turno (backend reiniciado, JWT_SECRET novo):
    // volta pro login em vez de deixar a tela quebrando em silêncio.
    apiClient.onUnauthorized = () {
      session.clear();
      navigatorKey.currentState?.pushAndRemoveUntil(
        fadeRoute(const LoginRoute()),
        (_) => false,
      );
    };

    effect(() {
      scaffoldFullDependencies.scaffold.setPendingOrdersCount(
        homeFullDependencies.home.activeOrders.value,
      );
    });
  }
}
