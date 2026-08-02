import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_admin/core/format/currency.dart';
import 'package:romeu_lanches_admin/models/delivery_type.dart';
import 'package:romeu_lanches_admin/models/order.dart';
import 'package:romeu_lanches_admin/models/order_detail.dart';
import 'package:romeu_lanches_admin/models/order_item.dart';
import 'package:romeu_lanches_admin/models/order_status.dart';

const _darkBrown = Color(0xFF2A1F17);
const _mutedText = Color(0xFF998875);
const _bodyText = Color(0xFF7A6A59);
const _hairline = Color(0xFFEFEAE3);

Future<void> showOrderDetailDialog(
  BuildContext context, {
  required Order order,
  required Future<OrderDetail> Function(String id) loadDetail,
  required Future<void> Function(Order order) onAdvance,
  required Future<void> Function(Order order) onCancel,
  required Future<void> Function(Order order, OrderDetail detail) onPrint,
}) {
  return showDialog(
    context: context,
    builder: (_) => OrderDetailDialog(
      order: order,
      loadDetail: loadDetail,
      onAdvance: onAdvance,
      onCancel: onCancel,
      onPrint: onPrint,
    ),
  );
}

/// Detalhe completo do pedido, aberto ao clicar num card do kanban.
///
/// O card só tem o resumo, então os itens vêm de uma requisição própria —
/// daí os estados de carregando e erro.
class OrderDetailDialog extends StatefulWidget {
  final Order order;
  final Future<OrderDetail> Function(String id) loadDetail;
  final Future<void> Function(Order order) onAdvance;
  final Future<void> Function(Order order) onCancel;

  /// Recebe os dois porque a comanda precisa do nome do cliente, que só existe
  /// no resumo — o detalhe da API não traz esse campo (ver [OrderDetail]).
  final Future<void> Function(Order order, OrderDetail detail) onPrint;

  const OrderDetailDialog({
    super.key,
    required this.order,
    required this.loadDetail,
    required this.onAdvance,
    required this.onCancel,
    required this.onPrint,
  });

  @override
  State<OrderDetailDialog> createState() => _OrderDetailDialogState();
}

class _OrderDetailDialogState extends State<OrderDetailDialog> {
  late Future<OrderDetail> _future;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _future = widget.loadDetail(widget.order.id);
  }

  void _retry() =>
      setState(() => _future = widget.loadDetail(widget.order.id));

  /// O spooler responde rápido, mas a modal pode ser fechada antes — daí o
  /// `mounted` antes de mexer no estado.
  Future<void> _print(OrderDetail detail) async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);

    try {
      await widget.onPrint(widget.order, detail);
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(order: widget.order),
            Flexible(
              child: FutureBuilder<OrderDetail>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _LoadingBody();
                  }
                  if (snapshot.hasError) {
                    return _ErrorBody(
                      message: _messageFor(snapshot.error!),
                      onRetry: _retry,
                    );
                  }
                  final detail = snapshot.data!;
                  return _DetailBody(
                    detail: detail,
                    isPrinting: _isPrinting,
                    onPrint: () => _print(detail),
                  );
                },
              ),
            ),
            FutureBuilder<OrderDetail>(
              future: _future,
              builder: (context, snapshot) {
                // O status do detalhe é mais fresco que o do card, então é
                // ele que decide quais ações aparecem.
                final status = snapshot.data?.status;
                if (status == null) return const SizedBox.shrink();
                return _ActionFooter(
                  order: widget.order,
                  status: status,
                  onAdvance: widget.onAdvance,
                  onCancel: widget.onCancel,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _messageFor(Object error) =>
      'Não foi possível carregar o pedido.\n$error';
}

class _Header extends StatelessWidget {
  final Order order;

  const _Header({required this.order});

  static const _statusColors = <OrderStatus, Color>{
    OrderStatus.awaitingPayment: Color(0xFF7C3AED),
    OrderStatus.newOrder: Color(0xFFE23725),
    OrderStatus.inProgress: Color(0xFFF59E0B),
    OrderStatus.ready: Color(0xFF3B82F6),
    OrderStatus.finished: Color(0xFF1B9E54),
    OrderStatus.canceled: Color(0xFF998875),
  };

  String get _time {
    final at = order.createdAt;
    final hour = at.hour.toString().padLeft(2, '0');
    final minute = at.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColors[order.status]!;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#${order.number}',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _darkBrown,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        order.status.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${order.userName} · às $_time',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: _mutedText,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20, color: _mutedText),
            tooltip: 'Fechar',
          ),
        ],
      ),
    );
  }
}

/// Mesmas ações do card, com o pedido inteiro à vista.
///
/// A modal fecha assim que a ação é disparada: a confirmação do cancelamento
/// e o aviso de erro aparecem sobre o kanban, que é onde o resultado importa.
class _ActionFooter extends StatelessWidget {
  final Order order;
  final OrderStatus status;
  final Future<void> Function(Order order) onAdvance;
  final Future<void> Function(Order order) onCancel;

  const _ActionFooter({
    required this.order,
    required this.status,
    required this.onAdvance,
    required this.onCancel,
  });

