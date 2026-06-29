import 'package:romeu_lanches_admin/components/header/header.dart';
import 'package:romeu_lanches_admin/features/home/components/home_column.dart';
import 'package:romeu_lanches_admin/features/home/components/home_stats.dart';
import 'package:romeu_lanches_admin/features/home/view/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

class HomeView extends StatefulWidget {
  final HomeController controller;

  const HomeView({super.key, required this.controller});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Header(
          title: widget.controller.headerTitle,
          subtitle: widget.controller.headerSubtitle,
        ),
        Expanded(
          child: ColoredBox(
            color: const Color(0XFFF4F1ED),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                  child: SignalBuilder(
                    builder: (context) => Row(
                      spacing: 12,
                      children: widget.controller.homeStats.value
                          .map((stat) => HomeStats(
                                title: stat.title,
                                value: stat.value,
                                color: stat.color,
                              ))
                          .toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(31, 0, 31, 20),
                    child: Scrollbar(
                      controller: _scrollController,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        child: SignalBuilder(
                          builder: (context) => Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 16,
                            children: HomeController.columns
                                .map((col) => HomeColumn(
                                      label: col.label,
                                      color: col.color,
                                      orders: widget.controller.orders.value
                                          .where((o) => o.status == col.status)
                                          .toList(),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
