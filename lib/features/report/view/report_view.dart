import 'dart:math';

import 'package:romeu_lanches_admin/components/header/header.dart';
import 'package:romeu_lanches_admin/features/report/view/report_controller.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportView extends StatelessWidget {
  final ReportController controller;

  const ReportView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Header(
          title: controller.headerTitle,
          subtitle: controller.headerSubtitle,
        ),
        Expanded(
          child: ColoredBox(
            color: const Color(0xFFF4F1ED),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 1248,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _StatsRow(),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Expanded(child: _HourlyChartCard()),
                          SizedBox(width: 16),
                          SizedBox(
                            width: 264,
                            child: Column(
                              children: [
                                _PaymentCard(),
                                SizedBox(height: 16),
                                _TopItemsCard(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final s = ReportController.stats;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Faturamento hoje',
            value: s.revenue,
            subtitle: s.revenueChange,
            subtitleColor: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Pedidos hoje',
            value: '${s.orders}',
            subtitle: s.ordersActive,
            subtitleColor: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Ticket médio',
            value: s.avgTicket,
            subtitle: s.avgTicketChange,
            subtitleColor: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Item campeão',
            value: s.topItem,
            subtitle: s.topItemSub,
            isDark: true,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color? subtitleColor;
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.subtitleColor,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF2A1F17) : Colors.white;
    final titleColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : const Color(0xFF998875);
    final valueColor = isDark ? Colors.white : const Color(0xFF2A1F17);
    final subColor = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : (subtitleColor ?? const Color(0xFF998875));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: subColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Hourly chart ─────────────────────────────────────────────────────────────

class _HourlyChartCard extends StatelessWidget {
  const _HourlyChartCard();

  static const _data = ReportController.hourlySales;
  static const _barGradient = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xFFE23725), Color(0xFFF97316)],
  );

  @override
  Widget build(BuildContext context) {
    final maxCount = _data.map((d) => d.count).reduce(max);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vendas por horário',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2A1F17),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 230,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _data.map((d) {
                final barH = (d.count / maxCount) * 180.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${d.count}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2A1F17),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: barH,
                          decoration: BoxDecoration(
                            gradient: _barGradient,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          d.hour,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF998875),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Payment methods ──────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  const _PaymentCard();

  static const _methods = ReportController.paymentMethods;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Por forma de pagamento',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2A1F17),
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < _methods.length; i++) ...[
            _PaymentBar(
              label: _methods[i].label,
              pct: _methods[i].pct,
              color: _methods[i].color,
            ),
            if (i < _methods.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _PaymentBar extends StatelessWidget {
  final String label;
  final int pct;
  final Color color;

  const _PaymentBar({
    required this.label,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2A1F17),
              ),
            ),
            const Spacer(),
            Text(
              '$pct%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF998875),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100,
            backgroundColor: const Color(0xFFF0EBE5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 7,
          ),
        ),
      ],
    );
  }
}

// ─── Top items ────────────────────────────────────────────────────────────────

class _TopItemsCard extends StatelessWidget {
  const _TopItemsCard();

  static const _items = ReportController.topItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mais vendidos',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2A1F17),
            ),
          ),
          const SizedBox(height: 4),
          for (int i = 0; i < _items.length; i++) ...[
            _TopItemRow(rank: i + 1, name: _items[i].name, count: _items[i].count),
            if (i < _items.length - 1)
              const Divider(height: 1, thickness: 1, color: Color(0xFFF0EBE5)),
          ],
        ],
      ),
    );
  }
}

class _TopItemRow extends StatelessWidget {
  final int rank;
  final String name;
  final int count;

  const _TopItemRow({
    required this.rank,
    required this.name,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$rank',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFE23725),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2A1F17),
              ),
            ),
          ),
          Text(
            '${count}x',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF998875),
            ),
          ),
        ],
      ),
    );
  }
}
