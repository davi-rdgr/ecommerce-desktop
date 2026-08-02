import 'package:romeu_lanches_admin/core/format/currency.dart';
import 'package:romeu_lanches_admin/models/delivery_type.dart';
import 'package:romeu_lanches_admin/models/order.dart';
import 'package:romeu_lanches_admin/models/order_status.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeCard extends StatelessWidget {
  final Order order;

  /// Abre o detalhe do pedido — a lista não traz os itens.
  final VoidCallback onTap;

  /// Manda o pedido para a próxima etapa (aceitar / pronto / concluir).
  final VoidCallback onAdvance;

  final VoidCallback onCancel;

  /// Transição em voo — trava os botões contra clique duplo.
  final bool isBusy;

  const HomeCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onAdvance,
    required this.onCancel,
    required this.isBusy,
  });

  String get _timeAgo {
    // Relógio do desktop atrasado em relação ao servidor deixa `criadoEm` no
    // futuro — sem o clamp o card mostraria tempo negativo.
    final total = DateTime.now().difference(order.createdAt);
    final minutes = total.inMinutes < 0 ? 0 : total.inMinutes;

    if (minutes < 60) return 'há $minutes min';

    final hours = minutes ~/ 60;
    if (hours < 24) {
      final rest = minutes % 60;
      if (rest == 0) return 'há ${hours}h';
      return 'há ${hours}h${rest.toString().padLeft(2, '0')} min';
    }

    final days = hours ~/ 24;
    if (days < 30) return 'há $days ${days == 1 ? 'dia' : 'dias'} atrás';

    // A fila ativa vem inteira do backend, sem corte por data: um pedido
    // esquecido em EM_PREPARO envelhece para sempre e cairia em "há 400 dias".
    final months = days ~/ 30;
    return 'há $months ${months == 1 ? 'mês' : 'meses'} atrás';
  }

  String get _itemsText =>
      '${order.itemCount} ${order.itemCount == 1 ? 'item' : 'itens'}';

  String get _priceText => brl(order.price);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: _buildCard()),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0XFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${order.number}',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0XFF2A1F17),
                ),
              ),
              Text(
                _timeAgo,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: const Color(0XFFA89684),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Badge(label: order.deliveryType.label),
              const SizedBox(width: 5),
              _Badge(label: order.paymentMethod.label),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.userName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0XFF2A1F17),
                  ),
                ),
                Text(
                  _itemsText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0XFF7A6A59),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _priceText,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0XFF2A1F17),
                ),
              ),
              _buildActions(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    switch (order.status) {
      case OrderStatus.newOrder:
        return Row(
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: isBusy ? null : onCancel,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0XFFFBE7E3),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Color(0XFFE23725),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _ActionButton(
              label: 'Aceitar',
              backgroundColor: const Color(0XFF1B9E54),
              onPressed: onAdvance,
              isBusy: isBusy,
            ),
          ],
        );
      case OrderStatus.inProgress:
        final label = order.deliveryType == DeliveryType.delivery
            ? 'Saiu p/ entrega'
            : 'Pronto';
        return _ActionButton(
          label: label,
          backgroundColor: const Color(0XFF3B82F6),
          onPressed: onAdvance,
          isBusy: isBusy,
        );
      case OrderStatus.ready:
        return _ActionButton(
          label: 'Concluir',
          backgroundColor: const Color(0XFF2A1F17),
          onPressed: onAdvance,
          isBusy: isBusy,
        );
      // Concluído não tem próxima ação. Aguardando pagamento e cancelado nunca
      // chegam a ser renderizados — não têm coluna no kanban.
      case OrderStatus.finished:
      case OrderStatus.awaitingPayment:
      case OrderStatus.canceled:
        return const SizedBox.shrink();
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final bool isBusy;

  const _ActionButton({
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isBusy ? null : onPressed,
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: backgroundColor.withValues(alpha: 0.45),
        disabledForegroundColor: Colors.white,
        enabledMouseCursor: SystemMouseCursors.click,
        foregroundColor: const Color(0XFFFFFFFF),
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  static final _styles = <String, ({Color bg, Color fg})>{
    'Entrega':  (bg: const Color(0XFFFBE7E3), fg: const Color(0XFFE23725)),
    'Retirada': (bg: const Color(0XFFEDE9FE), fg: const Color(0XFF7C3AED)),
    'PIX':      (bg: const Color(0XFFE6F4EC), fg: const Color(0XFF1B9E54)),
    'Cartão':   (bg: const Color(0XFFE0F2FE), fg: const Color(0XFF0369A1)),
    'Dinheiro': (bg: const Color(0XFFFEF3C7), fg: const Color(0XFFD97706)),
  };

  @override
  Widget build(BuildContext context) {
    final style = _styles[label] ?? (bg: const Color(0XFFE5E7EB), fg: const Color(0XFF374151));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
