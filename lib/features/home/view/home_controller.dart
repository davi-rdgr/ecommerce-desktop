import 'dart:async';

import 'package:romeu_lanches_admin/core/format/currency.dart';
import 'package:romeu_lanches_admin/core/network/api_exception.dart';
import 'package:romeu_lanches_admin/core/printing/ticket_printer.dart';
import 'package:romeu_lanches_admin/core/printing/windows_raw_printer.dart';
import 'package:romeu_lanches_admin/features/home/data/order_service.dart';
import 'package:romeu_lanches_admin/features/home/data/orders_realtime.dart';
import 'package:romeu_lanches_admin/features/report/data/report_service.dart';
import 'package:romeu_lanches_admin/models/daily_report.dart';
import 'package:romeu_lanches_admin/models/order.dart';
import 'package:romeu_lanches_admin/models/order_detail.dart';
import 'package:romeu_lanches_admin/models/order_status.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

class HomeController {
  final OrderService _service;
  final ReportService _reportService;
  final OrdersRealtime _realtime;
  final TicketPrinter _printer;

  HomeController(
    this._service,
    this._reportService,
    this._realtime,
    this._printer,
  ) {
    _realtime.onOrderChanged = _applyRealtimeOrder;
    _realtime.onResync = refresh;
  }

  /// Estado do canal de tempo real, exibido no painel.
  Signal<RealtimeStatus> get realtimeStatus => _realtime.status;

  void startRealtime() => _realtime.start();

  void stopRealtime() => _realtime.stop();

  final isLoading = signal(false);
  final loadError = signal<String?>(null);
  final orders = signal<List<Order>>([]);

  /// Fechamento do dia vindo do servidor — alimenta os dois cards de "HOJE".
  /// `null` enquanto a primeira chamada não voltou.
  final dailyReport = signal<DailyReport?>(null);

  /// Pedidos com um PATCH em voo — o card trava o botão para não disparar
  /// a mesma transição duas vezes no aperto do movimento.
  final pendingIds = signal<Set<String>>({});

  /// Pedidos com uma comanda no spooler. Separado de [pendingIds] porque
  /// imprimir não mexe no status: travar as duas coisas juntas impediria de
  /// aceitar o pedido enquanto a comanda sai.
  final printingIds = signal<Set<String>>({});

  final headerTitle = 'Pedidos';
  final headerSubtitle = 'Acompanhe e gerencie os pedidos em tempo real';

  static const List<({OrderStatus status, String label, Color color})> columns =
      [
        (
          status: OrderStatus.newOrder,
          label: 'Novos',
          color: Color(0xFFE23725),
        ),
        (
          status: OrderStatus.inProgress,
          label: 'Em preparo',
          color: Color(0xFFF59E0B),
        ),
        (
          status: OrderStatus.ready,
          label: 'A caminho / pronto',
          color: Color(0xFF3B82F6),
        ),
        (
          status: OrderStatus.finished,
          label: 'Concluídos',
          color: Color(0xFF1B9E54),
        ),
      ];

  late final activeOrders = computed(
    () => orders.value.where((o) => o.status.isActive).length,
  );

  /// "EM ANDAMENTO" é o kanban ao vivo, então sai da lista. Os dois de "HOJE"
  /// **não**: a coluna de concluídos são os 30 mais recentes que o servidor
  /// manda (§6.1), não os do dia — somar ela daria contagem e faturamento
  /// errados nos dois sentidos. Quem fecha a conta do dia civil, no fuso certo
  /// (America/Sao_Paulo), é o `/admin/relatorio/dia`.
  late final homeStats = computed(() {
    final active = orders.value.where((o) => o.status.isActive).length;
    final today = dailyReport.value;
    return [
      (title: 'EM ANDAMENTO', value: active, color: const Color(0XFFE23725)),
      (
        title: 'CONCLUÍDOS HOJE',
        value: today == null ? '—' : '${today.orderCount}',
        color: const Color(0XFF1B9E54),
      ),
      (
        title: 'FATURADO HOJE',
        value: today == null ? '—' : brl(today.revenue),
        color: const Color(0XFF2A1F17),
      ),
    ];
  });

  /// O que a tela chama para se atualizar: kanban e números do dia são fontes
  /// diferentes e vão juntos, em paralelo.
  Future<void> refresh() async {
    await Future.wait([loadOrders(), loadDailyStats()]);
  }

