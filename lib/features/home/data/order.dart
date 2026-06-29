import 'package:romeu_lanches_admin/features/home/data/order_status.dart';

class Order {
  final int id;
  final OrderStatus status;
  final String deliveryMethod;
  final String paymentMethod;
  final String userName;
  final List<String> products;
  final double price;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.status,
    required this.deliveryMethod,
    required this.paymentMethod,
    required this.userName,
    required this.products,
    required this.price,
    required this.createdAt,
  });
}
