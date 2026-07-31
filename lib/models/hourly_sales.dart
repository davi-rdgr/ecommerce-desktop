/// `VendaPorHoraResponse` — uma hora do expediente.
///
/// A lista vem com as **24 horas sempre presentes** (hora sem venda volta
/// zerada) e **já ordenada pelo dia operacional**: `2, 3, …, 23, 0, 1`.
///
/// Não reordene por [hour]. As horas `0` e `1` são a madrugada do **fim** do
/// expediente e pertencem ao fim da série — ordenar crescente joga a madrugada
/// para a esquerda e parte a curva em duas.
class HourlySales {
  /// Hora local de Brasília em que o pedido foi **criado**, de 0 a 23.
  final int hour;

  /// Pedidos concluídos nessa hora.
  final int quantity;

  const HourlySales({required this.hour, required this.quantity});

  /// `"02h"`.
  String get label => '${hour.toString().padLeft(2, '0')}h';

  factory HourlySales.fromJson(Map<String, dynamic> json) => HourlySales(
    hour: json['hora'] as int,
    quantity: (json['quantidade'] as num).toInt(),
  );
}
