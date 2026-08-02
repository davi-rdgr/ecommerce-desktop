import 'dart:isolate';
import 'dart:typed_data';

import 'package:romeu_lanches_admin/core/printing/esc_pos_document.dart';
import 'package:romeu_lanches_admin/core/printing/order_ticket.dart';
import 'package:romeu_lanches_admin/core/printing/printer_settings.dart';
import 'package:romeu_lanches_admin/core/printing/windows_raw_printer.dart';
import 'package:romeu_lanches_admin/models/order.dart';
import 'package:romeu_lanches_admin/models/order_detail.dart';

/// Junta config + conteúdo + spooler: é o que a UI chama.
class TicketPrinter {
  final PrinterSettings _settings;

  const TicketPrinter(this._settings);

  Future<void> printOrder({
    required Order order,
    required OrderDetail detail,
  }) {
    final bytes = OrderTicket.build(
      order: order,
      detail: detail,
      paper: _settings.paperWidth.value,
    );
    return _send(bytes, 'Comanda #${detail.number}');
  }

  /// Cupom de conferência da tela de Loja. A régua numerada existe para
  /// decidir a largura sem chutar: se a régua couber inteira numa linha, a
  /// largura configurada bate com a bobina.
  Future<void> printTest() {
    final paper = _settings.paperWidth.value;
    final doc = EscPosDocument(paper);

    doc.align(EscPosAlign.center);
    doc.bold(true);
    doc.text('TESTE DE IMPRESSAO');
    doc.bold(false);
    doc.text('Romeu Lanches');
    doc.align(EscPosAlign.left);

    doc.rule('=');
    doc.row('Largura', paper.label);
    doc.row('Colunas', '${paper.columns}');
    doc.text('Impressora: ${_settings.target ?? '-'}');
    doc.rule();

    doc.text('Acentos: coracao, cartao, ~ nao, acucar');
    doc.text('Acentuado: coração, cartão, não, açúcar');
    doc.blank();

    doc.text('Regua (deve caber numa linha so):');
    final ruler = StringBuffer();
    for (var i = 1; i <= paper.columns; i++) {
      ruler.write(i % 10);
    }
    doc.text(ruler.toString());

    doc.rule('=');
    doc.feed(2);
    doc.cut();

    return _send(doc.bytes, 'Teste de impressão');
  }

  /// O envio vai para um isolate: `WritePrinter` é síncrono e uma impressora
  /// desligada ou spooler travado congelaria o kanban em plena hora de pico.
  Future<void> _send(Uint8List bytes, String docName) async {
    final printer = _settings.target;

    if (printer == null) {
      throw const PrinterException(
        'Nenhuma impressora configurada. Escolha uma em Loja > Impressora.',
      );
    }

    await Isolate.run(
      () => WindowsRawPrinter.send(
        printer: printer,
        docName: docName,
        bytes: bytes,
      ),
    );
  }
}
