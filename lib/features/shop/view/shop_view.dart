import 'package:romeu_lanches_admin/components/header/header.dart';
import 'package:romeu_lanches_admin/core/format/currency.dart';
import 'package:romeu_lanches_admin/core/printing/paper_width.dart';
import 'package:romeu_lanches_admin/features/shop/view/shop_controller.dart';
import 'package:romeu_lanches_admin/models/business_hours.dart';
import 'package:romeu_lanches_admin/models/store_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signals_flutter/signals_flutter.dart';

const _darkBrown = Color(0xFF2A1F17);
const _mutedText = Color(0xFF998875);
const _hairline = Color(0xFFF0EBE5);
const _accent = Color(0xFFE23725);

/// Usado quando um dia fechado é aberto e ainda não tem horas gravadas —
/// `aberto=true` sem horário é 400 na API.
const _defaultOpenAt = '18:30';
const _defaultCloseAt = '23:30';

final _timePattern = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

class ShopView extends StatefulWidget {
  final ShopController controller;

  const ShopView({super.key, required this.controller});

  @override
  State<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<ShopView> {
  ShopController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  void _report(String? message) {
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
        backgroundColor: _darkBrown,
        behavior: SnackBarBehavior.floating,
        width: 420,
      ),
    );
  }

  Future<void> _saveConfig(StoreConfig next) async =>
      _report(await _controller.saveConfig(next));

  Future<void> _saveHours(BusinessHours next) async =>
      _report(await _controller.saveHours(next));

  Future<void> _testPrint() async => _report(
    await _controller.testPrint() ??
        'Cupom de teste enviado. Confira se a régua coube numa linha só.',
  );

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
            color: const Color(0xFFF4F1ED),
            child: SignalBuilder(builder: (context) => _buildBody()),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final config = _controller.config.value;

    if (config == null && _controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (config == null) {
      return _ErrorState(
        message: _controller.loadError.value ??
            'Não foi possível carregar a configuração da loja.',
        onRetry: _controller.load,
      );
    }

    final isSaving = _controller.isSavingConfig.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1248),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _OperatingHoursCard(
                  hours: _controller.hours.value,
                  savingWeekday: _controller.savingWeekday.value,
                  onSave: _saveHours,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 264,
                child: Column(
                  children: [
                    _StoreStatusCard(controller: _controller),
                    const SizedBox(height: 16),
                    _DeliveryCard(
                      config: config,
                      isSaving: isSaving,
                      onSave: _saveConfig,
                    ),
                    const SizedBox(height: 16),
                    _PaymentCard(
                      config: config,
                      isSaving: isSaving,
                      onSave: _saveConfig,
                    ),
                    const SizedBox(height: 16),
                    _PrinterCard(
                      controller: _controller,
                      onTestPrint: _testPrint,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _Card({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _darkBrown,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: _mutedText,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Horário de funcionamento ─────────────────────────────────────────────────

class _OperatingHoursCard extends StatelessWidget {
  final List<BusinessHours> hours;
  final int? savingWeekday;
  final void Function(BusinessHours) onSave;

  const _OperatingHoursCard({
    required this.hours,
    required this.savingWeekday,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Horário de funcionamento',
      subtitle:
          'Só aparece na vitrine do cliente. Não abre nem fecha a loja — quem '
          'faz isso é o botão ao lado.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, thickness: 1, color: _hairline),
          if (hours.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Nenhum horário retornado pela API.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: _mutedText,
                ),
              ),
            )
          else
            for (int i = 0; i < hours.length; i++) ...[
              _DayRow(
                key: ValueKey(hours[i].weekday),
                day: hours[i],
                isSaving: savingWeekday == hours[i].weekday,
                isLocked: savingWeekday != null,
                onSave: onSave,
              ),
              if (i < hours.length - 1)
                const Divider(height: 1, thickness: 1, color: _hairline),
            ],
        ],
      ),
    );
  }
}

class _DayRow extends StatefulWidget {
  final BusinessHours day;
  final bool isSaving;
  final bool isLocked;
  final void Function(BusinessHours) onSave;

  const _DayRow({
    super.key,
    required this.day,
    required this.isSaving,
    required this.isLocked,
    required this.onSave,
  });

  @override
  State<_DayRow> createState() => _DayRowState();
}

class _DayRowState extends State<_DayRow> {
  late final TextEditingController _openAt;
  late final TextEditingController _closeAt;
  late final FocusNode _openFocus;
  late final FocusNode _closeFocus;

  @override
  void initState() {
    super.initState();
    _openAt = TextEditingController(text: widget.day.openAt ?? '');
    _closeAt = TextEditingController(text: widget.day.closeAt ?? '');
    _openFocus = FocusNode()..addListener(_onFocusChange);
    _closeFocus = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_DayRow old) {
    super.didUpdateWidget(old);
    if (_openFocus.hasFocus || _closeFocus.hasFocus) return;
    if (old.day.openAt != widget.day.openAt) {
      _openAt.text = widget.day.openAt ?? '';
    }
    if (old.day.closeAt != widget.day.closeAt) {
      _closeAt.text = widget.day.closeAt ?? '';
    }
  }

  @override
  void dispose() {
    _openFocus.removeListener(_onFocusChange);
    _closeFocus.removeListener(_onFocusChange);
    _openFocus.dispose();
    _closeFocus.dispose();
    _openAt.dispose();
    _closeAt.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_openFocus.hasFocus && !_closeFocus.hasFocus) _commitTimes();
  }

  void _toggleOpen(bool open) {
    if (!open) {
      widget.onSave(widget.day.copyWith(open: false));
      return;
    }
    // Abrir um dia sem horário gravado seria 400 — entra com o padrão da casa.
    widget.onSave(
      BusinessHours(
        weekday: widget.day.weekday,
        open: true,
        openAt: widget.day.openAt ?? _defaultOpenAt,
        closeAt: widget.day.closeAt ?? _defaultCloseAt,
      ),
    );
  }

  void _commitTimes() {
    if (!widget.day.open) return;

    final open = _openAt.text.trim();
    final close = _closeAt.text.trim();

    // Formato inválido volta ao valor do servidor em vez de ir para a API.
    if (!_timePattern.hasMatch(open) || !_timePattern.hasMatch(close)) {
      _openAt.text = widget.day.openAt ?? '';
      _closeAt.text = widget.day.closeAt ?? '';
      return;
    }
    if (open == widget.day.openAt && close == widget.day.closeAt) return;

    // Fechamento antes da abertura é aceito de propósito: turno que vira a
    // madrugada, tipo 18:30 → 00:00. Nada de validar ordem aqui.
    widget.onSave(widget.day.copyWith(openAt: open, closeAt: close));
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final disabled = widget.isLocked;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              day.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: day.open ? _darkBrown : _mutedText,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: widget.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : CupertinoSwitch(
                    value: day.open,
                    onChanged: disabled ? null : _toggleOpen,
                    activeTrackColor: const Color(0xFF4CAF50),
                  ),
          ),
          const SizedBox(width: 12),
          if (day.open) ...[
            _TimeField(
              controller: _openAt,
              focusNode: _openFocus,
              enabled: !disabled,
              onSubmitted: _commitTimes,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '—',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: _mutedText,
                ),
              ),
            ),
            _TimeField(
              controller: _closeAt,
              focusNode: _closeFocus,
              enabled: !disabled,
              onSubmitted: _commitTimes,
            ),
            if (day.crossesMidnight)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Tooltip(
                  message: 'Fecha depois da meia-noite',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.nightlight_outlined,
                        size: 14,
                        color: _mutedText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'vira o dia',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: _mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ] else
            Text(
              'Fechado',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: _mutedText,
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSubmitted;

  const _TimeField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 34,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        textAlign: TextAlign.center,
        onSubmitted: (_) => onSubmitted(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _darkBrown,
        ),
        decoration: InputDecoration(
          hintText: '18:30',
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
    );
  }
}

