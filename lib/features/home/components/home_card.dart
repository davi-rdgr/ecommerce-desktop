import 'package:romeu_lanches_admin/features/home/data/order_status.dart';
import 'package:romeu_lanches_admin/models/order.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeCard extends StatelessWidget {
  final Order order;

  const HomeCard({super.key, required this.order});

  String get _timeAgo {
    final diff = DateTime.now().difference(order.createdAt).inMinutes;
    return 'há $diff min';
  }

  String get _productsText {
    final counts = <String, int>{};
    for (final p in order.products) {
      counts[p] = (counts[p] ?? 0) + 1;
    }
    return counts.entries.map((e) => '${e.value}x ${e.key}').join(', ');
  }

  String get _priceText {
    return 'R\$ ${order.price.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
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
                '#${order.id}',
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
              _Badge(label: order.deliveryMethod),
              const SizedBox(width: 5),
              _Badge(label: order.paymentMethod),
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
                  _productsText,
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
                onTap: () {},
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
            _ActionButton(label: 'Aceitar', backgroundColor: const Color(0XFF1B9E54)),
          ],
        );
      case OrderStatus.inProgress:
        final label = order.deliveryMethod == 'Entrega' ? 'Saiu p/ entrega' : 'Pronto';
        return _ActionButton(label: label, backgroundColor: const Color(0XFF3B82F6));
      case OrderStatus.ready:
        return _ActionButton(label: 'Concluir', backgroundColor: const Color(0XFF2A1F17));
      case OrderStatus.finished:
        return const SizedBox.shrink();
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;

  const _ActionButton({required this.label, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
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
