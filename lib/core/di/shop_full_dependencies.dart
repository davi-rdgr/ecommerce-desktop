import 'package:romeu_lanches_admin/components/scaffolds/scaffold/scaffold_controller.dart';
import 'package:romeu_lanches_admin/features/shop/view/shop_controller.dart';

class ShopFullDependencies {
  late final ShopController shop;

  ShopFullDependencies(ScaffoldController scaffold) {
    shop = ShopController(scaffold);
  }
}