// ─── Status da loja ───────────────────────────────────────────────────────────

class _StoreStatusCard extends StatelessWidget {
  final ShopController controller;

  const _StoreStatusCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final isOpen = controller.isStoreOpen.value;
        final isBusy = controller.isStoreBusy.value;

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
                              : 'Novos pedidos são recusados.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isBusy)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  else
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
      },
    );
  }
}

// ─── Entrega ──────────────────────────────────────────────────────────────────

class _DeliveryCard extends StatefulWidget {
  final StoreConfig config;
  final bool isSaving;
  final void Function(StoreConfig) onSave;

  const _DeliveryCard({
    required this.config,
    required this.isSaving,
    required this.onSave,
  });

  @override
  State<_DeliveryCard> createState() => _DeliveryCardState();
}

class _DeliveryCardState extends State<_DeliveryCard> {
  late final TextEditingController _fee;
  late final TextEditingController _time;
  late final FocusNode _feeFocus;
  late final FocusNode _timeFocus;

  @override
  void initState() {
    super.initState();
    _fee = TextEditingController(text: brlAmount(widget.config.deliveryFee));
    _time = TextEditingController(
      text: widget.config.estimatedTimeMin.toString(),
    );
    _feeFocus = FocusNode()..addListener(_onFeeFocus);
    _timeFocus = FocusNode()..addListener(_onTimeFocus);
  }

