import 'package:romeu_lanches_admin/core/network/api_exception.dart';
import 'package:romeu_lanches_admin/features/home/data/order_service.dart';
import 'package:romeu_lanches_admin/features/home/data/orders_realtime.dart';
import 'package:romeu_lanches_admin/models/order.dart';
import 'package:romeu_lanches_admin/models/order_detail.dart';
import 'package:romeu_lanches_admin/models/order_status.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

class HomeController {
  final OrderService _service;
  final OrdersRealtime _realtime;

  HomeController(this._service, this._realtime) {
    _realtime.onOrderChanged = _applyRealtimeOrder;
    _realtime.onResync = loadOrders;
  }

  /// Estado do canal de tempo real, exibido no painel.
  Signal<RealtimeStatus> get realtimeStatus => _realtime.status;

  void startRealtime() => _realtime.start();

  void stopRealtime() => _realtime.stop();

  final isLoading = signal(false);
  final loadError = signal<String?>(null);
  final orders = signal<List<Order>>([]);

  /// Pedidos com um PATCH em voo — o card trava o botão para não disparar
  /// a mesma transição duas vezes no aperto do movimento.
  final pendingIds = signal<Set<String>>({});

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

  late final homeStats = computed(() {
    final all = orders.value;
    final active = all.where((o) => o.status.isActive).length;
    final done = all.where((o) => o.status == OrderStatus.finished).length;
    final revenue = all
        .where((o) => o.status == OrderStatus.finished)
        .fold(0.0, (sum, o) => sum + o.price);
    final revenueText = 'R\$ ${revenue.toStringAsFixed(2).replaceAll('.', ',')}';
    return [
      (title: 'EM ANDAMENTO',   value: active,      color: const Color(0XFFE23725)),
      (title: 'CONCLUÍDOS HOJE', value: done,        color: const Color(0XFF1B9E54)),
      (title: 'FATURADO HOJE',  value: revenueText, color: const Color(0XFF2A1F17)),
    ];
  });

  /// Uma chamada por coluna, em paralelo — `GET /admin/pedidos` exige `status`
  /// e não tem "listar todos".
  Future<void> loadOrders() async {
    isLoading.value = true;
    loadError.value = null;

    try {
      final pages = await Future.wait(
        columns.map((col) => _service.listByStatus(col.status)),
      );
      orders.value = [
        for (final page in pages)
          for (final order in page)
            if (order.status != OrderStatus.finished || _isToday(order.createdAt))
              order,
      ];
    } on ApiException catch (e) {
      loadError.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// `GET /admin/pedidos` não aceita filtro de data, então `CONCLUIDO` viria
  /// com o histórico inteiro da loja — a coluna cresceria sem fim e o
  /// "FATURADO HOJE" somaria todo o faturamento de sempre. O corte é aqui,
  /// no dia civil, igual ao que o `/admin/relatorio/dia` faz no servidor.
  ///
  /// Pedidos em andamento não passam por esse filtro: um pedido feito antes
  /// da meia-noite e ainda em preparo tem que continuar visível.
  bool _isToday(DateTime moment) {
    final now = DateTime.now();
    return moment.year == now.year &&
        moment.month == now.month &&
        moment.day == now.day;
  }

  Future<OrderDetail> loadOrderDetail(String id) => _service.detail(id);

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
      return null;
    } on ApiException catch (e) {
      // 409 quer dizer que a tela está velha: ou outro atendente mexeu no
      // pedido, ou ele não estava no status que a gente achava. Recarregar
      // é a única saída que devolve a verdade.
      if (e.isConflict) {
        await loadOrders();
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

    // Sem coluna para ele: cancelado, PIX ainda não pago, ou concluído de um
    // dia anterior. Se estava na tela, sai.
    final belongsOnBoard =
        order.status.isOnBoard &&
        (order.status != OrderStatus.finished || _isToday(order.createdAt));

    if (!belongsOnBoard) {
      if (index >= 0) orders.value = [...current]..removeAt(index);
      return;
    }

    orders.value = index >= 0
        ? ([...current]..[index] = order)
        : [...current, order];
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
    pendingIds.dispose();
    activeOrders.dispose();
    homeStats.dispose();
  }
}
