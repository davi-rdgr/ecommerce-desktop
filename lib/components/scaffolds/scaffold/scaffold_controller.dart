import 'package:signals_flutter/signals_flutter.dart';

class ScaffoldController {
  final pageIndex = signal(0);
  final pendingOrdersCount = signal(0);

  /// Espelho do estado real da loja — quem manda é o `ConfigLojaResponse`.
  final isStoreOpen = signal(true);

  /// Falso até o `GET /admin/config` responder. Antes disso o toggle não age:
  /// mandar `!isStoreOpen` sem saber o valor real pode inverter a loja errada.
  final isStoreKnown = signal(false);

  /// Enquanto o PATCH está em voo, o toggle da sidebar não aceita clique.
  final isStoreBusy = signal(false);

  /// Ligado pelo `ShopController`, que é quem fala com a API.
  Future<void> Function()? onToggleStore;

  void goTo(int index) {
    if (pageIndex.value == index) return;
    pageIndex.value = index;
  }

  void setPendingOrdersCount(int count) => pendingOrdersCount.value = count;

  void setStoreOpen(bool open) {
    isStoreOpen.value = open;
    isStoreKnown.value = true;
  }

  void setStoreBusy(bool busy) => isStoreBusy.value = busy;

  void toggleStore() {
    if (isStoreBusy.value || !isStoreKnown.value) return;
    onToggleStore?.call();
  }

  void dispose() {
    pageIndex.dispose();
    pendingOrdersCount.dispose();
    isStoreOpen.dispose();
    isStoreKnown.dispose();
    isStoreBusy.dispose();
  }
}