  /// Rótulo da próxima etapa, ou `null` se não houver uma.
  String? get _advanceLabel => switch (status) {
    OrderStatus.newOrder => 'Aceitar',
    OrderStatus.inProgress =>
      order.deliveryType == DeliveryType.delivery ? 'Saiu p/ entrega' : 'Pronto',
    OrderStatus.ready => 'Concluir',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final advanceLabel = _advanceLabel;

    // Cancelado, concluído e aguardando pagamento não têm ação manual.
    if (advanceLabel == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFBF9F7),
        border: Border(top: BorderSide(color: _hairline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onCancel(order);
            },
            child: Text(
              'Cancelar pedido',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE23725),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onAdvance(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B9E54),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            child: Text(
              advanceLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 220,
    child: Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(strokeWidth: 2.4),
      ),
    ),
  );
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 30,
                color: _mutedText,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: _bodyText,
                  height: 1.4,
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
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final OrderDetail detail;
  final VoidCallback onPrint;
  final bool isPrinting;

  const _DetailBody({
    required this.detail,
    required this.onPrint,
    required this.isPrinting,
  });

  @override
  Widget build(BuildContext context) {
    final address = detail.address;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Badge(label: detail.deliveryType.label),
              const SizedBox(width: 6),
              _Badge(label: detail.paymentMethod.label),
            ],
          ),
          const SizedBox(height: 16),
          if (detail.deliveryType == DeliveryType.delivery && address != null)
            _InfoBlock(
              icon: Icons.location_on_outlined,
              title: address.line,
              lines: [
                if (address.complement != null) address.complement!,
                if (address.reference != null) address.reference!,
              ],
            )
          else
            const _InfoBlock(
              icon: Icons.storefront_outlined,
              title: 'Retirada no balcão',
              lines: [],
            ),
          if (detail.note != null) ...[
            const SizedBox(height: 10),
            _InfoBlock(
              icon: Icons.sticky_note_2_outlined,
              title: detail.note!,
              lines: const [],
              highlight: true,
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'ITENS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _mutedText,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in detail.items) _ItemRow(item: item),
          const SizedBox(height: 8),
          const Divider(color: _hairline, height: 24),
          _TotalRow(label: 'Subtotal', value: detail.subtotal),
          if (detail.deliveryFee > 0)
            _TotalRow(label: 'Taxa de entrega', value: detail.deliveryFee),
          const SizedBox(height: 6),
          _TotalRow(label: 'Total', value: detail.total, emphasized: true),
          const SizedBox(height: 18),
          Center(child: _PrintButton(onPressed: onPrint, isBusy: isPrinting)),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItem item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _hairline,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${item.quantity}×',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _darkBrown,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _darkBrown,
                  ),
                ),
                for (final addition in item.additions)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '+ ${addition.name} (${brl(addition.price)})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: _bodyText,
                      ),
                    ),
                  ),
                if (item.note != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.note!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            brl(item.subtotal),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _darkBrown,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool emphasized;

  const _TotalRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: emphasized ? 14 : 13,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w400,
              color: emphasized ? _darkBrown : _bodyText,
            ),
          ),
          Text(
            brl(value),
            style: emphasized
                ? GoogleFonts.bricolageGrotesque(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _darkBrown,
                  )
                : GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: _bodyText,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Manda a comanda para a térmica.
///
/// Fica sempre habilitado, em qualquer status: reimprimir é o conserto normal
/// para papel que acabou, comanda perdida ou entregador trocado.
class _PrintButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isBusy;

  const _PrintButton({required this.onPressed, required this.isBusy});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: isBusy ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isBusy ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isBusy ? const Color(0xFFEBB5AE) : const Color(0xFFE23725),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isBusy)
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(Icons.print_outlined, size: 15, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                isBusy ? 'Imprimindo…' : 'Imprimir comanda',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> lines;
  final bool highlight;

  const _InfoBlock({
    required this.icon,
    required this.title,
    required this.lines,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFFEF3C7) : const Color(0xFFF7F4F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: highlight ? amber : _mutedText),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: highlight ? const Color(0xFF92400E) : _darkBrown,
                    height: 1.35,
                  ),
                ),
                for (final line in lines)
                  Text(
                    line,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: _bodyText,
                      height: 1.35,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  static const _styles = <String, ({Color bg, Color fg})>{
    'Entrega': (bg: Color(0xFFFBE7E3), fg: Color(0xFFE23725)),
    'Retirada': (bg: Color(0xFFEDE9FE), fg: Color(0xFF7C3AED)),
    'PIX': (bg: Color(0xFFE6F4EC), fg: Color(0xFF1B9E54)),
    'Cartão': (bg: Color(0xFFE0F2FE), fg: Color(0xFF0369A1)),
    'Dinheiro': (bg: Color(0xFFFEF3C7), fg: Color(0xFFD97706)),
  };

  @override
  Widget build(BuildContext context) {
    final style =
        _styles[label] ?? (bg: const Color(0xFFE5E7EB), fg: const Color(0xFF374151));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        color: style.bg,
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: style.fg,
        ),
      ),
    );
  }
}
