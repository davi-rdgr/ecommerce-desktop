import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/di/app_dependencies.dart';
import 'core/navigation/app_messenger.dart';
import 'core/navigation/app_navigator.dart';
import 'core/printing/printer_settings.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // A box da impressora abre antes das dependências: o construtor de
  // AppDependencies é síncrono e já monta o TicketPrinter com ela.
  deps = AppDependencies(await PrinterSettings.open());
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
    );
  }
}