  /// Uma chamada por coluna, em paralelo — `GET /admin/pedidos` exige `status`
  /// e não tem "listar todos".
  ///
  /// Nada é filtrado por data aqui: o servidor já corta os terminais nos 30
  /// mais recentes, e filtrar "hoje" no cliente derrubaria os concluídos da
  /// madrugada na virada da meia-noite — em plena hora de pico do turno.
  Future<void> loadOrders() async {
    isLoading.value = true;
    loadError.value = null;

    try {
      final pages = await Future.wait(
        columns.map((col) => _service.listByStatus(col.status)),
      );
      orders.value = pages.expand((page) => page).toList();
    } on ApiException catch (e) {
      loadError.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// Falha aqui não vira erro de tela: o kanban é o que o atendente precisa
  /// para trabalhar. Os cards de "HOJE" ficam com o último valor conhecido
  /// (ou "—") e voltam na próxima recarga.
  Future<void> loadDailyStats() async {
    try {
      dailyReport.value = await _reportService.loadToday();
    } on ApiException {
      // Silencioso de propósito — ver doc acima.
    }
  }

  Future<OrderDetail> loadOrderDetail(String id) => _service.detail(id);

  /// Manda a comanda para a térmica. Devolve `null` no sucesso, ou a mensagem
  /// a exibir.
  ///
  /// Nada de recarregar ou mudar status aqui: imprimir é um efeito local, o
  /// pedido segue exatamente onde estava. O atendente pode imprimir de novo
  /// quantas vezes quiser — via caiu, papel acabou, entregador perdeu.
  Future<String?> printTicket(Order order, OrderDetail detail) async {
    if (printingIds.value.contains(order.id)) return null;
    printingIds.value = {...printingIds.value, order.id};

    try {
      await _printer.printOrder(order: order, detail: detail);
      return null;
    } on PrinterException catch (e) {
      return e.message;
    } catch (e) {
      return 'Falha ao imprimir a comanda: $e';
    } finally {
      printingIds.value = {...printingIds.value}..remove(order.id);
    }
  }

  /// Empurra o pedido para a próxima etapa, conforme o status atual.
  ///
  /// Devolve `null` em caso de sucesso, ou a mensagem a exibir.
  Future<String?> advance(Order order) => switch (order.status) {
    OrderStatus.newOrder => _transition(order, _service.accept),
    OrderStatus.inProgress => _transition(order, _service.markReady),
    OrderStatus.ready => _transition(order, _service.finish),
    _ => Future.value('Este pedido não tem próxima etapa.'),
  };

  Future<String?> cancel(Order order) => _transition(order, _service.cancel);

  Future<String?> _transition(
    Order order,
    Future<OrderDetail> Function(String id) action,
  ) async {
    if (pendingIds.value.contains(order.id)) return null;
    pendingIds.value = {...pendingIds.value, order.id};

    try {
      final updated = await action(order.id);
      _applyStatus(order.id, updated.status);
      // Concluir move o faturamento e a contagem do dia, e essa conta é do
      // servidor. O card já andou (o signal acima), falta acertar o topo.
      if (updated.status == OrderStatus.finished) await loadDailyStats();
      return null;
    } on ApiException catch (e) {
      // 409 quer dizer que a tela está velha: ou outro atendente mexeu no
      // pedido, ou ele não estava no status que a gente achava. Recarregar
      // é a única saída que devolve a verdade.
      if (e.isConflict) {
        await refresh();
        return e.message;
      }
      return e.message;
    } finally {
      pendingIds.value = {...pendingIds.value}..remove(order.id);
    }
  }

  /// Aplica um pedido vindo do WebSocket.
  ///
  /// É um upsert de propósito: `PEDIDO_CRIADO` e `STATUS_ATUALIZADO` caem os
  /// dois aqui, e a transição que nós mesmos disparamos volta como evento
  /// pouco depois. Sem upsert, isso viraria card duplicado.
  void _applyRealtimeOrder(Order order) {
    final current = orders.value;
    final index = current.indexWhere((o) => o.id == order.id);

    // Sem coluna para ele: cancelado ou PIX ainda não pago. Se estava na tela,
    // sai. Concluído tem coluna e entra sem filtro de data — a coluna mostra o
    // que o servidor mandou, não "os de hoje".
    if (!order.status.isOnBoard) {
      if (index >= 0) orders.value = [...current]..removeAt(index);
      return;
    }

    orders.value = index >= 0
        ? ([...current]..[index] = order)
        : [...current, order];

    // Outro atendente concluiu: o número do topo é do servidor, não dá para
    // somar aqui. Vale a chamada extra quando o concluído foi nosso — o eco do
    // nosso próprio PATCH cai aqui também.
    if (order.status == OrderStatus.finished) unawaited(loadDailyStats());
  }

  /// O PATCH devolve o pedido atualizado, então dá para mexer só nele em vez
  /// de recarregar as 4 colunas a cada clique.
  ///
  /// Cancelado não tem coluna: sai da lista.
  void _applyStatus(String id, OrderStatus status) {
    orders.value = [
      for (final order in orders.value)
        if (order.id != id)
          order
        else if (status.isOnBoard)
          order.copyWith(status: status),
    ];
  }

  void dispose() {
    _realtime.dispose();
    isLoading.dispose();
    loadError.dispose();
    orders.dispose();
    dailyReport.dispose();
    pendingIds.dispose();
    printingIds.dispose();
    activeOrders.dispose();
    homeStats.dispose();
  }
}
