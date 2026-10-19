import 'dart:async';

import 'package:romeu_lanches_admin/core/auth/auth_session.dart';
import 'package:romeu_lanches_admin/core/auth/saved_session.dart';
import 'package:romeu_lanches_admin/core/di/home_full_dependencies.dart';
import 'package:romeu_lanches_admin/core/di/login_full_dependencies.dart';
import 'package:romeu_lanches_admin/core/di/menu_full_dependencies.dart';
import 'package:romeu_lanches_admin/core/di/report_full_dependencies.dart';
import 'package:romeu_lanches_admin/core/di/scaffold_full_dependencies.dart';
import 'package:romeu_lanches_admin/core/di/shop_full_dependencies.dart';
import 'package:romeu_lanches_admin/core/navigation/app_navigator.dart';
import 'package:romeu_lanches_admin/core/navigation/fade_route.dart';
import 'package:romeu_lanches_admin/core/network/api_client.dart';
import 'package:romeu_lanches_admin/core/printing/printer_settings.dart';
import 'package:romeu_lanches_admin/core/printing/ticket_printer.dart';
import 'package:romeu_lanches_admin/core/sound/new_order_alert.dart';
import 'package:romeu_lanches_admin/features/login/view/login_route.dart';
import 'package:romeu_lanches_admin/features/login/view/login_controller.dart';
import 'package:signals_flutter/signals_flutter.dart';

late final AppDependencies deps;

class AppDependencies {
  late final AuthSession session;
  late final SavedSession savedSession;
  late final ApiClient apiClient;
  late final TicketPrinter ticketPrinter;
  late final ScaffoldFullDependencies scaffoldFullDependencies;
  late final LoginFullDependencies loginFullDependencies;
  late final HomeFullDependencies homeFullDependencies;
  late final MenuFullDependencies menuFullDependencies;
  late final ShopFullDependencies shopFullDependencies;
  late final ReportFullDependencies reportFullDependencies;

  /// [printerSettings] e [newOrderAlert] chegam prontos porque abrir a box do
  /// Hive e carregar o WAV são assíncronos e este construtor não é — `main`
  /// abre os dois antes de montar as dependências.
  AppDependencies(PrinterSettings printerSettings, NewOrderAlert newOrderAlert) {
    session = AuthSession();
    savedSession = SavedSession();
    apiClient = ApiClient(session);
    ticketPrinter = TicketPrinter(printerSettings);
    scaffoldFullDependencies = ScaffoldFullDependencies();
    loginFullDependencies = LoginFullDependencies(
      apiClient,
      session,
      savedSession,
    );
    // Antes do painel: ele usa o mesmo ReportService para os cards de "HOJE".
    reportFullDependencies = ReportFullDependencies(apiClient);
    homeFullDependencies = HomeFullDependencies(
      apiClient,
      session,
      reportFullDependencies.reportService,
      ticketPrinter,
      newOrderAlert,
    );
    menuFullDependencies = MenuFullDependencies(apiClient);
    shopFullDependencies = ShopFullDependencies(
      apiClient,
      scaffoldFullDependencies.scaffold,
      printerSettings,
      ticketPrinter,
    );

    // Sessão derrubada no meio do turno (token vencido, backend com
    // JWT_SECRET novo): volta pro login em vez de deixar a tela quebrando em
    // silêncio. O token salvo vai junto — já não serve para a entrada rápida.
    apiClient.onUnauthorized = () => unawaited(logout(expired: true));

    effect(() {
      scaffoldFullDependencies.scaffold.setPendingOrdersCount(
        homeFullDependencies.home.activeOrders.value,
      );
    });
  }

  /// "Sair" do menu do avatar e 401 em chamada autenticada caem aqui: fecha a
  /// sessão, apaga o token salvo e volta para o login. O storage é limpo
  /// **antes** de navegar, senão a tela de login ainda leria o token velho e
  /// mostraria a entrada rápida.
  ///
  /// [expired] deixa um aviso na tela de login, para o Romeu entender por que
  /// precisa digitar a senha de novo.
  Future<void> logout({bool expired = false}) async {
    // Sem token o canal só ficaria tentando reconectar e sendo recusado no
    // CONNECT.
    homeFullDependencies.home.stopRealtime();
    session.clear();
    final login = loginFullDependencies.login;
    login.savedLogin.value = null;
    login.errorMessage.value = expired ? LoginController.expiredMessage : null;
    await savedSession.clear();
    navigatorKey.currentState?.pushAndRemoveUntil(
      fadeRoute(const LoginRoute()),
      (_) => false,
    );
  }
}
