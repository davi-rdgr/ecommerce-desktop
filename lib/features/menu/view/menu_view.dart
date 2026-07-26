import 'package:romeu_lanches_admin/components/header/header.dart';
import 'package:romeu_lanches_admin/core/format/currency.dart';
import 'package:romeu_lanches_admin/features/menu/components/menu_form_dialogs.dart';
import 'package:romeu_lanches_admin/features/menu/view/menu_controller.dart';
import 'package:romeu_lanches_admin/models/addition.dart';
import 'package:romeu_lanches_admin/models/category.dart';
import 'package:romeu_lanches_admin/models/product.dart';
import 'package:flutter/cupertino.dart' hide MenuController;
import 'package:flutter/material.dart' hide MenuController;
import 'package:google_fonts/google_fonts.dart';
import 'package:signals_flutter/signals_flutter.dart';

const _darkBrown = Color(0xFF2A1F17);
const _mutedText = Color(0xFF998875);
const _hairline = Color(0xFFF0EBE5);
const _accent = Color(0xFFE23725);

class MenuView extends StatefulWidget {
  final MenuController controller;

  const MenuView({super.key, required this.controller});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  MenuController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  void _report(String? message) {
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        backgroundColor: _darkBrown,
        behavior: SnackBarBehavior.floating,
        width: 420,
      ),
    );
  }

  // ─── Ações ──────────────────────────────────────────────────────────────

  Future<void> _newCategory() async {
    final name = await showCategoryNameDialog(context);
    if (name == null) return;
    _report(await _controller.createCategory(name));
  }

  Future<void> _renameCategory(Category category) async {
    final name = await showCategoryNameDialog(
      context,
      currentName: category.name,
    );
    if (name == null) return;
    _report(await _controller.saveCategory(category.copyWith(name: name)));
  }

  Future<void> _newProduct(String categoryId) async {
    final draft = await showProductFormDialog(context, categoryId: categoryId);
    if (draft == null) return;
    _report(await _controller.createProduct(draft));
  }

  Future<void> _editProduct(Product product) async {
    final edited = await showProductFormDialog(
      context,
      categoryId: product.categoryId,
      product: product,
    );
    if (edited == null) return;
    _report(await _controller.saveProduct(edited));
  }

  Future<void> _newAddition() async {
    final data = await showAdditionFormDialog(context);
    if (data == null) return;
    _report(await _controller.createAddition(data.name, data.price));
  }

  Future<void> _editAddition(Addition addition) async {
    final data = await showAdditionFormDialog(context, addition: addition);
    if (data == null) return;
    _report(
      await _controller.saveAddition(
        addition.copyWith(name: data.name, price: data.price),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Header(
          title: _controller.headerTitle,
          subtitle: _controller.headerSubtitle,
        ),
        Expanded(
          child: ColoredBox(
            color: const Color(0XFFF4F1ED),
            child: SignalBuilder(builder: (context) => _buildBody()),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final categories = _controller.categories.value;

    if (categories.isEmpty && _controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (categories.isEmpty) {
      final error = _controller.loadError.value;
      return _EmptyState(
        message: error ?? 'Nenhuma categoria cadastrada ainda.',
        actionLabel: error == null ? 'Criar primeira categoria' : 'Tentar novamente',
        onAction: error == null ? _newCategory : _controller.load,
      );
    }

    final selected = _controller.selectedCategory.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CategoryTabs(
          categories: categories,
          selectedId: _controller.selectedCategoryId.value,
          onSelect: _controller.selectCategory,
          onNew: _newCategory,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1248),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (selected != null) ...[
                      _ItemsCard(
                        category: selected,
                        products: _controller.visibleProducts.value,
                        isPending: _controller.isPending,
                        onToggleAvailable: (p) async =>
                            _report(await _controller.toggleProductAvailable(p)),
                        onSavePrice: (p, price) async => _report(
                          await _controller.saveProduct(p.copyWith(price: price)),
                        ),
                        onEdit: _editProduct,
                        onNew: () => _newProduct(selected.id),
                        onRename: () => _renameCategory(selected),
                        onToggleActive: () async =>
                            _report(await _controller.toggleCategoryActive(selected)),
                      ),
                      const SizedBox(height: 16),
                      _AdditionsCard(
                        categoryName: selected.name,
                        additions: _controller.additions.value,
                        linkedIds: _controller.linkedAdditionIds.value,
                        isPending: _controller.isPending,
                        onToggleLink: (a) async =>
                            _report(await _controller.toggleAdditionLink(a)),
                        onToggleActive: (a) async =>
                            _report(await _controller.toggleAdditionActive(a)),
                        onSavePrice: (a, price) async => _report(
                          await _controller.saveAddition(a.copyWith(price: price)),
                        ),
                        onEdit: _editAddition,
                        onNew: _newAddition,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Abas de categoria ────────────────────────────────────────────────────────

class _CategoryTabs extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final void Function(String id) onSelect;
  final VoidCallback onNew;

  const _CategoryTabs({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final category in categories) ...[
              _CategoryTab(
                category: category,
                isActive: category.id == selectedId,
                onTap: () => onSelect(category.id),
              ),
              const SizedBox(width: 8),
            ],
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onNew,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: const Color(0xFFDDD5CB)),
                  ),
                  child: Text(
                    '+ Categoria',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _mutedText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final Category category;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.category,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? _accent : Colors.white,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                category.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isActive ? Colors.white : const Color(0XFF5A4A3A),
                ),
              ),
              // Categoria inativa não aparece no cardápio do cliente.
              if (!category.active) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.visibility_off_outlined,
                  size: 14,
                  color: isActive ? Colors.white70 : _mutedText,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Card de itens ────────────────────────────────────────────────────────────

class _ItemsCard extends StatelessWidget {
  final Category category;
  final List<Product> products;
  final bool Function(String key) isPending;
  final void Function(Product) onToggleAvailable;
  final void Function(Product, double) onSavePrice;
  final void Function(Product) onEdit;
  final VoidCallback onNew;
  final VoidCallback onRename;
  final VoidCallback onToggleActive;

  const _ItemsCard({
    required this.category,
    required this.products,
    required this.isPending,
    required this.onToggleAvailable,
    required this.onSavePrice,
    required this.onEdit,
    required this.onNew,
    required this.onRename,
    required this.onToggleActive,
  });

  static final _headerStyle = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: _mutedText,
  );

  @override
  Widget build(BuildContext context) {
    final busy = isPending('category-${category.id}');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _darkBrown,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: busy ? null : onRename,
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text('Renomear'),
                style: TextButton.styleFrom(foregroundColor: _mutedText),
              ),
              TextButton.icon(
                onPressed: busy ? null : onToggleActive,
                icon: Icon(
                  category.active
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 15,
                ),
                label: Text(category.active ? 'Ocultar' : 'Exibir'),
                style: TextButton.styleFrom(
                  foregroundColor: category.active ? _mutedText : _accent,
                ),
              ),
            ],
          ),
          if (!category.active)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Categoria oculta — não aparece no cardápio do cliente.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: _accent,
                ),
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: Text('ITEM', style: _headerStyle)),
              SizedBox(width: 140, child: Text('PREÇO (R\$)', style: _headerStyle)),
              SizedBox(width: 110, child: Text('DISPONÍVEL', style: _headerStyle)),
              const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: _hairline),
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Nenhum item nesta categoria.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: _mutedText,
                  ),
                ),
              ),
            )
          else
            for (int i = 0; i < products.length; i++) ...[
              _ProductRow(
                key: ValueKey(products[i].id),
                product: products[i],
                isBusy: isPending('product-${products[i].id}'),
                onToggleAvailable: () => onToggleAvailable(products[i]),
                onSavePrice: (price) => onSavePrice(products[i], price),
                onEdit: () => onEdit(products[i]),
              ),
              if (i < products.length - 1)
                const Divider(height: 1, thickness: 1, color: _hairline),
            ],
          const SizedBox(height: 4),
          _AddRow(label: '+ Adicionar item em ${category.name}', onTap: onNew),
        ],
      ),
    );
  }
}

