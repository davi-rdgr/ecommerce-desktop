import 'package:romeu_lanches_admin/models/delivery_type.dart';
import 'package:romeu_lanches_admin/models/order_status.dart';
import 'package:romeu_lanches_admin/models/payment_method.dart';

/// `PedidoResumoResponse` — a versão rasa que alimenta os cards do kanban.
///
/// Não traz os itens, só a contagem. O detalhe vem de `GET /admin/pedidos/{id}`
/// quando o card é aberto (ver [OrderDetail]).
class Order {
  /// UUID do pedido — é o que vai nas rotas `/admin/pedidos/{id}`.
  final String id;

  /// Número sequencial legível (1042), o que aparece no card.
  final int number;

  final OrderStatus status;
  final DeliveryType deliveryType;
  final PaymentMethod paymentMethod;
  final String userName;
  final int itemCount;
  final double price;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.number,
    required this.status,
    required this.deliveryType,
    required this.paymentMethod,
    required this.userName,
    required this.itemCount,
    required this.price,
    required this.createdAt,
  });

  Order copyWith({OrderStatus? status}) => Order(
    id: id,
    number: number,
    status: status ?? this.status,
    deliveryType: deliveryType,
    paymentMethod: paymentMethod,
    userName: userName,
    itemCount: itemCount,
    price: price,
    createdAt: createdAt,
  );

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String,
    number: json['numero'] as int,
    status: OrderStatus.fromWire(json['status'] as String),
    deliveryType: DeliveryType.fromWire(json['tipoEntrega'] as String),
    paymentMethod: PaymentMethod.fromWire(json['formaPagamento'] as String),
    userName: json['nomeCliente'] as String,
    itemCount: json['quantidadeItens'] as int,
    price: (json['total'] as num).toDouble(),
    createdAt: DateTime.parse(json['criadoEm'] as String).toLocal(),
  );
}
