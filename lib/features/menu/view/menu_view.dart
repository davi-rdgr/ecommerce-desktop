import 'package:romeu_lanches_admin/components/header/header.dart';
import 'package:romeu_lanches_admin/features/menu/view/menu_controller.dart';
import 'package:flutter/cupertino.dart' hide MenuController;
import 'package:flutter/material.dart' hide MenuController;
import 'package:google_fonts/google_fonts.dart';
import 'package:signals_flutter/signals_flutter.dart';

class MenuView extends StatelessWidget {
  final MenuController controller;

  const MenuView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Header(
          title: controller.headerTitle,
          subtitle: controller.headerSubtitle,
        ),
        Expanded(
          child: ColoredBox(
            color: const Color(0XFFF4F1ED),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CategoryTabs(controller: controller),
                Expanded(child: _MenuContent(controller: controller)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Category tabs ────────────────────────────────────────────────────────────

class _CategoryTabs extends SignalWidget {
  final MenuController controller;

  const _CategoryTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedCategory.value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
      child: Row(
        children: [
          for (int i = 0; i < MenuController.categories.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _CategoryTab(
              label: MenuController.categories[i],
              isActive: selected == i,
              onTap: () => controller.selectCategory(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
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
            color: isActive ? const Color(0xFFE23725) : Colors.white,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : const Color(0XFF5A4A3A),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Scrollable content ───────────────────────────────────────────────────────

class _MenuContent extends SignalWidget {
  final MenuController controller;

  const _MenuContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    final index = controller.selectedCategory.value;
    final category = MenuController.categories[index];
    final items = MenuController.items[category] ?? const [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1248),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ItemsCard(category: category, items: items),
              const SizedBox(height: 16),
              const _AdicionaisCard(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Items card ───────────────────────────────────────────────────────────────

class _ItemsCard extends StatelessWidget {
  final String category;
  final List<MenuItem> items;

  const _ItemsCard({required this.category, required this.items});

  static const _priceColW  = 140.0;
  static const _toggleColW = 110.0;
  static const _editColW   = 36.0;

  static final _headerStyle = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: const Color(0xFF998875),
  );

  @override
  Widget build(BuildContext context) {
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
              Expanded(child: Text('ITEM', style: _headerStyle)),
              SizedBox(
                width: _priceColW,
                child: Text('PREÇO (R\$)', style: _headerStyle),
              ),
              SizedBox(
                width: _toggleColW,
                child: Text('DISPONÍVEL', style: _headerStyle),
              ),
              SizedBox(width: _editColW),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0EBE5)),
          for (int i = 0; i < items.length; i++) ...[
            _MenuItemRow(item: items[i]),
            if (i < items.length - 1)
              const Divider(height: 1, thickness: 1, color: Color(0xFFF0EBE5)),
          ],
          const SizedBox(height: 4),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Text(
                    '+ Adicionar item em $category',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE23725),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Item row ─────────────────────────────────────────────────────────────────

class _MenuItemRow extends StatefulWidget {
  final MenuItem item;

  const _MenuItemRow({required this.item});

  @override
  State<_MenuItemRow> createState() => _MenuItemRowState();
}

class _MenuItemRowState extends State<_MenuItemRow> {
  late bool _available;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _available = widget.item.available;
    _priceController = TextEditingController(
      text: widget.item.price.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const _ImagePlaceholder(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.item.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2A1F17),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.item.description,
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
          // Price field
          SizedBox(
            width: 140,
            child: Center(
              child: SizedBox(
                width: 76,
                height: 34,
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2A1F17),
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDDD5CB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFB5A090)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Toggle
          SizedBox(
            width: 110,
            child: Center(
              child: CupertinoSwitch(
                value: _available,
                onChanged: (v) => setState(() => _available = v),
                activeTrackColor: const Color(0xFF4CAF50),
              ),
            ),
          ),
          // Edit icon
          SizedBox(
            width: 36,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {},
                child: const Icon(
                  Icons.mode_edit_outline,
                  size: 17,
                  color: Color(0xFFBCADA0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Image placeholder ────────────────────────────────────────────────────────

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CustomPaint(
        size: const Size(46, 46),
        painter: _StripesPainter(),
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
      canvas.drawLine(
        Offset(d, size.height),
        Offset(d + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripesPainter old) => false;
}

// ─── Adicionais card ──────────────────────────────────────────────────────────

class _AdicionaisCard extends StatelessWidget {
  const _AdicionaisCard();

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
              color: const Color(0xFF2A1F17),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Aplicados aos lanches no app do cliente',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 54,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: MenuController.adicionais.length,
            itemBuilder: (_, i) =>
                _AdicionalRow(adicional: MenuController.adicionais[i]),
          ),
          const SizedBox(height: 4),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Text(
                    '+ Adicionar item em Adicionais',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE23725),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdicionalRow extends StatefulWidget {
  final Adicional adicional;

  const _AdicionalRow({required this.adicional});

  @override
  State<_AdicionalRow> createState() => _AdicionalRowState();
}

class _AdicionalRowState extends State<_AdicionalRow> {
  late bool _available;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _available = true;
    _priceController = TextEditingController(
      text: widget.adicional.price.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.adicional.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2A1F17),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '+R\$',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF998875),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 52,
            height: 30,
            child: TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2A1F17),
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 6),
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
              ),
            ),
          ),
          const SizedBox(width: 10),
          CupertinoSwitch(
            value: _available,
            onChanged: (v) => setState(() => _available = v),
            activeTrackColor: const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {},
              child: const Icon(
                Icons.mode_edit_outline,
                size: 17,
                color: Color(0xFFBCADA0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
