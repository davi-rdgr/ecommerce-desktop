import 'package:romeu_lanches_admin/components/header/header.dart';
import 'package:romeu_lanches_admin/core/format/currency.dart';
import 'package:romeu_lanches_admin/features/report/view/report_controller.dart';
import 'package:romeu_lanches_admin/models/daily_report.dart';
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
        message: _controller.loadError.value ??
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
                  const SizedBox(
                    width: 264,
                    child: Column(
                      children: [
                        _UnavailableCard(
                          title: 'Vendas por horário',
                          message:
                              'O relatório da API entrega só os totais do dia. '
                              'Para o gráfico por hora seria preciso um endpoint '
                              'novo no backend.',
                        ),
                        SizedBox(height: 16),
                        _UnavailableCard(
                          title: 'Por forma de pagamento',
                          message:
                              'A API não quebra o faturamento por PIX, cartão e '
                              'dinheiro.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: _mutedText,
            ),
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

// ─── Sem dado na API ──────────────────────────────────────────────────────────

class _UnavailableCard extends StatelessWidget {
  final String title;
  final String message;

  const _UnavailableCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_outlined, size: 16, color: _mutedText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _mutedText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: _mutedText,
              height: 1.4,
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
