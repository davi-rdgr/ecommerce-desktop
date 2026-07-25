/// Adicional escolhido num item do pedido. Preço congelado no momento da compra.
class OrderItemAddition {
  final String id;
  final String name;
  final double price;

  const OrderItemAddition({
    required this.id,
    required this.name,
    required this.price,
  });

  factory OrderItemAddition.fromJson(Map<String, dynamic> json) =>
      OrderItemAddition(
        id: json['id'] as String,
        name: json['nome'] as String,
        price: (json['preco'] as num).toDouble(),
      );
}

class OrderItem {
  final String id;
  final String name;

  /// Preço do produto sozinho — **não** inclui os adicionais.
  final double unitPrice;

  final int quantity;

  /// Total da linha: `(unitPrice + soma dos adicionais) × quantity`.
  final double subtotal;

  final String? note;
  final List<OrderItemAddition> additions;

  const OrderItem({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    required this.note,
    required this.additions,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: json['id'] as String,
    name: json['nome'] as String,
    unitPrice: (json['precoUnitario'] as num).toDouble(),
    quantity: json['quantidade'] as int,
    subtotal: (json['subtotal'] as num).toDouble(),
    note: json['observacao'] as String?,
    additions: ((json['adicionais'] as List?) ?? const [])
        .map((e) => OrderItemAddition.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
