import 'package:romeu_lanches_admin/components/header/header.dart';
import 'package:romeu_lanches_admin/core/format/currency.dart';
import 'package:romeu_lanches_admin/features/shop/view/shop_controller.dart';
import 'package:romeu_lanches_admin/models/store_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signals_flutter/signals_flutter.dart';

const _darkBrown = Color(0xFF2A1F17);
const _mutedText = Color(0xFF998875);
const _hairline = Color(0xFFF0EBE5);

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
    final error = _controller.loadError.value;

    if (config == null && _controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (config == null) {
      return _ErrorState(
        message: error ?? 'Não foi possível carregar a configuração da loja.',
        onRetry: _controller.load,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1248),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: _OperatingHoursCard()),
              const SizedBox(width: 16),
              SizedBox(
                width: 264,
                child: Column(
                  children: [
                    _StoreStatusCard(controller: _controller),
                    const SizedBox(height: 16),
                    _DeliveryCard(config: config),
                    const SizedBox(height: 16),
                    _PaymentCard(config: config),
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

/// Aviso de que o controle abaixo não é editável, e por quê.
class _Note extends StatelessWidget {
  final String text;

  const _Note(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, size: 13, color: _mutedText),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
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

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Horário de funcionamento ─────────────────────────────────────────────────

/// A API não tem horário de funcionamento: não há campo no `ConfigLojaResponse`
/// nem endpoint para gravar. Fica visível como pendência, e desabilitado, para
/// não passar a impressão de que dá para configurar.
class _OperatingHoursCard extends StatelessWidget {
  const _OperatingHoursCard();

  static const _days = [
    'Domingo',
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
  ];

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Horário de funcionamento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Note(
            'A API ainda não tem horário de funcionamento — nem para ler, nem '
            'para gravar. Hoje a loja é aberta e fechada na mão, no card ao lado.',
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, thickness: 1, color: _hairline),
          for (int i = 0; i < _days.length; i++) ...[
            Opacity(
              opacity: 0.45,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        _days[i],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _darkBrown,
                        ),
                      ),
                    ),
                    const CupertinoSwitch(value: false, onChanged: null),
                    const SizedBox(width: 20),
                    Text(
                      '—',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: _mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < _days.length - 1)
              const Divider(height: 1, thickness: 1, color: _hairline),
          ],
        ],
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

class _DeliveryCard extends StatelessWidget {
  final StoreConfig config;

  const _DeliveryCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Entrega',
      child: Column(
        children: [
          _ReadOnlyRow(
            label: 'Taxa de entrega',
            value: brl(config.deliveryFee),
          ),
          const SizedBox(height: 10),
          const _ReadOnlyRow(label: 'Tempo estimado', value: '—'),
          const _Note(
            'A taxa vem do banco, mas a API não expõe endpoint para alterá-la. '
            'Tempo estimado ainda não existe no backend.',
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyRow({required this.label, required this.value});

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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF7F4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE7DFD6)),
          ),
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _darkBrown,
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

  const _PaymentCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Formas de pagamento',
      child: Column(
        children: [
          _PaymentRow(label: 'PIX', value: config.acceptsPix),
          const Divider(height: 1, thickness: 1, color: _hairline),
          _PaymentRow(label: 'Cartão', value: config.acceptsCard),
          const Divider(height: 1, thickness: 1, color: _hairline),
          _PaymentRow(label: 'Dinheiro na entrega', value: config.acceptsCash),
          const _Note(
            'Reflete o que está no banco. A API não tem endpoint para ligar ou '
            'desligar forma de pagamento.',
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final bool value;

  const _PaymentRow({required this.label, required this.value});

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
          // Desabilitado de propósito: mostra o estado real, mas não há como
          // gravar mudança.
          CupertinoSwitch(
            value: value,
            onChanged: null,
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
                color: const Color(0xFFE23725),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
