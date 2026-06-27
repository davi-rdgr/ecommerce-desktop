import 'package:signals_flutter/signals_flutter.dart';

class HomeController {
  final isLoading = signal(false);
  final headerTitle = 'Pedidos';
  final headerSubtitle = 'Acompanhe e gerencie os pedidos em tempo real';












  void setLoading(bool value) => isLoading.value = value;

  void dispose() {
    isLoading.dispose();
  }
}
