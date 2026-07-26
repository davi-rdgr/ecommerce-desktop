import 'package:romeu_lanches_admin/components/scaffolds/scaffold/scaffold_controller.dart';
import 'package:romeu_lanches_admin/core/network/api_client.dart';
import 'package:romeu_lanches_admin/features/shop/data/store_service.dart';
import 'package:romeu_lanches_admin/features/shop/view/shop_controller.dart';

class ShopFullDependencies {
  late final StoreService storeService;
  late final ShopController shop;

  ShopFullDependencies(ApiClient api, ScaffoldController scaffold) {
    storeService = StoreService(api);
    shop = ShopController(storeService, scaffold);
  }
}
