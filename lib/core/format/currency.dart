/// Formata em real: `44.0` → `R$ 44,00`.
String brl(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

/// Só o número, para preencher campo editável: `44.0` → `44,00`.
String brlAmount(double value) =>
    value.toStringAsFixed(2).replaceAll('.', ',');

/// Aceita `24,90` e `24.90`. Devolve `null` se não for um valor válido.
double? parseBrl(String text) {
  final cleaned = text.trim().replaceAll('R\$', '').replaceAll(',', '.').trim();
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  return (value == null || value < 0) ? null : value;
}
