/// Espelha `StatusPedido` do backend.
///
/// Os valores de [wire] são o contrato da API — não mudar sem mudar o backend.
enum OrderStatus {
  awaitingPayment('AGUARDANDO_PAGAMENTO', 'Aguardando pagamento'),
  newOrder('NOVO', 'Novo'),
  inProgress('EM_PREPARO', 'Em preparo'),
  ready('PRONTO', 'Pronto'),
  finished('CONCLUIDO', 'Concluído'),
  canceled('CANCELADO', 'Cancelado');

  final String wire;

  /// Rótulo de um pedido só. As colunas do kanban usam o plural, definido
  /// em `HomeController.columns`.
  final String label;

  const OrderStatus(this.wire, this.label);

  static OrderStatus fromWire(String value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => throw FormatException('StatusPedido desconhecido: $value'),
  );

  /// Aparece em alguma coluna do kanban.
  ///
  /// PIX não pago nunca chega ao admin, e cancelado sai da tela.
  bool get isOnBoard => this != awaitingPayment && this != canceled;

  /// Em andamento — alimenta o badge da sidebar e o card "EM ANDAMENTO".
  bool get isActive =>
      this == newOrder || this == inProgress || this == ready;
}
