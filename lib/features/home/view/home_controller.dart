import 'package:romeu_lanches_admin/features/home/data/order_status.dart';
import 'package:romeu_lanches_admin/models/order.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

class HomeController {
  final isLoading = signal(false);
  final headerTitle = 'Pedidos';
  final headerSubtitle = 'Acompanhe e gerencie os pedidos em tempo real';

  static const List<({OrderStatus status, String label, Color color})> columns =
      [
        (
          status: OrderStatus.newOrder,
          label: 'Novos',
          color: Color(0xFFE23725),
        ),
        (
          status: OrderStatus.inProgress,
          label: 'Em preparo',
          color: Color(0xFFF59E0B),
        ),
        (
          status: OrderStatus.ready,
          label: 'A caminho / pronto',
          color: Color(0xFF3B82F6),
        ),
        (
          status: OrderStatus.finished,
          label: 'Concluídos',
          color: Color(0xFF1B9E54),
        ),
      ];

  late final activeOrders = computed(
    () => orders.value.where((o) => o.status != OrderStatus.finished).length,
  );

  late final homeStats = computed(() {
    final all = orders.value;
    final active = all.where((o) => o.status != OrderStatus.finished).length;
    final done = all.where((o) => o.status == OrderStatus.finished).length;
    final revenue = all
        .where((o) => o.status == OrderStatus.finished)
        .fold(0.0, (sum, o) => sum + o.price);
    final revenueText = 'R\$ ${revenue.toStringAsFixed(2).replaceAll('.', ',')}';
    return [
      (title: 'EM ANDAMENTO',   value: active,      color: const Color(0XFFE23725)),
      (title: 'CONCLUÍDOS HOJE', value: done,        color: const Color(0XFF1B9E54)),
      (title: 'FATURADO HOJE',  value: revenueText, color: const Color(0XFF2A1F17)),
    ];
  });

  final orders = signal<List<Order>>([
    Order(
      id: 1042,
      status: OrderStatus.newOrder,
      deliveryMethod: 'Entrega',
      paymentMethod: 'PIX',
      userName: 'Lucas Silva',
      products: ['X-Tudo', 'Refri Lata'],
      price: 44.00,
      createdAt: DateTime.now().subtract(const Duration(minutes: 132)),
    ),
    Order(
      id: 1041,
      status: OrderStatus.newOrder,
      deliveryMethod: 'Entrega',
      paymentMethod: 'Cartão',
      userName: 'Marina Costa',
      products: ['Baurú da Casa', 'Baurú da Casa'],
      price: 72.00,
      createdAt: DateTime.now().subtract(const Duration(minutes: 134)),
    ),
    Order(
      id: 1040,
      status: OrderStatus.inProgress,
      deliveryMethod: 'Retirada',
      paymentMethod: 'Dinheiro',
      userName: 'Pedro Alves',
      products: ['Baurú Família'],
      price: 89.00,
      createdAt: DateTime.now().subtract(const Duration(minutes: 140)),
    ),
    Order(
      id: 1039,
      status: OrderStatus.inProgress,
      deliveryMethod: 'Entrega',
      paymentMethod: 'PIX',
      userName: 'Júlia Mendes',
      products: ['X-Lombinho', 'Batata Frita'],
      price: 47.00,
      createdAt: DateTime.now().subtract(const Duration(minutes: 145)),
    ),
    Order(
      id: 5534,
      status: OrderStatus.ready,
      deliveryMethod: 'Entrega',
      paymentMethod: 'PIX',
      userName: 'Cliente App',
      products: ['X-Tudo'],
      price: 43.00,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2431)),
    ),
    Order(
      id: 1038,
      status: OrderStatus.ready,
      deliveryMethod: 'Entrega',
      paymentMethod: 'PIX',
      userName: 'Rafael Lima',
      products: ['Pizza Calabresa'],
      price: 67.00,
      createdAt: DateTime.now().subtract(const Duration(minutes: 153)),
    ),
    Order(
      id: 1037,
      status: OrderStatus.finished,
      deliveryMethod: 'Retirada',
      paymentMethod: 'Cartão',
      userName: 'Ana Beatriz',
      products: ['Dog Show', 'Refri 2L'],
      price: 42.00,
      createdAt: DateTime.now().subtract(const Duration(minutes: 169)),
    ),
    Order(
      id: 1036,
      status: OrderStatus.finished,
      deliveryMethod: 'Entrega',
      paymentMethod: 'PIX',
      userName: 'Carlos Eduardo',
      products: ['X-Tudo', 'X-Tudo', 'Torre de Batatas'],
      price: 117.00,
      createdAt: DateTime.now().subtract(const Duration(minutes: 183)),
    ),
    Order(
      id: 1035,
      status: OrderStatus.finished,
      deliveryMethod: 'Entrega',
      paymentMethod: 'Dinheiro',
      userName: 'Fernanda Rocha',
      products: ['Baurú Insano'],
      price: 35.00,
      createdAt: DateTime.now().subtract(const Duration(minutes: 195)),
    ),
  ]);

  void setLoading(bool value) => isLoading.value = value;

  void dispose() {
    isLoading.dispose();
    orders.dispose();
    activeOrders.dispose();
    homeStats.dispose();
  }
}
