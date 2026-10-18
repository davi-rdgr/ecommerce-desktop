import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/config/app_environment.dart';
import 'core/di/app_dependencies.dart';
import 'core/navigation/app_messenger.dart';
import 'core/navigation/app_navigator.dart';
import 'core/printing/printer_settings.dart';
import 'core/sound/new_order_alert.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Resolve o ambiente antes de tudo: ENV inválido derruba o app aqui, não na
  // primeira chamada à API.
  AppEnvironment.current;
  await Hive.initFlutter();
  // A box da impressora e o WAV do aviso abrem antes das dependências: o
  // construtor de AppDependencies é síncrono e já monta o TicketPrinter e o
  // painel com eles.
  deps = AppDependencies(
    await PrinterSettings.open(),
    await NewOrderAlert.open(),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Romeu Lanches',
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: const SplashScreen(),
      builder: (context, child) => _EnvironmentBanner(child: child!),
    );
  }
}

/// Faixa no canto com o nome do ambiente, para um build fora de prod nunca
/// passar despercebido. Em prod não desenha nada.
class _EnvironmentBanner extends StatelessWidget {
  final Widget child;

  const _EnvironmentBanner({required this.child});

  @override
  Widget build(BuildContext context) {
    final env = AppEnvironment.current;
    if (env.isProd) return child;

    return Banner(
      message: env.label,
      location: BannerLocation.bottomStart,
      color: env.isLocal ? Colors.green.shade700 : Colors.purple.shade700,
      child: child,
    );
  }
}
