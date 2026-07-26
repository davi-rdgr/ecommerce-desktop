/// `ConfigLojaResponse` — singleton de configuração da loja.
///
/// Só [open] é editável pela API (`PATCH /admin/config/aberta`). Taxa e formas
/// de pagamento vêm do banco e hoje são somente leitura pelo painel.
class StoreConfig {
  final bool open;
  final double deliveryFee;
  final bool acceptsPix;
  final bool acceptsCard;
  final bool acceptsCash;

  const StoreConfig({
    required this.open,
    required this.deliveryFee,
    required this.acceptsPix,
    required this.acceptsCard,
    required this.acceptsCash,
  });

  factory StoreConfig.fromJson(Map<String, dynamic> json) => StoreConfig(
    open: json['aberta'] as bool,
    deliveryFee: (json['taxaEntrega'] as num).toDouble(),
    acceptsPix: json['aceitaPix'] as bool,
    acceptsCard: json['aceitaCartao'] as bool,
    acceptsCash: json['aceitaDinheiro'] as bool,
  );
}
