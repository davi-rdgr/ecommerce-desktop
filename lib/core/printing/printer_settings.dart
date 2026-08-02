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

  final Box _box;

  /// `null` = nunca escolheram uma; nesse caso cai na padrão do Windows.
  final Signal<String?> printerName;

  final Signal<PaperWidth> paperWidth;

  PrinterSettings._(this._box)
    : printerName = signal(_box.get(_keyPrinter) as String?),
      paperWidth = signal(PaperWidth.fromName(_box.get(_keyPaper) as String?));

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

  void dispose() {
    printerName.dispose();
    paperWidth.dispose();
  }
}
