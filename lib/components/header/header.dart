import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_admin/core/di/app_dependencies.dart';
import 'package:signals_flutter/signals_flutter.dart';

class Header extends StatefulWidget {
  final String title;
  final String subtitle;

  const Header({super.key, required this.title, required this.subtitle});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  static const _weekdays = [
    'segunda',
    'terça',
    'quarta',
    'quinta',
    'sexta',
    'sábado',
    'domingo',
  ];

  late DateTime _now;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // Checa a cada segundo mas só repinta na virada do minuto — o relógio
    // mostra HH:mm e o painel fica aberto o turno inteiro.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      if (now.minute == _now.minute && now.day == _now.day) return;
      setState(() => _now = now);
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  String get _dateText {
    final weekday = _weekdays[_now.weekday - 1];
    final day = _now.day.toString().padLeft(2, '0');
    final month = _now.month.toString().padLeft(2, '0');
    return '$weekday, $day/$month';
  }

  String get _timeText {
    final hour = _now.hour.toString().padLeft(2, '0');
    final minute = _now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Até duas iniciais do nome que veio no login.
  String _initialsOf(String? name) {
    final words = (name ?? '').trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return 'RL';
    return words
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
  }

  /// "Sair" fica escondido no menu do avatar e ainda pede confirmação: sair
  /// apaga o token salvo e obriga a digitar a senha na próxima vez.
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sair do painel?',
          style: GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.w800,
            color: const Color(0XFF2A1F17),
          ),
        ),
        content: Text(
          'Para entrar de novo será preciso digitar o e-mail e a senha.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0XFFE23725),
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed == true) await deps.logout();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0XFFFFFFFF),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0XFF2A1F17),
                  ),
                ),
                Text(
                  widget.subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xff998875),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _dateText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0XFF998875),
                      ),
                    ),
                    Text(
                      _timeText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0XFF2A1F17),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 15),
                SignalBuilder(
                  builder: (context) {
                    final name = deps.session.adminName.value;
                    return PopupMenuButton<String>(
                      onSelected: (_) => _confirmLogout(),
                      tooltip: name ?? 'Sessão do administrador',
                      offset: const Offset(0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.logout,
                                size: 17,
                                color: Color(0XFF998875),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Sair',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: const Color(0XFF2A1F17),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        height: 42,
                        width: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          gradient: const LinearGradient(
                            colors: [Color(0XFFe23725), Color(0XFFf97316)],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _initialsOf(name),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0XFFFFFFFF),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
