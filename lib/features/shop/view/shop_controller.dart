import 'package:romeu_lanches_admin/components/scaffolds/scaffold/scaffold_controller.dart';
import 'package:romeu_lanches_admin/core/navigation/app_messenger.dart';
import 'package:romeu_lanches_admin/core/network/api_exception.dart';
import 'package:romeu_lanches_admin/features/shop/data/store_service.dart';
import 'package:romeu_lanches_admin/models/business_hours.dart';
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
  final hours = signal<List<BusinessHours>>([]);
  final isLoading = signal(false);
  final loadError = signal<String?>(null);

  /// Um PATCH de config em voo. Trava os cinco controles juntos, já que a
  /// rota substitui o conjunto inteiro e disparos concorrentes se sobrescrevem.
  final isSavingConfig = signal(false);

  /// Dia com PUT em voo, ou `null`. Dias diferentes salvam em paralelo.
  final savingWeekday = signal<int?>(null);

  Signal<bool> get isStoreOpen => _scaffold.isStoreOpen;
  Signal<bool> get isStoreBusy => _scaffold.isStoreBusy;

  Future<void> load() async {
    isLoading.value = true;
    loadError.value = null;

    try {
      final configRequest = _service.loadConfig();
      final hoursRequest = _service.listHours();

      _apply(await configRequest);
      hours.value = (await hoursRequest)
        ..sort((a, b) => a.weekday.compareTo(b.weekday));
    } on ApiException catch (e) {
      loadError.value = _messageFor(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Disparado tanto pelo card da tela quanto pelo toggle da sidebar. Como a
  /// sidebar não pertence a nenhuma view, o retorno sai por [showAppMessage].
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
      showAppMessage(_messageFor(e));
    } finally {
      _scaffold.setStoreBusy(false);
    }
  }

  /// Taxa, tempo estimado e formas de pagamento. Recebe a config inteira já
  /// alterada — o endpoint não aceita payload parcial.
  Future<String?> saveConfig(StoreConfig next) async {
    if (isSavingConfig.value) return null;
    isSavingConfig.value = true;

    try {
      _apply(await _service.updateConfig(next));
      return null;
    } on ApiException catch (e) {
      return _messageFor(e);
    } finally {
      isSavingConfig.value = false;
    }
  }

  Future<String?> saveHours(BusinessHours next) async {
    if (savingWeekday.value != null) return null;
    savingWeekday.value = next.weekday;

    try {
      final saved = await _service.updateHours(next);
      hours.value = [
        for (final day in hours.value)
          if (day.weekday == saved.weekday) saved else day,
      ];
      return null;
    } on ApiException catch (e) {
      return _messageFor(e);
    } finally {
      savingWeekday.value = null;
    }
  }

  void _apply(StoreConfig value) {
    config.value = value;
    _scaffold.setStoreOpen(value.open);
  }

  /// O 400 de validação vem como `{"error":"Dados inválidos","campos":{...}}`.
  /// A mensagem útil está no campo, não no `error`.
  String _messageFor(ApiException e) {
    final fields = e.fields;
    if (fields != null && fields.isNotEmpty) return fields.values.first;
    return e.message;
  }

  void dispose() {
    config.dispose();
    hours.dispose();
    isLoading.dispose();
    loadError.dispose();
    isSavingConfig.dispose();
    savingWeekday.dispose();
  }
}