class _ProductRow extends StatefulWidget {
  final Product product;
  final bool isBusy;
  final VoidCallback onToggleAvailable;
  final void Function(double price) onSavePrice;
  final VoidCallback onEdit;

  const _ProductRow({
    super.key,
    required this.product,
    required this.isBusy,
    required this.onToggleAvailable,
    required this.onSavePrice,
    required this.onEdit,
  });

  @override
  State<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<_ProductRow> {
  late final TextEditingController _price;
  late final FocusNode _priceFocus;

  @override
  void initState() {
    super.initState();
    _price = TextEditingController(text: brlAmount(widget.product.price));
    _priceFocus = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_ProductRow old) {
    super.didUpdateWidget(old);
    // Preço mudou no servidor (ou o salvamento voltou arredondado) e o campo
    // não está sendo editado: reflete o valor novo.
    if (old.product.price != widget.product.price && !_priceFocus.hasFocus) {
      _price.text = brlAmount(widget.product.price);
    }
  }

  @override
  void dispose() {
    _priceFocus.removeListener(_onFocusChange);
    _priceFocus.dispose();
    _price.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_priceFocus.hasFocus) _commitPrice();
  }

  /// Salva ao sair do campo ou no Enter. Valor inválido volta ao original em
  /// vez de mandar lixo para a API.
  void _commitPrice() {
    final parsed = parseBrl(_price.text);
    if (parsed == null) {
      _price.text = brlAmount(widget.product.price);
      return;
    }
    if (parsed == widget.product.price) return;
    widget.onSavePrice(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _ProductThumb(imageUrl: product.imageUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _darkBrown,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.description?.isNotEmpty == true
                      ? product.description!
                      : 'Sem descrição',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFFA89684),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 140,
            child: Center(
              child: SizedBox(
                width: 86,
                height: 34,
                child: TextField(
                  controller: _price,
                  focusNode: _priceFocus,
                  enabled: !widget.isBusy,
                  textAlign: TextAlign.center,
                  onSubmitted: (_) => _commitPrice(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _darkBrown,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDDD5CB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFB5A090)),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFEDE6DE)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Center(
              child: widget.isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : CupertinoSwitch(
                      value: product.available,
                      onChanged: (_) => widget.onToggleAvailable(),
                      activeTrackColor: const Color(0xFF4CAF50),
                    ),
            ),
          ),
          SizedBox(
            width: 36,
            child: _IconAction(icon: Icons.mode_edit_outline, onTap: widget.onEdit),
          ),
        ],
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  final String? imageUrl;

  const _ProductThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 46,
        height: 46,
        child: url == null || url.isEmpty
            ? CustomPaint(painter: _StripesPainter())
            : Image.network(
                url,
                fit: BoxFit.cover,
                // Link quebrado é comum quando a URL é digitada à mão.
                errorBuilder: (_, _, _) => CustomPaint(painter: _StripesPainter()),
              ),
      ),
    );
  }
}

