import 'package:romeu_lanches_admin/core/auth/auth_session.dart';
import 'package:romeu_lanches_admin/core/network/api_client.dart';
import 'package:romeu_lanches_admin/core/printing/ticket_printer.dart';
import 'package:romeu_lanches_admin/core/sound/new_order_alert.dart';
import 'package:romeu_lanches_admin/features/home/data/order_service.dart';
import 'package:romeu_lanches_admin/features/home/data/orders_realtime.dart';
import 'package:romeu_lanches_admin/features/home/view/home_controller.dart';
import 'package:romeu_lanches_admin/features/report/data/report_service.dart';

class HomeFullDependencies {
  late final OrderService orderService;
  late final OrdersRealtime realtime;
  late final HomeController home;

  /// `reportService` vem de fora: os cards de "HOJE" do painel saem do mesmo
  /// `/admin/relatorio/dia` da tela de Relatório. `ticketPrinter` também, já
  /// que a tela de Loja usa o mesmo para o teste de impressão.
  HomeFullDependencies(
    ApiClient api,
    AuthSession session,
    ReportService reportService,
    TicketPrinter ticketPrinter,
    NewOrderAlert newOrderAlert,
  ) {
    orderService = OrderService(api);
    realtime = OrdersRealtime(session);
    home = HomeController(
      orderService,
      reportService,
      realtime,
      ticketPrinter,
      newOrderAlert,
    );
  }
}
