import 'package:flutter/material.dart';

class ReportController {
  final headerTitle = 'Relatório do dia';
  final headerSubtitle = 'Desempenho de hoje';

  static const stats = (
    revenue: 'R\$ 556,00',
    revenueChange: '▲ 12% vs ontem',
    orders: 9,
    ordersActive: '6 em andamento',
    avgTicket: 'R\$ 61,78',
    avgTicketChange: '▲ 4%',
    topItem: 'X-Tudo',
    topItemSub: '4 vendidos',
  );

  static const hourlySales = [
    (hour: '18h', count: 3),
    (hour: '19h', count: 7),
    (hour: '20h', count: 11),
    (hour: '21h', count: 9),
    (hour: '22h', count: 6),
    (hour: '23h', count: 2),
  ];

  static const paymentMethods = [
    (label: 'PIX',      pct: 57, color: Color(0xFF4CAF50)),
    (label: 'Cartão',   pct: 21, color: Color(0xFF3B82F6)),
    (label: 'Dinheiro', pct: 22, color: Color(0xFFF59E0B)),
  ];

  static const topItems = [
    (name: 'X-Tudo',        count: 4),
    (name: 'Baurú da Casa',  count: 2),
    (name: 'Refri Lata',    count: 1),
    (name: 'Baurú Família',  count: 1),
    (name: 'X-Lombinho',    count: 1),
  ];

  void dispose() {}
}
