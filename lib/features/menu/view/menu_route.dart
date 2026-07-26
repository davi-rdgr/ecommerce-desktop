import 'package:romeu_lanches_admin/core/di/app_dependencies.dart';
import 'package:romeu_lanches_admin/features/menu/view/menu_view.dart';
import 'package:flutter/material.dart';

class MenuRoute extends StatelessWidget {
  const MenuRoute({super.key});

  @override
  Widget build(BuildContext context) =>
      MenuView(controller: deps.menuFullDependencies.menu);
}
