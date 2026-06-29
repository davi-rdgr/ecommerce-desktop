import 'package:romeu_lanches_admin/components/header/header.dart';
import 'package:romeu_lanches_admin/features/shop/view/shop_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signals_flutter/signals_flutter.dart';

class ShopView extends StatelessWidget {
  final ShopController controller;

  const ShopView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Header(
          title: controller.headerTitle,
          subtitle: controller.headerSubtitle,
        ),
        Align(
          alignment: Alignment.topLeft,
          child: Expanded(
            child: ColoredBox(
              color: const Color(0xFFF4F1ED),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
                child: SizedBox(
                  width: 1248,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _OperatingHoursCard(controller: controller),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 264,
                        child: Column(
                          children: [
                            _StoreStatusCard(controller: controller),
                            const SizedBox(height: 16),
                            _DeliveryCard(controller: controller),
                            const SizedBox(height: 16),
                            _PaymentCard(controller: controller),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Operating hours ──────────────────────────────────────────────────────────

class _OperatingHoursCard extends StatelessWidget {
  final ShopController controller;

  const _OperatingHoursCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Horário de funcionamento',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2A1F17),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0EBE5)),
          for (int i = 0; i < controller.schedule.length; i++) ...[
            _DayRow(day: controller.schedule[i]),
            if (i < controller.schedule.length - 1)
              const Divider(height: 1, thickness: 1, color: Color(0xFFF0EBE5)),
          ],
        ],
      ),
    );
  }
}

class _DayRow extends StatefulWidget {
  final DaySchedule day;

  const _DayRow({required this.day});

  @override
  State<_DayRow> createState() => _DayRowState();
}

class _DayRowState extends State<_DayRow> {
  late bool _enabled;
  late final TextEditingController _openCtrl;
  late final TextEditingController _closeCtrl;

  @override
  void initState() {
    super.initState();
    _enabled = widget.day.enabled.value;
    _openCtrl = TextEditingController(text: widget.day.openTime);
    _closeCtrl = TextEditingController(text: widget.day.closeTime);
  }

  @override
  void dispose() {
    _openCtrl.dispose();
    _closeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              widget.day.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _enabled
                    ? const Color(0xFF2A1F17)
                    : const Color(0xFFE23725),
              ),
            ),
          ),
          CupertinoSwitch(
            value: _enabled,
            onChanged: (v) {
              setState(() => _enabled = v);
              widget.day.enabled.value = v;
            },
            activeTrackColor: const Color(0xFF4CAF50),
          ),
          const SizedBox(width: 20),
          if (_enabled) ...[
            _TimeField(controller: _openCtrl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '—',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF998875),
                ),
              ),
            ),
            _TimeField(controller: _closeCtrl),
          ] else
            Text(
              'Fechado',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF998875),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final TextEditingController controller;

  const _TimeField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 34,
      child: TextField(
        controller: controller,
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
    );
  }
}

// ─── Store status ─────────────────────────────────────────────────────────────

class _StoreStatusCard extends SignalWidget {
  final ShopController controller;

  const _StoreStatusCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isOpen = controller.isStoreOpen.value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFF4CAF50) : const Color(0xFF9E6B5E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status da loja',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOpen ? 'Aberta' : 'Fechada',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOpen
                          ? 'Recebendo pedidos normalmente.'
                          : 'Não está recebendo pedidos.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: controller.toggleStore,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 26,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: isOpen
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          width: 20,
                          height: 20,
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
        ],
      ),
    );
  }
}

// ─── Delivery ─────────────────────────────────────────────────────────────────

class _DeliveryCard extends StatefulWidget {
  final ShopController controller;

  const _DeliveryCard({required this.controller});

  @override
  State<_DeliveryCard> createState() => _DeliveryCardState();
}

class _DeliveryCardState extends State<_DeliveryCard> {
  late final TextEditingController _feeCtrl;
  late final TextEditingController _timeCtrl;

  @override
  void initState() {
    super.initState();
    _feeCtrl = TextEditingController(
      text: widget.controller.deliveryFee.value.toInt().toString(),
    );
    _timeCtrl = TextEditingController(
      text: widget.controller.estimatedTime.value.toString(),
    );
  }

  @override
  void dispose() {
    _feeCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Entrega',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2A1F17),
            ),
          ),
          const SizedBox(height: 14),
          _DeliveryRow(label: 'Taxa de entrega (R\$)', controller: _feeCtrl),
          const SizedBox(height: 10),
          _DeliveryRow(label: 'Tempo estimado (min)', controller: _timeCtrl),
        ],
      ),
    );
  }
}

class _DeliveryRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _DeliveryRow({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF5A4A3A),
            ),
          ),
        ),
        SizedBox(
          width: 68,
          height: 34,
          child: TextField(
            controller: controller,
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
      ],
    );
  }
}

// ─── Payment methods ──────────────────────────────────────────────────────────

class _PaymentCard extends StatefulWidget {
  final ShopController controller;

  const _PaymentCard({required this.controller});

  @override
  State<_PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<_PaymentCard> {
  late bool _pix;
  late bool _card;
  late bool _cash;

  @override
  void initState() {
    super.initState();
    _pix = widget.controller.pixEnabled.value;
    _card = widget.controller.creditCardEnabled.value;
    _cash = widget.controller.cashEnabled.value;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Formas de pagamento',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2A1F17),
            ),
          ),
          const SizedBox(height: 4),
          _PaymentRow(
            label: 'PIX',
            value: _pix,
            onChanged: (v) {
              setState(() => _pix = v);
              widget.controller.pixEnabled.value = v;
            },
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0EBE5)),
          _PaymentRow(
            label: 'Cartão de crédito',
            value: _card,
            onChanged: (v) {
              setState(() => _card = v);
              widget.controller.creditCardEnabled.value = v;
            },
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0EBE5)),
          _PaymentRow(
            label: 'Dinheiro na entrega',
            value: _cash,
            onChanged: (v) {
              setState(() => _cash = v);
              widget.controller.cashEnabled.value = v;
            },
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PaymentRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2A1F17),
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }
}
