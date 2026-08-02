import 'package:flutter_test/flutter_test.dart';
import 'package:romeu_lanches_admin/core/printing/order_ticket.dart';
import 'package:romeu_lanches_admin/core/printing/paper_width.dart';
import 'package:romeu_lanches_admin/models/delivery_type.dart';
import 'package:romeu_lanches_admin/models/order.dart';
import 'package:romeu_lanches_admin/models/order_address.dart';
import 'package:romeu_lanches_admin/models/order_detail.dart';
import 'package:romeu_lanches_admin/models/order_item.dart';
import 'package:romeu_lanches_admin/models/order_status.dart';
import 'package:romeu_lanches_admin/models/payment_method.dart';

import 'escpos_preview.dart';

final _createdAt = DateTime(2026, 7, 25, 19, 42);

Order _order({
  PaymentMethod payment = PaymentMethod.cash,
  DeliveryType delivery = DeliveryType.delivery,
  String userName = 'João da Conceição',
}) => Order(
  id: 'uuid',
  number: 1042,
  status: OrderStatus.newOrder,
  deliveryType: delivery,
  paymentMethod: payment,
  userName: userName,
  itemCount: 2,
  price: 57.80,
  createdAt: _createdAt,
);

OrderDetail _detail({
  PaymentMethod payment = PaymentMethod.cash,
  DeliveryType delivery = DeliveryType.delivery,
  String? note,
  double deliveryFee = 8.00,
  List<OrderItem>? items,
}) => OrderDetail(
  id: 'uuid',
  number: 1042,
  status: OrderStatus.newOrder,
  deliveryType: delivery,
  paymentMethod: payment,
  address: delivery == DeliveryType.delivery
      ? const OrderAddress(
          street: 'Av. Brasil',
          number: '1200',
          district: 'Centro',
          complement: 'Apto 302',
          reference: 'portão azul',
        )
      : null,
  subtotal: 49.80,
  deliveryFee: deliveryFee,
  total: 49.80 + deliveryFee,
  note: note,
  createdAt: _createdAt,
  items: items ?? const [
    OrderItem(
      id: '1',
      name: 'X-Tudo',
      unitPrice: 20.90,
      quantity: 2,
      subtotal: 49.80,
      note: 'sem cebola',
      additions: [OrderItemAddition(id: 'a', name: 'Bacon', price: 4.00)],
    ),
  ],
);

List<String> _print({
  PaymentMethod payment = PaymentMethod.cash,
  DeliveryType delivery = DeliveryType.delivery,
  String? note,
  double deliveryFee = 8.00,
  List<OrderItem>? items,
  PaperWidth paper = PaperWidth.mm80,
  String userName = 'João da Conceição',
}) => previewLines(
  OrderTicket.build(
    order: _order(payment: payment, delivery: delivery, userName: userName),
    detail: _detail(
      payment: payment,
      delivery: delivery,
      note: note,
      deliveryFee: deliveryFee,
      items: items,
    ),
    paper: paper,
  ),
);

