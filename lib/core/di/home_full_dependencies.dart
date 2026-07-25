import 'package:romeu_lanches_admin/core/network/api_client.dart';
import 'package:romeu_lanches_admin/features/home/data/order_service.dart';
import 'package:romeu_lanches_admin/features/home/view/home_controller.dart';

class HomeFullDependencies {
  late final OrderService orderService;
  late final HomeController home;

  HomeFullDependencies(ApiClient api) {
    orderService = OrderService(api);
    home = HomeController(orderService);
  }
}
