/// `CategoriaResponse`.
///
/// O vínculo dos adicionais é **por categoria**, não por produto: um adicional
/// só pode ser escolhido num item se estiver vinculado à categoria do produto.
///
/// A imagem também é **por categoria**: todos os produtos dela exibem a mesma
/// imagem genérica (a imagem por item foi descontinuada).
class Category {
  final String id;
  final String name;
  final int order;
  final bool active;
  final String? imageUrl;

  const Category({
    required this.id,
    required this.name,
    required this.order,
    required this.active,
    this.imageUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final imageUrl = (json['imagemUrl'] as String?)?.trim();
    return Category(
      id: json['id'] as String,
      name: json['nome'] as String,
      order: (json['ordem'] as int?) ?? 0,
      active: json['ativo'] as bool? ?? true,
      imageUrl: imageUrl == null || imageUrl.isEmpty ? null : imageUrl,
    );
  }

  /// [imageUrl] é sempre substituído (inclusive por `null`), já que "sem
  /// imagem" é um valor válido vindo do formulário.
  Category copyWith({String? name, int? order, required String? imageUrl}) =>
      Category(
        id: id,
        name: name ?? this.name,
        order: order ?? this.order,
        active: active,
        imageUrl: imageUrl,
      );

  /// `PUT` e `POST` não aceitam `ativo` — a ativação tem rota própria.
  ///
  /// No `PUT`, `imagemUrl` ausente/`null` **mantém** a imagem atual e `""`
  /// remove — por isso "sem imagem" vai como string vazia.
  Map<String, dynamic> toRequest() => {
    'nome': name,
    'ordem': order,
    'imagemUrl': imageUrl ?? '',
  };
}
