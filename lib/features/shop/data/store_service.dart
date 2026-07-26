import 'package:romeu_lanches_admin/core/network/api_client.dart';
import 'package:romeu_lanches_admin/models/store_config.dart';

class StoreService {
  final ApiClient _api;

  const StoreService(this._api);

  Future<StoreConfig> load() async {
    final json = await _api.get('/admin/config');
    return StoreConfig.fromJson(json as Map<String, dynamic>);
  }

  /// `PATCH /admin/config/aberta` — fechar bloqueia **novos** pedidos;
  /// os que já estão em andamento seguem o fluxo normal.
  Future<StoreConfig> setOpen(bool open) async {
    final json = await _api.patch('/admin/config/aberta', body: {'aberta': open});
    return StoreConfig.fromJson(json as Map<String, dynamic>);
  }
}
