import 'package:romeu_lanches_admin/core/di/app_dependencies.dart';
import 'package:romeu_lanches_admin/features/shop/view/shop_view.dart';
import 'package:flutter/material.dart';

class ShopRoute extends StatelessWidget {
  const ShopRoute({super.key});

  @override
  Widget build(BuildContext context) =>
      ShopView(controller: deps.shopFullDependencies.shop);
}
