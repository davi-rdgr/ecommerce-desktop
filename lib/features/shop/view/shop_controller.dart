import 'package:romeu_lanches_admin/components/scaffolds/scaffold/scaffold_controller.dart';
import 'package:signals_flutter/signals_flutter.dart';

class DaySchedule {
  final String name;
  final Signal<bool> enabled;
  final String openTime;
  final String closeTime;

  DaySchedule({
    required this.name,
    required this.enabled,
    required this.openTime,
    required this.closeTime,
  });

  void dispose() => enabled.dispose();
}

class ShopController {
  final ScaffoldController _scaffold;

  ShopController(this._scaffold);

  Signal<bool> get isStoreOpen => _scaffold.isStoreOpen;
  void toggleStore() => _scaffold.toggleStore();

  final headerTitle = 'Loja';
  final headerSubtitle = 'Funcionamento, entrega e pagamentos';

  late final schedule = [
    DaySchedule(name: 'Domingo', enabled: signal(true),  openTime: '18:30', closeTime: '23:30'),
    DaySchedule(name: 'Segunda', enabled: signal(false), openTime: '18:30', closeTime: '23:30'),
    DaySchedule(name: 'Terça',   enabled: signal(true),  openTime: '18:30', closeTime: '23:30'),
    DaySchedule(name: 'Quarta',  enabled: signal(true),  openTime: '18:30', closeTime: '23:30'),
    DaySchedule(name: 'Quinta',  enabled: signal(true),  openTime: '18:30', closeTime: '23:30'),
    DaySchedule(name: 'Sexta',   enabled: signal(true),  openTime: '18:30', closeTime: '00:00'),
    DaySchedule(name: 'Sábado',  enabled: signal(true),  openTime: '18:30', closeTime: '00:00'),
  ];

  final deliveryFee = signal(6.0);
  final estimatedTime = signal(40);

  final pixEnabled = signal(true);
  final creditCardEnabled = signal(true);
  final cashEnabled = signal(true);

  void dispose() {
    for (final d in schedule) {
      d.dispose();
    }
    deliveryFee.dispose();
    estimatedTime.dispose();
    pixEnabled.dispose();
    creditCardEnabled.dispose();
    cashEnabled.dispose();
  }
}
