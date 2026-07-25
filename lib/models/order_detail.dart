import 'package:romeu_lanches_admin/models/delivery_type.dart';
import 'package:romeu_lanches_admin/models/order_address.dart';
import 'package:romeu_lanches_admin/models/order_item.dart';
import 'package:romeu_lanches_admin/models/order_status.dart';
import 'package:romeu_lanches_admin/models/payment_method.dart';

/// `PedidoResponse` — o pedido completo, de `GET /admin/pedidos/{id}`.
///
/// Repare que **não traz o nome do cliente**: esse campo só existe no
/// `PedidoResumoResponse` da lista. Como a modal abre a partir de um card,
/// o nome vem de lá.
class OrderDetail {
  final String id;
  final int number;
  final OrderStatus status;
  final DeliveryType deliveryType;
  final PaymentMethod paymentMethod;

  /// `null` quando a entrega é `RETIRADA`.
  final OrderAddress? address;

  final double subtotal;
  final double deliveryFee;
  final double total;

  /// Observação do pedido inteiro — cada item tem a sua separada.
  final String? note;

  final DateTime createdAt;
  final List<OrderItem> items;

  const OrderDetail({
    required this.id,
    required this.number,
    required this.status,
    required this.deliveryType,
    required this.paymentMethod,
    required this.address,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.note,
    required this.createdAt,
    required this.items,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    final address = json['endereco'] as Map<String, dynamic>?;

    return OrderDetail(
      id: json['id'] as String,
      number: json['numero'] as int,
      status: OrderStatus.fromWire(json['status'] as String),
      deliveryType: DeliveryType.fromWire(json['tipoEntrega'] as String),
      paymentMethod: PaymentMethod.fromWire(json['formaPagamento'] as String),
      address: address == null ? null : OrderAddress.fromJson(address),
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['taxaEntrega'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      note: json['observacao'] as String?,
      createdAt: DateTime.parse(json['criadoEm'] as String).toLocal(),
      items: ((json['itens'] as List?) ?? const [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
