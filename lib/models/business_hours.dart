/// `HorarioResponse` — um dia do horário de funcionamento.
///
/// É **decorativo**: não abre nem fecha a loja. A disponibilidade real vem do
/// toggle `aberta` da config, e pode contrariar o horário publicado.
class BusinessHours {
  /// Convenção `java.time.DayOfWeek`: 1 = Segunda … 7 = Domingo.
  ///
  /// Não é 0–6 começando no domingo, como o `Date.getDay()` do JavaScript.
  final int weekday;

  final bool open;

  /// `"HH:mm"`. Nulo quando o dia está fechado.
  final String? openAt;
  final String? closeAt;

  const BusinessHours({
    required this.weekday,
    required this.open,
    required this.openAt,
    required this.closeAt,
  });

  static const _labels = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];

  String get label => _labels[weekday - 1];

  /// A API pode mandar `"HH:mm"` ou `"HH:mm:ss"`; o painel só usa horas e
  /// minutos.
  static String? _hhmm(Object? raw) {
    if (raw is! String || raw.length < 5) return raw as String?;
    return raw.substring(0, 5);
  }

  factory BusinessHours.fromJson(Map<String, dynamic> json) => BusinessHours(
    weekday: json['diaSemana'] as int,
    open: json['aberto'] as bool,
    openAt: _hhmm(json['abertura']),
    closeAt: _hhmm(json['fechamento']),
  );

  BusinessHours copyWith({bool? open, String? openAt, String? closeAt}) =>
      BusinessHours(
        weekday: weekday,
        open: open ?? this.open,
        openAt: openAt ?? this.openAt,
        closeAt: closeAt ?? this.closeAt,
      );

  /// `AtualizarHorarioRequest`. Dia fechado não manda horas — a API descarta
  /// e grava `null` de qualquer forma.
  Map<String, dynamic> toRequest() => open
      ? {'aberto': true, 'abertura': openAt, 'fechamento': closeAt}
      : {'aberto': false};

  /// `18:30 → 00:00` é válido e quer dizer que o turno vira a madrugada.
  bool get crossesMidnight {
    final from = openAt;
    final to = closeAt;
    if (from == null || to == null) return false;
    return to.compareTo(from) <= 0;
  }
}
