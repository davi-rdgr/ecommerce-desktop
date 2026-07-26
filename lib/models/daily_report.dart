class TopSeller {
  final String name;
  final int quantity;

  const TopSeller({required this.name, required this.quantity});

  factory TopSeller.fromJson(Map<String, dynamic> json) => TopSeller(
    name: json['nome'] as String,
    quantity: json['quantidade'] as int,
  );
}

/// `RelatorioDiaResponse`.
///
/// Conta **apenas pedidos concluídos** do dia civil em America/São_Paulo, e
/// traz no máximo 10 mais vendidos. Dia sem venda volta zerado, nunca nulo.
class DailyReport {
  final DateTime date;
  final double revenue;
  final int orderCount;
  final double averageTicket;
  final List<TopSeller> topSellers;

  const DailyReport({
    required this.date,
    required this.revenue,
    required this.orderCount,
    required this.averageTicket,
    required this.topSellers,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) => DailyReport(
    date: DateTime.parse(json['data'] as String),
    revenue: (json['faturamento'] as num).toDouble(),
    orderCount: json['quantidadePedidos'] as int,
    averageTicket: (json['ticketMedio'] as num).toDouble(),
    topSellers: ((json['maisVendidos'] as List?) ?? const [])
        .map((e) => TopSeller.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
