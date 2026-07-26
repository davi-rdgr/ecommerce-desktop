import 'package:romeu_lanches_admin/core/network/api_client.dart';
import 'package:romeu_lanches_admin/features/menu/data/menu_service.dart';
import 'package:romeu_lanches_admin/features/menu/view/menu_controller.dart';

class MenuFullDependencies {
  late final MenuService menuService;
  late final MenuController menu;

  MenuFullDependencies(ApiClient api) {
    menuService = MenuService(api);
    menu = MenuController(menuService);
  }
}
