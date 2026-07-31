import 'package:romeu_lanches_admin/components/header/header.dart';
import 'package:romeu_lanches_admin/core/format/currency.dart';
import 'package:romeu_lanches_admin/features/report/view/report_controller.dart';
import 'package:romeu_lanches_admin/models/daily_report.dart';
import 'package:romeu_lanches_admin/models/hourly_sales.dart';
import 'package:romeu_lanches_admin/models/revenue_by_payment.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signals_flutter/signals_flutter.dart';

const _darkBrown = Color(0xFF2A1F17);
const _mutedText = Color(0xFF998875);
const _hairline = Color(0xFFF0EBE5);
const _accent = Color(0xFFE23725);

class ReportView extends StatefulWidget {
  final ReportController controller;

  const ReportView({super.key, required this.controller});

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  ReportController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Header(
          title: _controller.headerTitle,
          subtitle: _controller.headerSubtitle,
        ),
        Expanded(
          child: ColoredBox(
            color: const Color(0xFFF4F1ED),
            child: SignalBuilder(builder: (context) => _buildBody()),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final report = _controller.report.value;

    if (report == null && _controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (report == null) {
      return _ErrorState(
        message:
            _controller.loadError.value ??
            'Não foi possível carregar o relatório.',
        onRetry: _controller.load,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1248),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(
                date: report.date,
                isLoading: _controller.isLoading.value,
                onRefresh: _controller.load,
              ),
              const SizedBox(height: 14),
              _StatsRow(report: report),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _TopSellersCard(sellers: report.topSellers)),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 264,
                    child: _PaymentBreakdownCard(
                      entries: _controller.revenueByPayment.value,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Série de 24 horas ocupa a largura toda: espremida na coluna de
              // 264 as barras não caberiam com os rótulos.
              _HourlySalesCard(hours: _controller.hourlySales.value),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final DateTime date;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _TopBar({
    required this.date,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return Row(
      children: [
        Text(
          'Fechamento de $day/$month · considera apenas pedidos concluídos',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _mutedText),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onRefresh,
          icon: isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh, size: 17),
          label: Text(
            'Atualizar',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _darkBrown,
            side: const BorderSide(color: Color(0xFFECE4DA)),
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Indicadores ──────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final DailyReport report;

  const _StatsRow({required this.report});

  @override
  Widget build(BuildContext context) {
    final champion = report.topSellers.isEmpty ? null : report.topSellers.first;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'FATURAMENTO HOJE',
            value: brl(report.revenue),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'PEDIDOS CONCLUÍDOS',
            value: '${report.orderCount}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'TICKET MÉDIO',
            value: brl(report.averageTicket),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'ITEM CAMPEÃO',
            value: champion?.name ?? '—',
            subtitle: champion == null
                ? 'Nenhuma venda ainda'
                : '${champion.quantity} vendidos',
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
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : _mutedText;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? _darkBrown : Colors.white,
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
              color: isDark ? Colors.white : _darkBrown,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.65)
                    : _mutedText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Mais vendidos ────────────────────────────────────────────────────────────

class _TopSellersCard extends StatelessWidget {
  final List<TopSeller> sellers;

  const _TopSellersCard({required this.sellers});

  @override
  Widget build(BuildContext context) {
    final max = sellers.isEmpty
        ? 1
        : sellers.map((s) => s.quantity).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
              color: _darkBrown,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Top 10 do dia, por quantidade',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _mutedText),
          ),
          const SizedBox(height: 12),
          if (sellers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Nenhum pedido concluído hoje ainda.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: _mutedText,
                  ),
                ),
              ),
            )
          else
            for (int i = 0; i < sellers.length; i++) ...[
              _TopSellerRow(rank: i + 1, seller: sellers[i], max: max),
              if (i < sellers.length - 1)
                const Divider(height: 1, thickness: 1, color: _hairline),
            ],
        ],
      ),
    );
  }
}

class _TopSellerRow extends StatelessWidget {
  final int rank;
  final TopSeller seller;
  final int max;

  const _TopSellerRow({
    required this.rank,
    required this.seller,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$rank',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: rank <= 3 ? _accent : _mutedText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 200,
            child: Text(
              seller.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _darkBrown,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: seller.quantity / max,
                backgroundColor: _hairline,
                valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                minHeight: 7,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            child: Text(
              '${seller.quantity}x',
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _darkBrown,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Por forma de pagamento ───────────────────────────────────────────────────

class _PaymentBreakdownCard extends StatelessWidget {
  final List<RevenueByPayment> entries;

  const _PaymentBreakdownCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<double>(0, (sum, e) => sum + e.revenue);

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
            'Por forma de pagamento',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _darkBrown,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Faturamento do dia',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _mutedText),
          ),
          const SizedBox(height: 14),
          // As três formas vêm sempre; a lista só fica vazia se a chamada não
          // tiver chegado.
          for (int i = 0; i < entries.length; i++) ...[
            _PaymentRow(entry: entries[i], total: total),
            if (i < entries.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final RevenueByPayment entry;
  final double total;

  const _PaymentRow({required this.entry, required this.total});

  @override
  Widget build(BuildContext context) {
    // Dia sem venda nenhuma vem com as três formas zeradas — barra vazia, não
    // divisão por zero.
    final share = total == 0 ? 0.0 : entry.revenue / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              entry.method.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _darkBrown,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${(share * 100).round()}%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _mutedText,
              ),
            ),
            const Spacer(),
            Text(
              brl(entry.revenue),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _darkBrown,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: share,
            backgroundColor: _hairline,
            valueColor: const AlwaysStoppedAnimation<Color>(_accent),
            minHeight: 7,
          ),
        ),
      ],
    );
  }
}

// ─── Vendas por horário ───────────────────────────────────────────────────────

class _HourlySalesCard extends StatelessWidget {
  final List<HourlySales> hours;

  const _HourlySalesCard({required this.hours});

  @override
  Widget build(BuildContext context) {
    final peak = hours.fold<int>(
      0,
      (max, h) => h.quantity > max ? h.quantity : max,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
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
              color: _darkBrown,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Pedidos concluídos por hora — o expediente vira às 2h da madrugada',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _mutedText),
          ),
          const SizedBox(height: 16),
          if (hours.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Sem dados de movimento por hora.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: _mutedText,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 132,
              // Na ordem em que o backend mandou (2h → 1h): é a ordem
              // cronológica do expediente. Ordenar por hora aqui jogaria a
              // madrugada para a esquerda e partiria a curva em duas.
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final hour in hours)
                    Expanded(
                      child: _HourBar(entry: hour, peak: peak),
                    ),
                ],
              ),
            ),
          if (hours.isNotEmpty && peak == 0) ...[
            const SizedBox(height: 10),
            Text(
              'Nenhum pedido concluído neste expediente ainda.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: _mutedText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HourBar extends StatelessWidget {
  final HourlySales entry;
  final int peak;

  const _HourBar({required this.entry, required this.peak});

  /// Altura da barra mais alta; horas sem venda ficam só com o toco de 6px.
  static const _maxBarHeight = 84.0;

  @override
  Widget build(BuildContext context) {
    final ratio = peak == 0 ? 0.0 : entry.quantity / peak;

    final Color color;
    if (entry.quantity == 0) {
      color = _hairline;
    } else if (entry.quantity == peak) {
      color = _accent;
    } else {
      color = _accent.withValues(alpha: 0.38);
    }

    return Tooltip(
      message:
          '${entry.label} · ${entry.quantity} '
          '${entry.quantity == 1 ? 'pedido' : 'pedidos'}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            entry.quantity == 0 ? '' : '${entry.quantity}',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _darkBrown,
            ),
          ),
          const SizedBox(height: 4),
          FractionallySizedBox(
            widthFactor: 0.6,
            child: Container(
              height: 6 + ratio * _maxBarHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            entry.label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              color: _mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 34, color: _mutedText),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: const Color(0xFF7A6A59),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Tentar novamente',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
