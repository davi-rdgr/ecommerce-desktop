import 'package:romeu_lanches_admin/components/header/header.dart';
import 'package:romeu_lanches_admin/features/home/components/home_column.dart';
import 'package:romeu_lanches_admin/features/home/components/home_stats.dart';
import 'package:romeu_lanches_admin/features/home/components/order_detail_dialog.dart';
import 'package:romeu_lanches_admin/features/home/data/orders_realtime.dart';
import 'package:romeu_lanches_admin/features/home/view/home_controller.dart';
import 'package:romeu_lanches_admin/models/order.dart';
import 'package:romeu_lanches_admin/models/order_detail.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signals_flutter/signals_flutter.dart';

class HomeView extends StatefulWidget {
  final HomeController controller;

  const HomeView({super.key, required this.controller});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _scrollController = ScrollController();

  HomeController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.refresh();
    _controller.startRealtime();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openOrderDetail(Order order) => showOrderDetailDialog(
    context,
    order: order,
    loadDetail: _controller.loadOrderDetail,
    onAdvance: _advance,
    onCancel: _cancel,
    onPrint: _print,
  );

  Future<void> _advance(Order order) async {
    final message = await _controller.advance(order);
    if (message != null) _showMessage(message);
  }

  Future<void> _print(Order order, OrderDetail detail) async {
    final message = await _controller.printTicket(order, detail);
    _showMessage(message ?? 'Comanda #${detail.number} enviada para impressão.');
  }

  Future<void> _cancel(Order order) async {
    if (!await _confirmCancel(order)) return;
    final message = await _controller.cancel(order);
    if (message != null) _showMessage(message);
  }

  /// Cancelar é destrutivo e não tem volta pela API — pede confirmação.
  Future<bool> _confirmCancel(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: Text(
          'Cancelar o pedido #${order.number}?',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2A1F17),
          ),
        ),
        content: Text(
          'O pedido de ${order.userName} sai do painel e a ação não pode ser desfeita.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF7A6A59),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Voltar',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF998875),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE23725),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Cancelar pedido',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        backgroundColor: const Color(0xFF2A1F17),
        behavior: SnackBarBehavior.floating,
        width: 420,
      ),
    );
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
            color: const Color(0XFFF4F1ED),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                  child: SignalBuilder(
                    builder: (context) => Row(
                      spacing: 12,
                      children: [
                        ..._controller.homeStats.value.map(
                          (stat) => HomeStats(
                            title: stat.title,
                            value: stat.value,
                            color: stat.color,
                          ),
                        ),
                        const Spacer(),
                        _RealtimeBadge(
                          status: _controller.realtimeStatus.value,
                        ),
                        const SizedBox(width: 12),
                        _RefreshButton(
                          isLoading: _controller.isLoading.value,
                          onPressed: _controller.refresh,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(31, 0, 31, 20),
                    child: SignalBuilder(builder: (context) => _buildBoard()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBoard() {
    final orders = _controller.orders.value;
    final error = _controller.loadError.value;

    // Enquanto houver pedidos na tela, falha e recarga acontecem por baixo —
    // o atendente não perde o painel de vista no meio do movimento.
    if (orders.isEmpty && _controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (orders.isEmpty && error != null) {
      return _BoardMessage(
        icon: Icons.cloud_off_outlined,
        message: error,
        onRetry: _controller.refresh,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = HomeController.columns.length;
        final totalSpacing = _columnSpacing * (count - 1);
        final fitWidth = (constraints.maxWidth - totalSpacing) / count;
        final fits = fitWidth >= _minColumnWidth;

        Widget board(double columnWidth) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: _columnSpacing,
          children: HomeController.columns
              .map((col) => HomeColumn(
                    label: col.label,
                    color: col.color,
                    width: columnWidth,
                    orders: orders
                        .where((o) => o.status == col.status)
                        .toList(),
                    onOrderTap: _openOrderDetail,
                    onAdvance: _advance,
                    onCancel: _cancel,
                    pendingIds: _controller.pendingIds.value,
                  ))
              .toList(),
        );

        // Cabendo, as colunas dividem a largura toda. Tela estreita: mantém a
        // largura mínima e rola na horizontal — com barra sempre visível e
        // arraste pelo mouse, porque a roda do mouse já rola os cards.
        if (fits) return board(fitWidth);

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {...PointerDeviceKind.values},
          ),
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: 16),
              child: board(_minColumnWidth),
            ),
          ),
        );
      },
    );
  }

  static const double _minColumnWidth = 280;
  static const double _columnSpacing = 16;
}

/// Sem isso, canal caído é indistinguível de noite fraca: a tela fica parada
/// e ninguém sabe se é falta de pedido ou falta de conexão.
class _RealtimeBadge extends StatelessWidget {
  final RealtimeStatus status;

  const _RealtimeBadge({required this.status});

  static const _colors = <RealtimeStatus, Color>{
    RealtimeStatus.live: Color(0xFF1B9E54),
    RealtimeStatus.connecting: Color(0xFFF59E0B),
    RealtimeStatus.offline: Color(0xFF998875),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status]!;

    return Tooltip(
      message: status == RealtimeStatus.live
          ? 'Pedidos novos chegam sozinhos'
          : 'O painel pode estar desatualizado — use Atualizar',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _RefreshButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Recarregar pedidos',
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
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
          foregroundColor: const Color(0xFF2A1F17),
          side: const BorderSide(color: Color(0xFFECE4DA)),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }
}

class _BoardMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback onRetry;

  const _BoardMessage({
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 34, color: const Color(0xFF998875)),
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
                color: const Color(0xFFE23725),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
