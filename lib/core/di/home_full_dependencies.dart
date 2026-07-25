import 'package:romeu_lanches_admin/core/auth/auth_session.dart';
import 'package:romeu_lanches_admin/core/network/api_client.dart';
import 'package:romeu_lanches_admin/features/home/data/order_service.dart';
import 'package:romeu_lanches_admin/features/home/data/orders_realtime.dart';
import 'package:romeu_lanches_admin/features/home/view/home_controller.dart';

class HomeFullDependencies {
  late final OrderService orderService;
  late final OrdersRealtime realtime;
  late final HomeController home;

  HomeFullDependencies(ApiClient api, AuthSession session) {
    orderService = OrderService(api);
    realtime = OrdersRealtime(session);
    home = HomeController(orderService, realtime);
  }
}
