import 'package:ecommerce/features/menu/view/menu_controller.dart';
import 'package:ecommerce/features/menu/view/menu_view.dart';
import 'package:flutter/material.dart' hide MenuController;

class MenuRoute extends StatefulWidget {
  const MenuRoute({super.key});

  @override
  State<MenuRoute> createState() => _MenuRouteState();
}

class _MenuRouteState extends State<MenuRoute> {
  late final MenuController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MenuController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MenuView(controller: _controller);
}
