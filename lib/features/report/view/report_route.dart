import 'package:romeu_lanches_admin/core/di/app_dependencies.dart';
import 'package:romeu_lanches_admin/features/report/view/report_view.dart';
import 'package:flutter/material.dart';

class ReportRoute extends StatelessWidget {
  const ReportRoute({super.key});

  @override
  Widget build(BuildContext context) =>
      ReportView(controller: deps.reportFullDependencies.report);
}
