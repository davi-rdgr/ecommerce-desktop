import 'package:ecommerce/features/shop/view/shop_controller.dart';
import 'package:ecommerce/features/shop/view/shop_view.dart';
import 'package:flutter/material.dart';

class ShopRoute extends StatefulWidget {
  const ShopRoute({super.key});

  @override
  State<ShopRoute> createState() => _ShopRouteState();
}

class _ShopRouteState extends State<ShopRoute> {
  late final ShopController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ShopController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ShopView(controller: _controller);
}
