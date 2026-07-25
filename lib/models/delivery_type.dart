/// Espelha `TipoEntrega` do backend.
enum DeliveryType {
  delivery('ENTREGA', 'Entrega'),
  pickup('RETIRADA', 'Retirada');

  /// Valor do contrato da API.
  final String wire;

  /// Rótulo exibido no card.
  final String label;

  const DeliveryType(this.wire, this.label);

  static DeliveryType fromWire(String value) => values.firstWhere(
    (type) => type.wire == value,
    orElse: () => throw FormatException('TipoEntrega desconhecido: $value'),
  );
}
