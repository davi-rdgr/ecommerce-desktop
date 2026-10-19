import 'package:romeu_lanches_admin/core/network/api_client.dart';
import 'package:romeu_lanches_admin/models/addition.dart';
import 'package:romeu_lanches_admin/models/category.dart';
import 'package:romeu_lanches_admin/models/product.dart';

class MenuService {
  final ApiClient _api;

  const MenuService(this._api);

  // ─── Categorias ─────────────────────────────────────────────────────────

  Future<List<Category>> listCategories() async {
    final json = await _api.get('/admin/categorias');
    return (json as List)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Category> createCategory(
    String name,
    int order, {
    String? imageUrl,
  }) async {
    final json = await _api.post(
      '/admin/categorias',
      body: {
        'nome': name,
        'ordem': order,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imagemUrl': imageUrl,
      },
    );
    return Category.fromJson(json as Map<String, dynamic>);
  }

  Future<Category> updateCategory(Category category) async {
    final json = await _api.put(
      '/admin/categorias/${category.id}',
      body: category.toRequest(),
    );
    return Category.fromJson(json as Map<String, dynamic>);
  }

  Future<Category> setCategoryActive(String id, bool active) async {
    final json = await _api.patch(
      '/admin/categorias/$id/ativo',
      body: {'ativo': active},
    );
    return Category.fromJson(json as Map<String, dynamic>);
  }

  Future<List<Addition>> listCategoryAdditions(String categoryId) async {
    final json = await _api.get('/admin/categorias/$categoryId/adicionais');
    return (json as List)
        .map((e) => Addition.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// **Substitui** o conjunto inteiro de adicionais da categoria — não é
  /// append. Lista vazia desvincula todos.
  Future<List<Addition>> linkAdditions(
    String categoryId,
    Iterable<String> additionIds,
  ) async {
    final json = await _api.put(
      '/admin/categorias/$categoryId/adicionais',
      body: {'adicionalIds': additionIds.toList()},
    );
    final map = json as Map<String, dynamic>;
    return ((map['adicionais'] as List?) ?? const [])
        .map((e) => Addition.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Produtos ───────────────────────────────────────────────────────────

  Future<List<Product>> listProducts() async {
    final json = await _api.get('/admin/produtos');
    return (json as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Product> createProduct(Product draft) async {
    final json = await _api.post('/admin/produtos', body: draft.toRequest());
    return Product.fromJson(json as Map<String, dynamic>);
  }

  Future<Product> updateProduct(Product product) async {
    final json = await _api.put(
      '/admin/produtos/${product.id}',
      body: product.toRequest(),
    );
    return Product.fromJson(json as Map<String, dynamic>);
  }

  Future<Product> setProductAvailable(String id, bool available) async {
    final json = await _api.patch(
      '/admin/produtos/$id/disponibilidade',
      body: {'disponivel': available},
    );
    return Product.fromJson(json as Map<String, dynamic>);
  }

  // ─── Adicionais ─────────────────────────────────────────────────────────

  Future<List<Addition>> listAdditions() async {
    final json = await _api.get('/admin/adicionais');
    return (json as List)
        .map((e) => Addition.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Addition> createAddition(String name, double price) async {
    final json = await _api.post(
      '/admin/adicionais',
      body: {'nome': name, 'preco': price},
    );
    return Addition.fromJson(json as Map<String, dynamic>);
  }

  Future<Addition> updateAddition(Addition addition) async {
    final json = await _api.put(
      '/admin/adicionais/${addition.id}',
      body: addition.toRequest(),
    );
    return Addition.fromJson(json as Map<String, dynamic>);
  }

  Future<Addition> setAdditionActive(String id, bool active) async {
    final json = await _api.patch(
      '/admin/adicionais/$id/ativo',
      body: {'ativo': active},
    );
    return Addition.fromJson(json as Map<String, dynamic>);
  }
}
