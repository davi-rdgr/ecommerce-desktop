import 'package:romeu_lanches_admin/core/network/api_client.dart';
import 'package:romeu_lanches_admin/models/business_hours.dart';
import 'package:romeu_lanches_admin/models/store_config.dart';

class StoreService {
  final ApiClient _api;

  const StoreService(this._api);

  Future<StoreConfig> loadConfig() async {
    final json = await _api.get('/admin/config');
    return StoreConfig.fromJson(json as Map<String, dynamic>);
  }

  /// `PATCH /admin/config` — taxa, tempo estimado e formas de pagamento.
  ///
  /// Manda o objeto inteiro: a rota exige os cinco campos. Não altera
  /// `aberta`, que tem rota própria.
  Future<StoreConfig> updateConfig(StoreConfig config) async {
    final json = await _api.patch(
      '/admin/config',
      body: config.toUpdateRequest(),
    );
    return StoreConfig.fromJson(json as Map<String, dynamic>);
  }

  /// `PATCH /admin/config/aberta` — fechar bloqueia **novos** pedidos;
  /// os que já estão em andamento seguem o fluxo normal.
  Future<StoreConfig> setOpen(bool open) async {
    final json = await _api.patch(
      '/admin/config/aberta',
      body: {'aberta': open},
    );
    return StoreConfig.fromJson(json as Map<String, dynamic>);
  }

  /// `GET /admin/horarios` — os 7 dias, de Segunda a Domingo.
  Future<List<BusinessHours>> listHours() async {
    final json = await _api.get('/admin/horarios');
    return (json as List)
        .map((e) => BusinessHours.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `PUT /admin/horarios/{diaSemana}`. Não há POST nem DELETE — os 7 dias
  /// já existem no banco.
  Future<BusinessHours> updateHours(BusinessHours hours) async {
    final json = await _api.put(
      '/admin/horarios/${hours.weekday}',
      body: hours.toRequest(),
    );
    return BusinessHours.fromJson(json as Map<String, dynamic>);
  }
}
