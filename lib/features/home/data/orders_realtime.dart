import 'dart:convert';

import 'package:romeu_lanches_admin/core/auth/auth_session.dart';
import 'package:romeu_lanches_admin/core/network/api_config.dart';
import 'package:romeu_lanches_admin/models/order.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

enum RealtimeStatus {
  /// Canal desligado — antes de entrar no painel ou depois de perder a sessão.
  offline('Sem conexão'),

  /// Tentando (re)conectar. O painel pode estar desatualizado.
  connecting('Reconectando'),

  /// Recebendo eventos.
  live('Ao vivo');

  final String label;

  const RealtimeStatus(this.label);
}

/// Canal STOMP de `/topic/admin/pedidos`.
///
/// O broker é in-memory e não tem replay: tudo que for emitido enquanto a
/// conexão estiver caída se perde para sempre. Por isso toda reconexão dispara
/// [onResync] antes de o painel voltar a confiar nos eventos.
class OrdersRealtime {
  static const _topic = '/topic/admin/pedidos';

  final AuthSession _session;

  OrdersRealtime(this._session);

  final status = signal(RealtimeStatus.offline);

  /// Pedido criado ou atualizado. No canal do admin o `dado` é sempre um
  /// `PedidoResumoResponse`, tanto em `PEDIDO_CRIADO` quanto em
  /// `STATUS_ATUALIZADO`, então os dois caem aqui.
  void Function(Order order)? onOrderChanged;

  /// Chamado a cada **re**conexão, para recuperar o que se perdeu na queda.
  Future<void> Function()? onResync;

  StompClient? _client;
  bool _connectedBefore = false;

  void start() {
    if (_client != null) return;

    final token = _session.token.value;
    if (token == null) return;

    status.value = RealtimeStatus.connecting;

    _client = StompClient(
      config: StompConfig.sockJS(
        url: '${ApiConfig.baseUrl}/ws',
        // A autenticação acontece no frame CONNECT, não no handshake HTTP.
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        reconnectDelay: const Duration(seconds: 5),
        onConnect: _onConnect,
        onDisconnect: (_) => _onDropped(),
        onStompError: (_) => _onDropped(),
        onWebSocketError: (_) => _onDropped(),
        onWebSocketDone: _onDropped,
      ),
    )..activate();
  }

  void stop() {
    _client?.deactivate();
    _client = null;
    _connectedBefore = false;
    status.value = RealtimeStatus.offline;
  }

  void _onConnect(StompFrame frame) {
    status.value = RealtimeStatus.live;
    _client?.subscribe(destination: _topic, callback: _onMessage);

    // Na primeira conexão quem abriu a tela já carregou a lista; recarregar
    // aqui só duplicaria a chamada.
    if (_connectedBefore) onResync?.call();
    _connectedBefore = true;
  }

  void _onDropped() {
    // `stop()` zera o client — sem isso, a parada intencional apareceria
    // como "reconectando".
    if (_client == null) return;
    status.value = RealtimeStatus.connecting;
  }

  void _onMessage(StompFrame frame) {
    final body = frame.body;
    if (body == null || body.isEmpty) return;

    try {
      final envelope = jsonDecode(body) as Map<String, dynamic>;
      final data = envelope['dado'] as Map<String, dynamic>?;
      if (data == null) return;
      onOrderChanged?.call(Order.fromJson(data));
    } catch (_) {
      // Evento malformado não pode derrubar o painel no meio do movimento.
      // A próxima recarga corrige o estado.
    }
  }

  void dispose() {
    stop();
    status.dispose();
  }
}