class _StripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFF2E5D2),
    );
    final paint = Paint()
      ..color = const Color(0xFFD8C4A8)
      ..strokeWidth = 1.5;

    const gap = 7.0;
    for (double d = -size.height; d < size.width + size.height; d += gap) {
      canvas.drawLine(Offset(d, size.height), Offset(d + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_StripesPainter old) => false;
}

// ─── Card de adicionais ───────────────────────────────────────────────────────

class _AdditionsCard extends StatelessWidget {
  final String categoryName;
  final List<Addition> additions;
  final Set<String> linkedIds;
  final bool Function(String key) isPending;
  final void Function(Addition) onToggleLink;
  final void Function(Addition) onToggleActive;
  final void Function(Addition, double) onSavePrice;
  final void Function(Addition) onEdit;
  final VoidCallback onNew;

  const _AdditionsCard({
    required this.categoryName,
    required this.additions,
    required this.linkedIds,
    required this.isPending,
    required this.onToggleLink,
    required this.onToggleActive,
    required this.onSavePrice,
    required this.onEdit,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adicionais',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _darkBrown,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'A lista é do catálogo inteiro. Marque os que o cliente pode '
            'escolher em $categoryName — o vínculo é por categoria, não por item.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: _mutedText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          if (additions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Nenhum adicional cadastrado.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: _mutedText,
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 58,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: additions.length,
              itemBuilder: (_, i) => _AdditionRow(
                key: ValueKey(additions[i].id),
                addition: additions[i],
                isLinked: linkedIds.contains(additions[i].id),
                isBusy: isPending('addition-${additions[i].id}'),
                isLinkBusy: isPending('link-${additions[i].id}'),
                categoryName: categoryName,
                onToggleLink: () => onToggleLink(additions[i]),
                onToggleActive: () => onToggleActive(additions[i]),
                onSavePrice: (price) => onSavePrice(additions[i], price),
                onEdit: () => onEdit(additions[i]),
              ),
            ),
          const SizedBox(height: 4),
          _AddRow(label: '+ Adicionar adicional', onTap: onNew),
        ],
      ),
    );
  }
}

