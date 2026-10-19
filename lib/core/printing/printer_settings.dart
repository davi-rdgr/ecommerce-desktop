import 'package:hive_flutter/hive_flutter.dart';
import 'package:romeu_lanches_admin/core/printing/paper_width.dart';
import 'package:romeu_lanches_admin/core/printing/windows_raw_printer.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Qual impressora recebe a comanda e em que largura de bobina.
///
/// Fica no Hive porque é config da **máquina**, não da conta: o PC do balcão
/// tem a térmica, e trocar de operador não pode reconfigurar nada. Por isso
/// também não vai para a API.
class PrinterSettings {
  static const _boxName = 'printer';
  static const _keyPrinter = 'name';
  static const _keyPaper = 'paper';
  static const _keyCopies = 'copies';

  /// Vias aceitas: uma para a cozinha, e opcionalmente outra para o
  /// balcão/entrega.
  static const copyOptions = [1, 2];

  final Box _box;

  /// `null` = nunca escolheram uma; nesse caso cai na padrão do Windows.
  final Signal<String?> printerName;

  final Signal<PaperWidth> paperWidth;

  /// Quantas vias de cada comanda saem. Padrão 1.
  final Signal<int> ticketCopies;

  PrinterSettings._(this._box)
    : printerName = signal(_box.get(_keyPrinter) as String?),
      paperWidth = signal(PaperWidth.fromName(_box.get(_keyPaper) as String?)),
      ticketCopies = signal(_copiesFrom(_box.get(_keyCopies)));

  /// Valor estranho na box (versão futura, edição na mão) volta para 1 via em
  /// vez de imprimir uma pilha de comandas.
  static int _copiesFrom(Object? raw) =>
      copyOptions.contains(raw) ? raw as int : copyOptions.first;

  static Future<PrinterSettings> open() async =>
      PrinterSettings._(await Hive.openBox(_boxName));

  /// A impressora que vai receber o trabalho agora: a escolhida, ou a padrão
  /// do sistema enquanto ninguém escolheu.
  String? get target => printerName.value ?? WindowsRawPrinter.defaultPrinter();

  Future<void> selectPrinter(String? name) async {
    printerName.value = name;
    if (name == null) {
      await _box.delete(_keyPrinter);
    } else {
      await _box.put(_keyPrinter, name);
    }
  }

  Future<void> selectPaper(PaperWidth width) async {
    paperWidth.value = width;
    await _box.put(_keyPaper, width.name);
  }

  Future<void> selectCopies(int copies) async {
    if (!copyOptions.contains(copies)) return;
    ticketCopies.value = copies;
    await _box.put(_keyCopies, copies);
  }

  void dispose() {
    printerName.dispose();
    paperWidth.dispose();
    ticketCopies.dispose();
  }
}
