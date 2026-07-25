import 'package:flutter/material.dart';
import 'package:romeu_lanches_admin/app_shell.dart';
import 'package:romeu_lanches_admin/core/di/app_dependencies.dart';
import 'package:romeu_lanches_admin/core/navigation/fade_route.dart';
import 'package:romeu_lanches_admin/features/login/view/login_view.dart';

class LoginRoute extends StatelessWidget {
  const LoginRoute({super.key});

  @override
  Widget build(BuildContext context) => LoginView(
    controller: deps.loginFullDependencies.login,
    onLoggedIn: () =>
        Navigator.of(context).pushReplacement(fadeRoute(const AppShell())),
  );
}
