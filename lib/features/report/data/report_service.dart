import 'package:romeu_lanches_admin/core/network/api_client.dart';
import 'package:romeu_lanches_admin/models/daily_report.dart';

class ReportService {
  final ApiClient _api;

  const ReportService(this._api);

  /// `GET /admin/relatorio/dia` — sempre o dia de hoje; a API não aceita data.
  Future<DailyReport> loadToday() async {
    final json = await _api.get('/admin/relatorio/dia');
    return DailyReport.fromJson(json as Map<String, dynamic>);
  }
}
