/// `AdicionalResponse` — o adicional no catálogo.
///
/// Não confundir com o adicional já congelado dentro de um item de pedido,
/// que é o `OrderItemAddition`.
class Addition {
  final String id;
  final String name;
  final double price;
  final bool active;

  const Addition({
    required this.id,
    required this.name,
    required this.price,
    required this.active,
  });

  factory Addition.fromJson(Map<String, dynamic> json) => Addition(
    id: json['id'] as String,
    name: json['nome'] as String,
    price: (json['preco'] as num).toDouble(),
    active: json['ativo'] as bool? ?? true,
  );

  Addition copyWith({String? name, double? price}) => Addition(
    id: id,
    name: name ?? this.name,
    price: price ?? this.price,
    active: active,
  );

  /// `PUT` não altera `ativo` — a ativação tem rota própria.
  Map<String, dynamic> toRequest() => {'nome': name, 'preco': price};
}