  @override
  void didUpdateWidget(_DeliveryCard old) {
    super.didUpdateWidget(old);
    if (old.config.deliveryFee != widget.config.deliveryFee &&
        !_feeFocus.hasFocus) {
      _fee.text = brlAmount(widget.config.deliveryFee);
    }
    if (old.config.estimatedTimeMin != widget.config.estimatedTimeMin &&
        !_timeFocus.hasFocus) {
      _time.text = widget.config.estimatedTimeMin.toString();
    }
  }

  @override
  void dispose() {
    _feeFocus.removeListener(_onFeeFocus);
    _timeFocus.removeListener(_onTimeFocus);
    _feeFocus.dispose();
    _timeFocus.dispose();
    _fee.dispose();
    _time.dispose();
    super.dispose();
  }

  void _onFeeFocus() {
    if (!_feeFocus.hasFocus) _commitFee();
  }

  void _onTimeFocus() {
    if (!_timeFocus.hasFocus) _commitTime();
  }

  void _commitFee() {
    final parsed = parseBrl(_fee.text);
    if (parsed == null) {
      _fee.text = brlAmount(widget.config.deliveryFee);
      return;
    }
    if (parsed == widget.config.deliveryFee) return;
    widget.onSave(widget.config.copyWith(deliveryFee: parsed));
  }

  void _commitTime() {
    final parsed = int.tryParse(_time.text.trim());
    // A API rejeita zero; devolver o valor bom evita um 400 desnecessário.
    if (parsed == null || parsed <= 0) {
      _time.text = widget.config.estimatedTimeMin.toString();
      return;
    }
    if (parsed == widget.config.estimatedTimeMin) return;
    widget.onSave(widget.config.copyWith(estimatedTimeMin: parsed));
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Entrega',
      child: Column(
        children: [
          _EditableRow(
            label: 'Taxa de entrega (R\$)',
            controller: _fee,
            focusNode: _feeFocus,
            enabled: !widget.isSaving,
            onSubmitted: _commitFee,
          ),
          const SizedBox(height: 10),
          _EditableRow(
            label: 'Tempo estimado (min)',
            controller: _time,
            focusNode: _timeFocus,
            enabled: !widget.isSaving,
            onSubmitted: _commitTime,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'A taxa nova vale para os próximos pedidos; os já feitos guardam '
              'a taxa da hora da compra.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: _mutedText,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSubmitted;

  const _EditableRow({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSubmitted,
  });

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
          width: 72,
          height: 34,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            textAlign: TextAlign.center,
            onSubmitted: (_) => onSubmitted(),
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
      ],
    );
  }
}

// ─── Formas de pagamento ──────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final StoreConfig config;
  final bool isSaving;
  final void Function(StoreConfig) onSave;

  const _PaymentCard({
    required this.config,
    required this.isSaving,
    required this.onSave,
  });

