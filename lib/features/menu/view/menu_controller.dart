import 'package:romeu_lanches_admin/core/network/api_exception.dart';
import 'package:romeu_lanches_admin/features/menu/data/menu_service.dart';
import 'package:romeu_lanches_admin/models/addition.dart';
import 'package:romeu_lanches_admin/models/category.dart';
import 'package:romeu_lanches_admin/models/product.dart';
import 'package:signals_flutter/signals_flutter.dart';

class MenuController {
  final MenuService _service;

  MenuController(this._service);

  final headerTitle = 'Cardápio';
  final headerSubtitle = 'Edite itens, preços e disponibilidade';

  final categories = signal<List<Category>>([]);
  final products = signal<List<Product>>([]);
  final additions = signal<List<Addition>>([]);

  /// Adicionais vinculados à categoria selecionada. O vínculo é por categoria,
  /// não por produto.
  final linkedAdditionIds = signal<Set<String>>({});

  final selectedCategoryId = signal<String?>(null);
  final isLoading = signal(false);
  final loadError = signal<String?>(null);

  /// Chaves com operação em voo, para travar o controle correspondente.
  final pendingKeys = signal<Set<String>>({});

  late final selectedCategory = computed(() {
    final id = selectedCategoryId.value;
    for (final category in categories.value) {
      if (category.id == id) return category;
    }
    return null;
  });

  late final visibleProducts = computed(() {
    final id = selectedCategoryId.value;
    if (id == null) return const <Product>[];
    return products.value.where((p) => p.categoryId == id).toList()
      ..sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
      });
  });

  Future<void> load() async {
    isLoading.value = true;
    loadError.value = null;

    try {
      // Disparadas antes dos awaits para irem em paralelo.
      final categoriesRequest = _service.listCategories();
      final productsRequest = _service.listProducts();
      final additionsRequest = _service.listAdditions();

      categories.value = (await categoriesRequest)
        ..sort((a, b) {
          final byOrder = a.order.compareTo(b.order);
          return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
        });
      products.value = await productsRequest;
      additions.value = (await additionsRequest)
        ..sort((a, b) => a.name.compareTo(b.name));

      final current = selectedCategoryId.value;
      final stillExists = categories.value.any((c) => c.id == current);
      final target = stillExists
          ? current
          : (categories.value.isEmpty ? null : categories.value.first.id);

      selectedCategoryId.value = target;
      if (target != null) await _loadLinks(target);
    } on ApiException catch (e) {
      loadError.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectCategory(String id) async {
    if (selectedCategoryId.value == id) return;
    selectedCategoryId.value = id;
    linkedAdditionIds.value = {};
    await _loadLinks(id);
  }

  Future<void> _loadLinks(String categoryId) async {
    try {
      final linked = await _service.listCategoryAdditions(categoryId);
      // Só aplica se a categoria ainda for a selecionada — troca rápida de aba
      // pode fazer uma resposta antiga chegar depois da nova.
      if (selectedCategoryId.value != categoryId) return;
      linkedAdditionIds.value = linked.map((a) => a.id).toSet();
    } on ApiException catch (e) {
      loadError.value = e.message;
    }
  }

  bool isPending(String key) => pendingKeys.value.contains(key);

  // ─── Produtos ───────────────────────────────────────────────────────────

  Future<String?> toggleProductAvailable(Product product) =>
      _run('product-${product.id}', () async {
        _upsertProduct(
          await _service.setProductAvailable(product.id, !product.available),
        );
      });

  Future<String?> saveProduct(Product product) =>
      _run('product-${product.id}', () async {
        _upsertProduct(await _service.updateProduct(product));
      });

  Future<String?> createProduct(Product draft) =>
      _run('product-new', () async {
        _upsertProduct(await _service.createProduct(draft));
      });

  void _upsertProduct(Product product) {
    final current = products.value;
    final index = current.indexWhere((p) => p.id == product.id);
    products.value = index >= 0
        ? ([...current]..[index] = product)
        : [...current, product];
  }

  // ─── Adicionais ─────────────────────────────────────────────────────────

  Future<String?> toggleAdditionActive(Addition addition) =>
      _run('addition-${addition.id}', () async {
        _upsertAddition(
          await _service.setAdditionActive(addition.id, !addition.active),
        );
      });

  Future<String?> saveAddition(Addition addition) =>
      _run('addition-${addition.id}', () async {
        _upsertAddition(await _service.updateAddition(addition));
      });

  Future<String?> createAddition(String name, double price) =>
      _run('addition-new', () async {
        _upsertAddition(await _service.createAddition(name, price));
      });

  /// Liga ou desliga o adicional da categoria selecionada.
  ///
  /// O endpoint substitui o conjunto inteiro, então mandamos a lista nova
  /// completa e reaproveitamos a resposta como verdade.
  Future<String?> toggleAdditionLink(Addition addition) {
    final categoryId = selectedCategoryId.value;
    if (categoryId == null) {
      return Future.value('Nenhuma categoria selecionada.');
    }

    final next = {...linkedAdditionIds.value};
    if (!next.remove(addition.id)) next.add(addition.id);

    return _run('link-${addition.id}', () async {
      final linked = await _service.linkAdditions(categoryId, next);
      if (selectedCategoryId.value != categoryId) return;
      linkedAdditionIds.value = linked.map((a) => a.id).toSet();
    });
  }

  void _upsertAddition(Addition addition) {
    final current = additions.value;
    final index = current.indexWhere((a) => a.id == addition.id);
    additions.value =
        (index >= 0 ? ([...current]..[index] = addition) : [...current, addition])
          ..sort((a, b) => a.name.compareTo(b.name));
  }

  // ─── Categorias ─────────────────────────────────────────────────────────

  Future<String?> createCategory(String name, {String? imageUrl}) =>
      _run('category-new', () async {
        final order = categories.value.isEmpty
            ? 1
            : categories.value.map((c) => c.order).reduce((a, b) => a > b ? a : b) + 1;
        final created = await _service.createCategory(
          name,
          order,
          imageUrl: imageUrl,
        );
        _upsertCategory(created);
        await selectCategory(created.id);
      });

  Future<String?> saveCategory(Category category) =>
      _run('category-${category.id}', () async {
        _upsertCategory(await _service.updateCategory(category));
      });

  Future<String?> toggleCategoryActive(Category category) =>
      _run('category-${category.id}', () async {
        _upsertCategory(
          await _service.setCategoryActive(category.id, !category.active),
        );
      });

  void _upsertCategory(Category category) {
    final current = categories.value;
    final index = current.indexWhere((c) => c.id == category.id);
    categories.value =
        (index >= 0
            ? ([...current]..[index] = category)
            : [...current, category])
          ..sort((a, b) {
            final byOrder = a.order.compareTo(b.order);
            return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
          });
  }

  Future<String?> _run(String key, Future<void> Function() action) async {
    if (pendingKeys.value.contains(key)) return null;
    pendingKeys.value = {...pendingKeys.value, key};

    try {
      await action();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      pendingKeys.value = {...pendingKeys.value}..remove(key);
    }
  }

  void dispose() {
    categories.dispose();
    products.dispose();
    additions.dispose();
    linkedAdditionIds.dispose();
    selectedCategoryId.dispose();
    isLoading.dispose();
    loadError.dispose();
    pendingKeys.dispose();
    selectedCategory.dispose();
    visibleProducts.dispose();
  }
}
