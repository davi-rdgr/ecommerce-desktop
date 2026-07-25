import 'package:romeu_lanches_admin/core/network/api_client.dart';
import 'package:romeu_lanches_admin/models/order.dart';
import 'package:romeu_lanches_admin/models/order_detail.dart';
import 'package:romeu_lanches_admin/models/order_status.dart';

class OrderService {
  final ApiClient _api;

  const OrderService(this._api);

  /// `GET /admin/pedidos?status=` — o filtro é obrigatório, não existe
  /// "listar todos". O kanban faz uma chamada por coluna.
  Future<List<Order>> listByStatus(OrderStatus status) async {
    final json = await _api.get('/admin/pedidos?status=${status.wire}');
    return (json as List)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /admin/pedidos/{id}` — pedido completo, com itens e endereço.
  Future<OrderDetail> detail(String id) async {
    final json = await _api.get('/admin/pedidos/$id');
    return OrderDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<OrderDetail> accept(String id) => _patch('/admin/pedidos/$id/aceitar');

  Future<OrderDetail> markReady(String id) =>
      _patch('/admin/pedidos/$id/pronto');

  Future<OrderDetail> finish(String id) =>
      _patch('/admin/pedidos/$id/concluir');

  Future<OrderDetail> cancel(String id) =>
      _patch('/admin/pedidos/$id/cancelar');

  Future<OrderDetail> _patch(String path) async {
    final json = await _api.patch(path);
    return OrderDetail.fromJson(json as Map<String, dynamic>);
  }
}
