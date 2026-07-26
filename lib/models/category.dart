/// `CategoriaResponse`.
///
/// O vínculo dos adicionais é **por categoria**, não por produto: um adicional
/// só pode ser escolhido num item se estiver vinculado à categoria do produto.
class Category {
  final String id;
  final String name;
  final int order;
  final bool active;

  const Category({
    required this.id,
    required this.name,
    required this.order,
    required this.active,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['nome'] as String,
    order: (json['ordem'] as int?) ?? 0,
    active: json['ativo'] as bool? ?? true,
  );

  Category copyWith({String? name, int? order}) => Category(
    id: id,
    name: name ?? this.name,
    order: order ?? this.order,
    active: active,
  );

  /// `PUT` e `POST` não aceitam `ativo` — a ativação tem rota própria.
  Map<String, dynamic> toRequest() => {'nome': name, 'ordem': order};
}
