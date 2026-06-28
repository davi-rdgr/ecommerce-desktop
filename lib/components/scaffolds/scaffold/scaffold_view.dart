import 'package:ecommerce/components/scaffolds/scaffold/scaffold_controller.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signals_flutter/signals_flutter.dart';

class ScaffoldView extends StatefulWidget {
  final ScaffoldController controller;
  final List<Widget> pages;

  const ScaffoldView({
    super.key,
    required this.controller,
    required this.pages,
  });

  @override
  State<ScaffoldView> createState() => _ScaffoldViewState();
}

class _ScaffoldViewState extends State<ScaffoldView> {
  double _sidebarWidth = 248;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: Row(
        children: [
          SizedBox(
            width: _sidebarWidth,
            child: _Sidebar(controller: widget.controller),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _sidebarWidth = (_sidebarWidth + details.delta.dx).clamp(
                    180,
                    400,
                  );
                });
              },
              child: Container(width: 1, color: Colors.transparent),
            ),
          ),
          Expanded(
            child: SignalBuilder(
              builder: (context) => IndexedStack(
                index: widget.controller.pageIndex.value,
                children: widget.pages,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends SignalWidget {
  final ScaffoldController controller;

  const _Sidebar({required this.controller});

  static const _bgColor = Color(0xFF2A1F17);
  static const _activeColor = Color(0xFFEF7B00);

  @override
  Widget build(BuildContext context) {
    final pageIdx = controller.pageIndex.value;
    final pendingCount = controller.pendingOrdersCount.value;
    final isOpen = controller.isStoreOpen.value;

    return Container(
      color: _bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(),
          const SizedBox(height: 10),
          _buildNavItem(
            'Pedidos',
            0,
            pageIdx,
            badge: pendingCount > 0 ? pendingCount : null,
          ),
          _buildNavItem('Cardápio', 1, pageIdx),
          _buildNavItem('Loja', 2, pageIdx),
          _buildNavItem('Relatório', 3, pageIdx),
          const Spacer(),
          _buildStoreToggle(isOpen),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: Color(0xFFF0E4D8).withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFe23725), Color(0xFFf97316)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                'R',
                style: GoogleFonts.bricolageGrotesque(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Romeu',
                  style: GoogleFonts.bricolageGrotesque(
                    color: const Color(0xFFFFB627),
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  'ADMIN',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFFC9A88B),
                    fontSize: 11,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String label, int index, int pageIdx, {int? badge}) {
    final isActive = pageIdx == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
      child: InkWell(
        onTap: () => controller.goTo(index),
        mouseCursor: SystemMouseCursors.click,
        hoverColor: Colors.white.withValues(alpha: 0.05),
        splashColor: Colors.white.withValues(alpha: 0.08),
        child: Container(
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? _activeColor : const Color(0xFF6A5F5A),
                    border: isActive
                        ? null
                        : Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFFF6E8D8),
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B3B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreToggle(bool isOpen) {
    final statusColor = isOpen
        ? const Color(0xFF36D17A)
        : const Color(0xFFE07A6B);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            width: 1,
            color: const Color(0xFFF0E4D8).withValues(alpha: 0.3),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loja',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOpen ? 'Aberta' : 'Fechada',
                      style: GoogleFonts.plusJakartaSans(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: controller.toggleStore,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isOpen
                        ? const Color(0xFF4CAF50)
                        : Colors.white.withValues(alpha: 0.2),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: isOpen
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
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
