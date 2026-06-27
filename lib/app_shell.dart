import 'package:ecommerce/components/scaffolds/scaffold/scaffold_view.dart';
import 'package:ecommerce/core/di/app_dependencies.dart';
import 'package:ecommerce/features/home/view/home_view.dart';
import 'package:ecommerce/features/menu/view/menu_view.dart';
import 'package:ecommerce/features/report/view/report_view.dart';
import 'package:ecommerce/features/shop/view/shop_view.dart';
import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldView(
      controller: deps.scaffoldFullDependencies.scaffold,
      pages: const [
        HomeView(),
        MenuView(),
        ShopView(),
        ReportView(),
      ],
    );
  }
}
