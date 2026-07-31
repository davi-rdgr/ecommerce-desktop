import 'package:romeu_lanches_admin/core/network/api_exception.dart';
import 'package:romeu_lanches_admin/features/report/data/report_service.dart';
import 'package:romeu_lanches_admin/models/daily_report.dart';
import 'package:romeu_lanches_admin/models/hourly_sales.dart';
import 'package:romeu_lanches_admin/models/revenue_by_payment.dart';
import 'package:signals_flutter/signals_flutter.dart';

class ReportController {
  final ReportService _service;

  ReportController(this._service);

  final headerTitle = 'Relatório do dia';
  final headerSubtitle = 'Desempenho de hoje';

  final report = signal<DailyReport?>(null);

  /// As 24 horas do expediente, na ordem que o backend mandou (2h → 1h).
  final hourlySales = signal<List<HourlySales>>([]);

  /// PIX, cartão e dinheiro — os três sempre presentes.
  final revenueByPayment = signal<List<RevenueByPayment>>([]);

  final isLoading = signal(false);
  final loadError = signal<String?>(null);

  Future<void> load() async {
    isLoading.value = true;
    loadError.value = null;

    try {
      // Os três recortes são do mesmo dia operacional e vêm do mesmo módulo do
      // backend: ou vão juntos, ou falham juntos (401, servidor fora). Um
      // `Future.wait` busca em paralelo e ainda marca como tratado o erro das
      // outras chamadas quando a primeira estoura.
      final responses = await Future.wait([
        _service.loadToday(),
        _service.loadHourlySales(),
        _service.loadRevenueByPayment(),
      ]);

      report.value = responses[0] as DailyReport;
      hourlySales.value = responses[1] as List<HourlySales>;
      revenueByPayment.value = responses[2] as List<RevenueByPayment>;
    } on ApiException catch (e) {
      loadError.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    report.dispose();
    hourlySales.dispose();
    revenueByPayment.dispose();
    isLoading.dispose();
    loadError.dispose();
  }
}
