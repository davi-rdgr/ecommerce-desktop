import 'package:romeu_lanches_admin/components/scaffolds/scaffold/scaffold_view.dart';
import 'package:romeu_lanches_admin/core/di/app_dependencies.dart';
import 'package:romeu_lanches_admin/features/home/view/home_route.dart';
import 'package:romeu_lanches_admin/features/menu/view/menu_route.dart';
import 'package:romeu_lanches_admin/features/report/view/report_route.dart';
import 'package:romeu_lanches_admin/features/shop/view/shop_route.dart';
import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldView(
      controller: deps.scaffoldFullDependencies.scaffold,
      pages: const [
        HomeRoute(),
        MenuRoute(),
        ShopRoute(),
        ReportRoute(),
      ],
    );
  }
}
