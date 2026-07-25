/// Formata em real: `44.0` → `R$ 44,00`.
String brl(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
