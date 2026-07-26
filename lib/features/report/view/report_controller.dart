import 'package:romeu_lanches_admin/core/network/api_exception.dart';
import 'package:romeu_lanches_admin/features/report/data/report_service.dart';
import 'package:romeu_lanches_admin/models/daily_report.dart';
import 'package:signals_flutter/signals_flutter.dart';

class ReportController {
  final ReportService _service;

  ReportController(this._service);

  final headerTitle = 'Relatório do dia';
  final headerSubtitle = 'Desempenho de hoje';

  final report = signal<DailyReport?>(null);
  final isLoading = signal(false);
  final loadError = signal<String?>(null);

  Future<void> load() async {
    isLoading.value = true;
    loadError.value = null;

    try {
      report.value = await _service.loadToday();
    } on ApiException catch (e) {
      loadError.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    report.dispose();
    isLoading.dispose();
    loadError.dispose();
  }
}