class _AdditionRow extends StatefulWidget {
  final Addition addition;
  final bool isLinked;
  final bool isBusy;
  final bool isLinkBusy;
  final String categoryName;
  final VoidCallback onToggleLink;
  final VoidCallback onToggleActive;
  final void Function(double price) onSavePrice;
  final VoidCallback onEdit;

  const _AdditionRow({
    super.key,
    required this.addition,
    required this.isLinked,
    required this.isBusy,
    required this.isLinkBusy,
    required this.categoryName,
    required this.onToggleLink,
    required this.onToggleActive,
    required this.onSavePrice,
    required this.onEdit,
  });

  @override
  State<_AdditionRow> createState() => _AdditionRowState();
}

class _AdditionRowState extends State<_AdditionRow> {
  late final TextEditingController _price;
  late final FocusNode _priceFocus;

  @override
  void initState() {
    super.initState();
    _price = TextEditingController(text: brlAmount(widget.addition.price));
    _priceFocus = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_AdditionRow old) {
    super.didUpdateWidget(old);
    if (old.addition.price != widget.addition.price && !_priceFocus.hasFocus) {
      _price.text = brlAmount(widget.addition.price);
    }
  }

  @override
  void dispose() {
    _priceFocus.removeListener(_onFocusChange);
    _priceFocus.dispose();
    _price.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_priceFocus.hasFocus) _commitPrice();
  }

  void _commitPrice() {
    final parsed = parseBrl(_price.text);
    if (parsed == null) {
      _price.text = brlAmount(widget.addition.price);
      return;
    }
    if (parsed == widget.addition.price) return;
    widget.onSavePrice(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final addition = widget.addition;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.isLinked ? const Color(0xFF4CAF50) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Tooltip(
            message: widget.isLinked
                ? 'Disponível em ${widget.categoryName}'
                : 'Não aparece em ${widget.categoryName}',
            child: SizedBox(
              width: 34,
              child: widget.isLinkBusy
                  ? const Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Checkbox(
                      value: widget.isLinked,
                      onChanged: (_) => widget.onToggleLink(),
                      activeColor: const Color(0xFF4CAF50),
                      visualDensity: VisualDensity.compact,
                    ),
            ),
          ),
          Expanded(
            child: Text(
              addition.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: addition.active ? _darkBrown : _mutedText,
                decoration: addition.active ? null : TextDecoration.lineThrough,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '+R\$',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: _mutedText,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 58,
            height: 30,
            child: TextField(
              controller: _price,
              focusNode: _priceFocus,
              enabled: !widget.isBusy,
              textAlign: TextAlign.center,
              onSubmitted: (_) => _commitPrice(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _darkBrown,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(color: Color(0xFFDDD5CB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(color: Color(0xFFB5A090)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(color: Color(0xFFEDE6DE)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: addition.active
                ? 'Ativo no catálogo'
                : 'Inativo — não aparece em nenhuma categoria',
            child: widget.isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : CupertinoSwitch(
                    value: addition.active,
                    onChanged: (_) => widget.onToggleActive(),
                    activeTrackColor: const Color(0xFF4CAF50),
                  ),
          ),
          const SizedBox(width: 4),
          _IconAction(icon: Icons.mode_edit_outline, onTap: widget.onEdit),
        ],
      ),
    );
  }
}

// ─── Peças pequenas ───────────────────────────────────────────────────────────

class _IconAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Icon(icon, size: 17, color: const Color(0xFFBCADA0)),
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.restaurant_menu, size: 34, color: _mutedText),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: const Color(0xFF7A6A59),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
