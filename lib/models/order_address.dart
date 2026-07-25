/// Endereço congelado no pedido. Vem `null` quando a entrega é `RETIRADA`,
/// e não traz `id` — é um snapshot, não o endereço cadastrado do cliente.
class OrderAddress {
  final String street;
  final String number;
  final String district;
  final String? complement;
  final String? reference;

  const OrderAddress({
    required this.street,
    required this.number,
    required this.district,
    required this.complement,
    required this.reference,
  });

  factory OrderAddress.fromJson(Map<String, dynamic> json) => OrderAddress(
    street: json['rua'] as String,
    number: json['numero'] as String,
    district: json['bairro'] as String,
    complement: json['complemento'] as String?,
    reference: json['referencia'] as String?,
  );

  /// `Av. Brasil, 1200 — Centro`
  String get line => '$street, $number — $district';
}
