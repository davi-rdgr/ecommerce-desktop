import 'package:romeu_lanches_admin/components/scaffolds/scaffold/scaffold_controller.dart';
import 'package:romeu_lanches_admin/core/network/api_client.dart';
import 'package:romeu_lanches_admin/core/printing/printer_settings.dart';
import 'package:romeu_lanches_admin/core/printing/ticket_printer.dart';
import 'package:romeu_lanches_admin/features/shop/data/store_service.dart';
import 'package:romeu_lanches_admin/features/shop/view/shop_controller.dart';

class ShopFullDependencies {
  late final StoreService storeService;
  late final ShopController shop;

  /// A impressora é config da máquina, não da loja — por isso [PrinterSettings]
  /// e [TicketPrinter] vêm de fora em vez de nascerem aqui: o painel de pedidos
  /// imprime com os mesmos.
  ShopFullDependencies(
    ApiClient api,
    ScaffoldController scaffold,
    PrinterSettings printerSettings,
    TicketPrinter ticketPrinter,
  ) {
    storeService = StoreService(api);
    shop = ShopController(storeService, scaffold, printerSettings,
        ticketPrinter);
  }
}
