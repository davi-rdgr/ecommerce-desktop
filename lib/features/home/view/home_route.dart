import 'package:romeu_lanches_admin/core/di/app_dependencies.dart';
import 'package:romeu_lanches_admin/features/home/view/home_view.dart';
import 'package:flutter/material.dart';

class HomeRoute extends StatelessWidget {
  const HomeRoute({super.key});

  @override
  Widget build(BuildContext context) =>
      HomeView(controller: deps.homeFullDependencies.home);
}
