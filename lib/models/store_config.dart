/// `ConfigLojaResponse` — singleton de configuração da loja.
class StoreConfig {
  final bool open;
  final double deliveryFee;
  final int estimatedTimeMin;
  final bool acceptsPix;
  final bool acceptsCard;
  final bool acceptsCash;

  const StoreConfig({
    required this.open,
    required this.deliveryFee,
    required this.estimatedTimeMin,
    required this.acceptsPix,
    required this.acceptsCard,
    required this.acceptsCash,
  });

  factory StoreConfig.fromJson(Map<String, dynamic> json) => StoreConfig(
    open: json['aberta'] as bool,
    deliveryFee: (json['taxaEntrega'] as num).toDouble(),
    estimatedTimeMin: (json['tempoEstimadoMin'] as int?) ?? 0,
    acceptsPix: json['aceitaPix'] as bool,
    acceptsCard: json['aceitaCartao'] as bool,
    acceptsCash: json['aceitaDinheiro'] as bool,
  );

  StoreConfig copyWith({
    double? deliveryFee,
    int? estimatedTimeMin,
    bool? acceptsPix,
    bool? acceptsCard,
    bool? acceptsCash,
  }) => StoreConfig(
    open: open,
    deliveryFee: deliveryFee ?? this.deliveryFee,
    estimatedTimeMin: estimatedTimeMin ?? this.estimatedTimeMin,
    acceptsPix: acceptsPix ?? this.acceptsPix,
    acceptsCard: acceptsCard ?? this.acceptsCard,
    acceptsCash: acceptsCash ?? this.acceptsCash,
  );

  /// `AtualizarConfigRequest`.
  ///
  /// É `PATCH` na rota mas semântica de substituição: os cinco campos são
  /// obrigatórios, payload incompleto dá 400. Por isso mandamos sempre o
  /// objeto inteiro, com só um campo trocado.
  ///
  /// `aberta` fica de fora de propósito — é ignorado aqui e tem rota própria.
  Map<String, dynamic> toUpdateRequest() => {
    'taxaEntrega': deliveryFee,
    'tempoEstimadoMin': estimatedTimeMin,
    'aceitaPix': acceptsPix,
    'aceitaCartao': acceptsCard,
    'aceitaDinheiro': acceptsCash,
  };
}