void main() {
  group('identificação', () {
    test('traz número, data e cliente', () {
      final lines = _print();

      expect(lines, contains('#1042'));
      expect(lines, contains('25/07/2026 19:42'));
      expect(lines, contains('Cliente: João da Conceição'));
    });

    test('o nome do cliente vem do resumo, não do detalhe', () {
      // OrderDetail não tem esse campo — se a comanda passasse a ler só o
      // detalhe, o entregador ficaria sem saber para quem é.
      expect(_print(userName: 'Marta Silva'), contains('Cliente: Marta Silva'));
    });
  });

  group('entrega', () {
    test('entrega imprime endereço, complemento e referência', () {
      final lines = _print(delivery: DeliveryType.delivery);

      expect(lines, contains('ENDERECO DE ENTREGA'));
      // O travessão de `OrderAddress.line` não existe no CP860 e cai para
      // hífen — legível, em vez do `?` que uma página de código errada daria.
      expect(lines, contains('Av. Brasil, 1200 - Centro'));
      expect(lines, contains('Compl.: Apto 302'));
      expect(lines, contains('Ref.: portão azul'));
    });

    test('retirada não inventa endereço', () {
      final lines = _print(delivery: DeliveryType.pickup);

      expect(lines, contains('RETIRADA NO BALCAO'));
      expect(lines, isNot(contains('ENDERECO DE ENTREGA')));
    });
  });

  group('itens', () {
    test('quantidade, nome, adicional e observação do item', () {
      final lines = _print();

      expect(lines.any((l) => l.startsWith('2x X-Tudo')), isTrue);
      expect(lines.any((l) => l.contains('+ Bacon (R\$ 4,00)')), isTrue);
      expect(lines.any((l) => l.contains('** sem cebola')), isTrue);
    });

    test('item sem observação não imprime linha vazia de observação', () {
      final lines = _print(
        items: const [
          OrderItem(
            id: '1',
            name: 'Coca-Cola',
            unitPrice: 6.00,
            quantity: 1,
            subtotal: 6.00,
            note: '   ',
            additions: [],
          ),
        ],
      );

      expect(lines.any((l) => l.contains('**')), isFalse);
    });
  });

  group('totais', () {
    test('subtotal, taxa e total', () {
      final lines = _print();

      expect(lines.any((l) => l.startsWith('Subtotal')), isTrue);
      expect(lines.any((l) => l.startsWith('Taxa de entrega')), isTrue);
      expect(lines.any((l) => l.startsWith('TOTAL')), isTrue);
      expect(lines.any((l) => l.contains('R\$ 57,80')), isTrue);
    });

    test('retirada sem taxa não imprime a linha de taxa', () {
      final lines = _print(delivery: DeliveryType.pickup, deliveryFee: 0);
      expect(lines.any((l) => l.startsWith('Taxa de entrega')), isFalse);
    });
  });

  group('instrução de cobrança para o entregador', () {
    test('PIX já veio pago pelo webhook — manda não cobrar', () {
      final lines = _print(payment: PaymentMethod.pix);

      expect(lines, contains('PAGO ONLINE VIA PIX'));
      expect(lines, contains('NAO COBRAR'));
      expect(lines.any((l) => l.contains('COBRAR EM')), isFalse);
    });

    test('dinheiro é cobrado na entrega', () {
      final lines = _print(payment: PaymentMethod.cash);

      expect(lines, contains('COBRAR EM DINHEIRO NA ENTREGA'));
      expect(lines.any((l) => l.contains('NAO COBRAR')), isFalse);
    });

    test('cartão é maquininha na porta, não pagamento online', () {
      final lines = _print(payment: PaymentMethod.card);

      expect(lines, contains('COBRAR NA MAQUININHA NA ENTREGA'));
    });

    test('na retirada a instrução fala em retirada', () {
      final lines = _print(
        payment: PaymentMethod.cash,
        delivery: DeliveryType.pickup,
      );

      expect(lines, contains('COBRAR EM DINHEIRO NA RETIRADA'));
    });
  });

  group('observação do pedido', () {
    test('sai destacada quando existe', () {
      final lines = _print(note: 'Não tocar a campainha');

      expect(lines, contains('OBSERVACAO DO PEDIDO'));
      expect(lines, contains('Não tocar a campainha'));
    });

    test('observação só de espaços não vira bloco vazio', () {
      expect(_print(note: '   '), isNot(contains('OBSERVACAO DO PEDIDO')));
    });
  });

  group('largura do papel', () {
    for (final paper in PaperWidth.values) {
      test('${paper.label}: nenhuma linha estoura a coluna', () {
        final lines = _print(
          paper: paper,
          note: 'Entregar rápido por favor, o cliente está com pressa hoje',
        );

        for (final line in lines) {
          expect(
            line.length,
            lessThanOrEqualTo(paper.columns),
            reason: 'linha "$line" passou de ${paper.columns} colunas',
          );
        }
      });
    }
  });
}