  /// Desligar a última forma deixaria o cliente sem como pagar: todo
  /// `POST /app/pedidos` passaria a voltar 400.
  bool get _isLastEnabled =>
      [config.acceptsPix, config.acceptsCard, config.acceptsCash]
          .where((enabled) => enabled)
          .length ==
      1;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Formas de pagamento',
      child: Column(
        children: [
          _PaymentRow(
            label: 'PIX',
            value: config.acceptsPix,
            enabled: !isSaving && !(config.acceptsPix && _isLastEnabled),
            onChanged: (v) => onSave(config.copyWith(acceptsPix: v)),
          ),
          const Divider(height: 1, thickness: 1, color: _hairline),
          _PaymentRow(
            label: 'Cartão',
            value: config.acceptsCard,
            enabled: !isSaving && !(config.acceptsCard && _isLastEnabled),
            onChanged: (v) => onSave(config.copyWith(acceptsCard: v)),
          ),
          const Divider(height: 1, thickness: 1, color: _hairline),
          _PaymentRow(
            label: 'Dinheiro na entrega',
            value: config.acceptsCash,
            enabled: !isSaving && !(config.acceptsCash && _isLastEnabled),
            onChanged: (v) => onSave(config.copyWith(acceptsCash: v)),
          ),
          if (_isLastEnabled)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'É a única forma ativa — desligar deixaria o cliente sem como '
                'fechar o pedido.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: _accent,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Impressora de comandas ───────────────────────────────────────────────────

/// Config da **máquina**, não da loja: fica no Hive local e não vai para a API.
/// Por isso este card não passa por `isSavingConfig` nem pelo `_saveConfig`.
class _PrinterCard extends StatelessWidget {
  final ShopController controller;
  final Future<void> Function() onTestPrint;

  const _PrinterCard({required this.controller, required this.onTestPrint});

  // SignalBuilder próprio, como o _StoreStatusCard: os signals lidos aqui
  // estão fora do escopo do builder do corpo da tela, que só rastreia o que é
  // lido dentro dele.
  @override
  Widget build(BuildContext context) =>
      SignalBuilder(builder: (context) => _buildCard());

  Widget _buildCard() {
    final printers = controller.availablePrinters.value;
    final selected = controller.selectedPrinter.value;
    final paper = controller.paperWidth.value;
    final copies = controller.ticketCopies.value;
    final isTesting = controller.isTestingPrinter.value;

    // A escolhida pode ter sumido (impressora removida, PC trocado). Mostrar o
    // dropdown vazio esconderia isso; o aviso abaixo é quem conta.
    final isMissing = selected != null && !printers.contains(selected);

    return _Card(
      title: 'Impressora de comandas',
      subtitle: 'Vale só para este computador — não é config da loja.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Impressora',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: _darkBrown,
                  ),
                ),
              ),
              _IconAction(
                icon: Icons.refresh,
                tooltip: 'Procurar impressoras de novo',
                onTap: controller.refreshPrinters,
              ),
            ],
          ),
          const SizedBox(height: 6),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDDD5CB)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: DropdownButton<String?>(
                value: isMissing ? null : selected,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                isDense: true,
                hint: Text(
                  // Sem escolha explícita o envio cai na padrão do Windows.
                  controller.effectivePrinter == null
                      ? 'Nenhuma impressora instalada'
                      : 'Padrão do Windows (${controller.effectivePrinter})',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: _mutedText,
                  ),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    child: Text(
                      'Padrão do Windows',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12),
                    ),
                  ),
                  for (final printer in printers)
                    DropdownMenuItem<String?>(
                      value: printer,
                      child: Text(
                        printer,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12),
                      ),
                    ),
                ],
                onChanged: controller.selectPrinter,
              ),
            ),
          ),
          if (isMissing) ...[
            const SizedBox(height: 6),
            Text(
              '"$selected" não está mais instalada. Escolha outra ou reconecte.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: _accent,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            'Largura da bobina',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: _darkBrown,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final width in PaperWidth.values) ...[
                Expanded(
                  child: _PaperChip(
                    label: width.label,
                    selected: paper == width,
                    onTap: () => controller.selectPaper(width),
                  ),
                ),
                if (width != PaperWidth.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Vias da comanda',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: _darkBrown,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final option in controller.copyOptions) ...[
                Expanded(
                  child: _PaperChip(
                    label: option == 1 ? '1 via' : '$option vias',
                    selected: copies == option,
                    onTap: () => controller.selectCopies(option),
                  ),
                ),
                if (option != controller.copyOptions.last)
                  const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Com 2 vias, cada comanda sai duas vezes: cozinha e balcão/entrega.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: _mutedText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: isTesting ? null : onTestPrint,
              icon: isTesting
                  ? const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.print_outlined, size: 16),
              label: Text(
                isTesting ? 'Imprimindo…' : 'Imprimir teste',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: _darkBrown,
                backgroundColor: const Color(0xFFF4F1ED),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PaperChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _accent : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? _accent : const Color(0xFFDDD5CB),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : _mutedText,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Icon(icon, size: 16, color: _mutedText),
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _PaymentRow({
    required this.label,
    required this.value,
    required this.enabled,
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
                color: _darkBrown,
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeTrackColor: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 34, color: _mutedText),
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
            onPressed: onRetry,
            child: Text(
              'Tentar novamente',
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
