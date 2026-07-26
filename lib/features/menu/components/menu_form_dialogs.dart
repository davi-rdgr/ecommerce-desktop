import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_admin/core/format/currency.dart';
import 'package:romeu_lanches_admin/models/addition.dart';
import 'package:romeu_lanches_admin/models/product.dart';

const _darkBrown = Color(0xFF2A1F17);
const _mutedText = Color(0xFF998875);
const _accent = Color(0xFFE23725);

/// Formulário de produto. Devolve o produto montado, ou `null` se cancelado.
///
/// Em criação o `id` volta vazio — quem chama decide entre POST e PUT, e o
/// `ProdutoRequest` não carrega id de qualquer forma.
Future<Product?> showProductFormDialog(
  BuildContext context, {
  required String categoryId,
  Product? product,
}) {
  return showDialog<Product>(
    context: context,
    builder: (_) => _ProductFormDialog(categoryId: categoryId, product: product),
  );
}

/// Formulário de adicional. Devolve `(name, price)`, ou `null` se cancelado.
Future<({String name, double price})?> showAdditionFormDialog(
  BuildContext context, {
  Addition? addition,
}) {
  return showDialog<({String name, double price})>(
    context: context,
    builder: (_) => _AdditionFormDialog(addition: addition),
  );
}

/// Nome de categoria. Devolve o nome, ou `null` se cancelado.
Future<String?> showCategoryNameDialog(
  BuildContext context, {
  String? currentName,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _CategoryNameDialog(currentName: currentName),
  );
}

// ─── Produto ──────────────────────────────────────────────────────────────────

class _ProductFormDialog extends StatefulWidget {
  final String categoryId;
  final Product? product;

  const _ProductFormDialog({required this.categoryId, this.product});

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _imageUrl;
  late final TextEditingController _order;

  Product? get _product => widget.product;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _product?.name ?? '');
    _description = TextEditingController(text: _product?.description ?? '');
    _price = TextEditingController(
      text: _product == null ? '' : brlAmount(_product!.price),
    );
    _imageUrl = TextEditingController(text: _product?.imageUrl ?? '');
    _order = TextEditingController(text: (_product?.order ?? 0).toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _imageUrl.dispose();
    _order.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    String text(TextEditingController c) => c.text.trim();

    Navigator.of(context).pop(
      Product(
        id: _product?.id ?? '',
        categoryId: widget.categoryId,
        categoryName: _product?.categoryName ?? '',
        name: text(_name),
        description: text(_description).isEmpty ? null : text(_description),
        price: parseBrl(_price.text)!,
        available: _product?.available ?? true,
        imageUrl: text(_imageUrl).isEmpty ? null : text(_imageUrl),
        order: int.tryParse(text(_order)) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      title: _product == null ? 'Novo item' : 'Editar item',
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Field(
              label: 'Nome',
              controller: _name,
              autofocus: true,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Informe o nome.' : null,
            ),
            _Field(
              label: 'Descrição',
              controller: _description,
              maxLines: 2,
              hint: 'Aparece embaixo do nome no app do cliente',
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Field(
                    label: 'Preço (R\$)',
                    controller: _price,
                    hint: '24,90',
                    validator: (v) =>
                        parseBrl(v ?? '') == null ? 'Preço inválido.' : null,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: _Field(
                    label: 'Ordem',
                    controller: _order,
                    hint: '0',
                  ),
                ),
              ],
            ),
            _Field(
              label: 'URL da imagem',
              controller: _imageUrl,
              hint: 'https://…  (a API não faz upload, só guarda o link)',
            ),
            if (_product != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'A disponibilidade é alterada pelo botão da lista — este '
                  'formulário não mexe nela.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: _mutedText,
                    height: 1.35,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Adicional ────────────────────────────────────────────────────────────────

class _AdditionFormDialog extends StatefulWidget {
  final Addition? addition;

  const _AdditionFormDialog({this.addition});

  @override
  State<_AdditionFormDialog> createState() => _AdditionFormDialogState();
}

class _AdditionFormDialogState extends State<_AdditionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.addition?.name ?? '');
    _price = TextEditingController(
      text: widget.addition == null ? '' : brlAmount(widget.addition!.price),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop((
      name: _name.text.trim(),
      price: parseBrl(_price.text)!,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      title: widget.addition == null ? 'Novo adicional' : 'Editar adicional',
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Field(
              label: 'Nome',
              controller: _name,
              autofocus: true,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Informe o nome.' : null,
            ),
            _Field(
              label: 'Preço (R\$)',
              controller: _price,
              hint: '4,00',
              validator: (v) =>
                  parseBrl(v ?? '') == null ? 'Preço inválido.' : null,
            ),
            Text(
              'O adicional só aparece para o cliente nas categorias em que '
              'estiver marcado.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: _mutedText,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Categoria ────────────────────────────────────────────────────────────────

class _CategoryNameDialog extends StatefulWidget {
  final String? currentName;

  const _CategoryNameDialog({this.currentName});

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.currentName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_name.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return _FormShell(
      title: widget.currentName == null ? 'Nova categoria' : 'Renomear categoria',
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: _Field(
          label: 'Nome',
          controller: _name,
          autofocus: true,
          hint: 'Lanches, Bebidas…',
          validator: (v) => (v ?? '').trim().isEmpty ? 'Informe o nome.' : null,
        ),
      ),
    );
  }
}

// ─── Peças compartilhadas ─────────────────────────────────────────────────────

class _FormShell extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onSubmit;

  const _FormShell({
    required this.title,
    required this.child,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _darkBrown,
                ),
              ),
              const SizedBox(height: 18),
              child,
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: _mutedText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: Text(
                      'Salvar',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final bool autofocus;
  final String? Function(String?)? validator;

  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.autofocus = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: color, width: width),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _darkBrown,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            autofocus: autofocus,
            maxLines: maxLines,
            validator: validator,
            style: GoogleFonts.plusJakartaSans(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: _mutedText.withValues(alpha: 0.7),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: border(const Color(0xFFDDD5CB)),
              enabledBorder: border(const Color(0xFFDDD5CB)),
              focusedBorder: border(const Color(0xFFEF7B00), 1.5),
              errorBorder: border(_accent),
              focusedErrorBorder: border(_accent, 1.5),
              errorStyle: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: _accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
