import 'package:romeu_lanches_admin/core/network/api_client.dart';
import 'package:romeu_lanches_admin/features/report/data/report_service.dart';
import 'package:romeu_lanches_admin/features/report/view/report_controller.dart';

class ReportFullDependencies {
  late final ReportService reportService;
  late final ReportController report;

  ReportFullDependencies(ApiClient api) {
    reportService = ReportService(api);
    report = ReportController(reportService);
  }
}
