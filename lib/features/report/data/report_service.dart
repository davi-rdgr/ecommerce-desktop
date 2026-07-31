import 'package:romeu_lanches_admin/core/network/api_client.dart';
import 'package:romeu_lanches_admin/models/daily_report.dart';
import 'package:romeu_lanches_admin/models/hourly_sales.dart';
import 'package:romeu_lanches_admin/models/revenue_by_payment.dart';

/// Os três relatórios compartilham o mesmo recorte: apenas pedidos concluídos
/// do **dia operacional corrente** (das 2h de um dia às 2h do seguinte, em
/// America/São_Paulo). Nenhum deles aceita parâmetro de data.
class ReportService {
  final ApiClient _api;

  const ReportService(this._api);

  /// `GET /admin/relatorio/dia` — sempre o dia operacional corrente.
  Future<DailyReport> loadToday() async {
    final json = await _api.get('/admin/relatorio/dia');
    return DailyReport.fromJson(json as Map<String, dynamic>);
  }

  /// `GET /admin/relatorio/vendas-por-hora` — as 24 horas do expediente.
  ///
  /// Devolve na ordem em que o backend mandou (`2, 3, …, 23, 0, 1`), que já é a
  /// ordem cronológica do dia operacional. **Não ordenar por hora.**
  Future<List<HourlySales>> loadHourlySales() async {
    final json = await _api.get('/admin/relatorio/vendas-por-hora');
    return (json as List)
        .map((e) => HourlySales.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /admin/relatorio/faturamento-por-forma` — PIX, cartão e dinheiro,
  /// sempre os três, zerados onde não houve venda.
  Future<List<RevenueByPayment>> loadRevenueByPayment() async {
    final json = await _api.get('/admin/relatorio/faturamento-por-forma');
    return (json as List)
        .map((e) => RevenueByPayment.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
