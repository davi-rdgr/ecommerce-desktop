/// `ProdutoResponse`.
class Product {
  final String id;
  final String categoryId;
  final String categoryName;
  final String name;
  final String? description;
  final double price;
  final bool available;
  final String? imageUrl;
  final int order;

  const Product({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.description,
    required this.price,
    required this.available,
    required this.imageUrl,
    required this.order,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    categoryId: json['categoriaId'] as String,
    categoryName: json['categoriaNome'] as String? ?? '',
    name: json['nome'] as String,
    description: json['descricao'] as String?,
    price: (json['preco'] as num).toDouble(),
    available: json['disponivel'] as bool? ?? true,
    imageUrl: json['imagemUrl'] as String?,
    order: (json['ordem'] as int?) ?? 0,
  );

  Product copyWith({
    String? categoryId,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    int? order,
  }) => Product(
    id: id,
    categoryId: categoryId ?? this.categoryId,
    categoryName: categoryName,
    name: name ?? this.name,
    description: description ?? this.description,
    price: price ?? this.price,
    available: available,
    imageUrl: imageUrl ?? this.imageUrl,
    order: order ?? this.order,
  );

  /// `ProdutoRequest`. Não carrega `disponivel`: o `PUT` ignora esse campo e a
  /// criação sempre nasce disponível — quem muda é o PATCH de disponibilidade.
  Map<String, dynamic> toRequest() => {
    'categoriaId': categoryId,
    'nome': name,
    'descricao': description,
    'preco': price,
    'imagemUrl': imageUrl,
    'ordem': order,
  };
}
