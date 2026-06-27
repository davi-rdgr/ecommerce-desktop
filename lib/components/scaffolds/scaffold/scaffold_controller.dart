import 'package:signals_flutter/signals_flutter.dart';

class ScaffoldController {
  final pageIndex = signal(0);
  final pendingOrdersCount = signal(0);
  final isStoreOpen = signal(true);

  void goTo(int index) {
    if (pageIndex.value == index) return;
    pageIndex.value = index;
  }

  void setPendingOrdersCount(int count) => pendingOrdersCount.value = count;

  void toggleStore() => isStoreOpen.value = !isStoreOpen.value;

  void dispose() {
    pageIndex.dispose();
    pendingOrdersCount.dispose();
    isStoreOpen.dispose();
  }
}
