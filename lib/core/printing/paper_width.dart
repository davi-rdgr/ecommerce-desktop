/// Largura da bobina. O que muda de fato é quantos caracteres cabem na linha
/// na fonte padrão (Font A, 12 pontos de largura): 58mm dá 32, 80mm dá 48.
enum PaperWidth {
  mm58('58 mm', 32),
  mm80('80 mm', 48);

  final String label;

  /// Caracteres por linha em tamanho normal.
  final int columns;

  const PaperWidth(this.label, this.columns);

  static PaperWidth fromName(String? name) =>
      values.firstWhere((width) => width.name == name, orElse: () => mm80);
}
