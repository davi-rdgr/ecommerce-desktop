import 'package:romeu_lanches_admin/features/report/view/report_controller.dart';
import 'package:romeu_lanches_admin/features/report/view/report_view.dart';
import 'package:flutter/material.dart';

class ReportRoute extends StatefulWidget {
  const ReportRoute({super.key});

  @override
  State<ReportRoute> createState() => _ReportRouteState();
}

class _ReportRouteState extends State<ReportRoute> {
  late final ReportController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReportController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ReportView(controller: _controller);
}
