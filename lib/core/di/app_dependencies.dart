import 'package:romeu_lanches_admin/core/di/home_full_dependencies.dart';
import 'package:romeu_lanches_admin/core/di/scaffold_full_dependencies.dart';
import 'package:romeu_lanches_admin/core/di/shop_full_dependencies.dart';
import 'package:signals_flutter/signals_flutter.dart';

late final AppDependencies deps;

class AppDependencies {
  late final ScaffoldFullDependencies scaffoldFullDependencies;
  late final HomeFullDependencies homeFullDependencies;
  late final ShopFullDependencies shopFullDependencies;

  AppDependencies() {
    scaffoldFullDependencies = ScaffoldFullDependencies();
    homeFullDependencies = HomeFullDependencies();
    shopFullDependencies = ShopFullDependencies(scaffoldFullDependencies.scaffold);
    effect(() {
      scaffoldFullDependencies.scaffold.setPendingOrdersCount(
        homeFullDependencies.home.activeOrders.value,
      );
    });
  }
}
