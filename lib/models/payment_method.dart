/// Espelha `FormaPagamento` do backend.
enum PaymentMethod {
  pix('PIX', 'PIX'),
  card('CARTAO', 'Cartão'),
  cash('DINHEIRO', 'Dinheiro');

  /// Valor do contrato da API — repare que `CARTAO` vai sem acento.
  final String wire;

  /// Rótulo exibido no card.
  final String label;

  const PaymentMethod(this.wire, this.label);

  static PaymentMethod fromWire(String value) => values.firstWhere(
    (method) => method.wire == value,
    orElse: () => throw FormatException('FormaPagamento desconhecida: $value'),
  );
}
