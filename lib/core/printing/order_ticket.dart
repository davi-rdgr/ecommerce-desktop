import 'dart:typed_data';

import 'package:romeu_lanches_admin/core/format/currency.dart';
import 'package:romeu_lanches_admin/core/printing/esc_pos_document.dart';
import 'package:romeu_lanches_admin/core/printing/paper_width.dart';
import 'package:romeu_lanches_admin/models/delivery_type.dart';
import 'package:romeu_lanches_admin/models/order.dart';
import 'package:romeu_lanches_admin/models/order_detail.dart';
import 'package:romeu_lanches_admin/models/order_item.dart';
import 'package:romeu_lanches_admin/models/payment_method.dart';

/// Monta a comanda de um pedido. Função pura: pedido entra, bytes ESC/POS
/// saem — dá para testar sem impressora nenhuma.
///
/// Recebe [Order] **e** [OrderDetail] porque o nome do cliente só existe no
/// resumo da lista; o detalhe da API não traz esse campo (ver [OrderDetail]).
abstract final class OrderTicket {
  static Uint8List build({
    required Order order,
    required OrderDetail detail,
    required PaperWidth paper,
  }) {
    final doc = EscPosDocument(paper);

    _header(doc, order: order, detail: detail);
    _routing(doc, order: order, detail: detail);
    _items(doc, detail.items);
    _totals(doc, detail);
    _payment(doc, detail);

    doc.feed(2);
    doc.cut();

    return doc.bytes;
  }

  static void _header(
    EscPosDocument doc, {
    required Order order,
    required OrderDetail detail,
  }) {
    doc.align(EscPosAlign.center);

    doc.size(doubleWidth: true, doubleHeight: true);
    doc.bold(true);
    doc.text('#${detail.number}');
    doc.bold(false);
    doc.size();

    doc.text('ROMEU LANCHES');
    doc.text(_dateTime(detail.createdAt));
    doc.align(EscPosAlign.left);
    doc.rule('=');
  }

  /// O bloco que o entregador lê primeiro: como sai e para onde vai.
  static void _routing(
    EscPosDocument doc, {
    required Order order,
    required OrderDetail detail,
  }) {
    final address = detail.address;
    final isDelivery = detail.deliveryType == DeliveryType.delivery;

    doc.bold(true);
    doc.row(detail.deliveryType.label.toUpperCase(), detail.paymentMethod.label
        .toUpperCase());
    doc.bold(false);
    doc.text('Cliente: ${order.userName}');

    doc.rule();

    if (isDelivery && address != null) {
      doc.bold(true);
      doc.text('ENDERECO DE ENTREGA');
      doc.bold(false);
      doc.text(address.line);
      if (address.complement != null) doc.text('Compl.: ${address.complement}');
      if (address.reference != null) doc.text('Ref.: ${address.reference}');
    } else {
      doc.bold(true);
      doc.text('RETIRADA NO BALCAO');
      doc.bold(false);
    }

    if (detail.note != null && detail.note!.trim().isNotEmpty) {
      doc.rule();
      doc.bold(true);
      doc.text('OBSERVACAO DO PEDIDO');
      doc.bold(false);
      doc.text(detail.note!.trim());
    }
  }

  static void _items(EscPosDocument doc, List<OrderItem> items) {
    doc.rule();
    doc.bold(true);
    doc.text('ITENS');
    doc.bold(false);
    doc.blank();

    for (final item in items) {
      doc.row('${item.quantity}x ${item.name}', brl(item.subtotal));

      for (final addition in item.additions) {
        doc.indented('+ ${addition.name} (${brl(addition.price)})');
      }

      // Observação de item é o que mais gera pedido refeito — vai destacada.
      if (item.note != null && item.note!.trim().isNotEmpty) {
        doc.bold(true);
        doc.indented('** ${item.note!.trim()}');
        doc.bold(false);
      }

      doc.blank();
    }
  }

  static void _totals(EscPosDocument doc, OrderDetail detail) {
    doc.rule();
    doc.row('Subtotal', brl(detail.subtotal));
    if (detail.deliveryFee > 0) {
      doc.row('Taxa de entrega', brl(detail.deliveryFee));
    }

    doc.bold(true);
    doc.size(doubleHeight: true);
    doc.row('TOTAL', brl(detail.total));
    doc.size();
    doc.bold(false);
  }

  /// Fecha a comanda dizendo se o entregador cobra ou não.
  ///
  /// PIX já veio pago: o pedido só entra no kanban depois do webhook aprovar
  /// (§2 do contrato). Cartão e dinheiro entram direto em `NOVO`, ou seja são
  /// cobrados na hora da entrega.
  static void _payment(EscPosDocument doc, OrderDetail detail) {
    final onDelivery = detail.deliveryType == DeliveryType.delivery
        ? 'NA ENTREGA'
        : 'NA RETIRADA';

    doc.rule('=');
    doc.align(EscPosAlign.center);
    doc.bold(true);

    switch (detail.paymentMethod) {
      case PaymentMethod.pix:
        doc.text('PAGO ONLINE VIA PIX');
        doc.text('NAO COBRAR');
      case PaymentMethod.card:
        doc.text('COBRAR NA MAQUININHA $onDelivery');
        doc.size(doubleHeight: true);
        doc.text(brl(detail.total));
        doc.size();
      case PaymentMethod.cash:
        doc.text('COBRAR EM DINHEIRO $onDelivery');
        doc.size(doubleHeight: true);
        doc.text(brl(detail.total));
        doc.size();
    }

    doc.bold(false);
    doc.align(EscPosAlign.left);
    doc.rule('=');
  }

  /// `25/07/2026 19:42` — sem `intl` no projeto, é na mão mesmo.
  static String _dateTime(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} '
        '${two(value.hour)}:${two(value.minute)}';
  }
}
