import 'package:romeu_lanches_admin/components/scaffolds/scaffold/scaffold_controller.dart';
import 'package:romeu_lanches_admin/core/navigation/app_messenger.dart';
import 'package:romeu_lanches_admin/core/network/api_exception.dart';
import 'package:romeu_lanches_admin/features/shop/data/store_service.dart';
import 'package:romeu_lanches_admin/models/store_config.dart';
import 'package:signals_flutter/signals_flutter.dart';

class ShopController {
  final StoreService _service;
  final ScaffoldController _scaffold;

  ShopController(this._service, this._scaffold) {
    _scaffold.onToggleStore = toggleStore;
  }

  final headerTitle = 'Loja';
  final headerSubtitle = 'Funcionamento, entrega e pagamentos';

  final config = signal<StoreConfig?>(null);
  final isLoading = signal(false);
  final loadError = signal<String?>(null);

  Signal<bool> get isStoreOpen => _scaffold.isStoreOpen;
  Signal<bool> get isStoreBusy => _scaffold.isStoreBusy;

  Future<void> load() async {
    isLoading.value = true;
    loadError.value = null;

    try {
      _apply(await _service.load());
    } on ApiException catch (e) {
      loadError.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// Disparado tanto pelo card da tela quanto pelo toggle da sidebar. Como a
  /// sidebar não pertence a nenhuma view, o erro sai por [showAppMessage].
  Future<void> toggleStore() async {
    if (_scaffold.isStoreBusy.value) return;
    _scaffold.setStoreBusy(true);

    final target = !_scaffold.isStoreOpen.value;

    try {
      _apply(await _service.setOpen(target));
      showAppMessage(
        target
            ? 'Loja aberta — recebendo pedidos.'
            : 'Loja fechada — novos pedidos serão recusados.',
      );
    } on ApiException catch (e) {
      showAppMessage(e.message);
    } finally {
      _scaffold.setStoreBusy(false);
    }
  }

  void _apply(StoreConfig value) {
    config.value = value;
    _scaffold.setStoreOpen(value.open);
  }

  void dispose() {
    config.dispose();
    isLoading.dispose();
    loadError.dispose();
  }
}
