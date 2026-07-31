import 'package:romeu_lanches_admin/models/payment_method.dart';

/// `FaturamentoPorFormaResponse` — o faturamento do dia de uma forma de
/// pagamento.
///
/// As três formas vêm **sempre**, na ordem `PIX`, `CARTAO`, `DINHEIRO`, com
/// `0.00` onde não houve venda — nunca nulo, nunca lista vazia. A soma das três
/// bate com o `faturamento` do relatório do dia.
class RevenueByPayment {
  final PaymentMethod method;

  /// Soma do `total` dos pedidos (subtotal + taxa de entrega).
  final double revenue;

  const RevenueByPayment({required this.method, required this.revenue});

  factory RevenueByPayment.fromJson(Map<String, dynamic> json) =>
      RevenueByPayment(
        method: PaymentMethod.fromWire(json['formaPagamento'] as String),
        revenue: (json['faturamento'] as num).toDouble(),
      );
}
