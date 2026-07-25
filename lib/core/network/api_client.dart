import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:romeu_lanches_admin/core/auth/auth_session.dart';
import 'package:romeu_lanches_admin/core/network/api_config.dart';
import 'package:romeu_lanches_admin/core/network/api_exception.dart';

/// Cliente HTTP da API. Injeta o `Authorization` da sessão, decodifica o JSON
/// e converte qualquer resposta fora da faixa 2xx em [ApiException].
class ApiClient {
  final AuthSession _session;
  final http.Client _http;

  /// Chamado quando uma chamada **autenticada** volta 401 — sessão derrubada
  /// por reinício do backend, troca de `JWT_SECRET` ou relógio fora de hora.
  ///
  /// Não dispara no login: ali o 401 é credencial errada, e nesse momento a
  /// sessão ainda não tem token.
  void Function()? onUnauthorized;

  ApiClient(this._session, {http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, {Object? body}) async {
    final request = http.Request(method, Uri.parse('${ApiConfig.baseUrl}$path'))
      ..headers.addAll({
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
        ..._session.authHeader,
      });

    if (body != null) request.body = jsonEncode(body);

    try {
      final streamed = await _http.send(request).timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamed);
      return _handle(response);
    } on TimeoutException {
      throw const ApiException.network(
        'O servidor demorou demais para responder.',
      );
    } on SocketException {
      throw const ApiException.network(
        'Não foi possível conectar ao servidor. Verifique se o sistema está no ar.',
      );
    } on http.ClientException {
      throw const ApiException.network('Falha de comunicação com o servidor.');
    }
  }

  dynamic _handle(http.Response response) {
    final status = response.statusCode;
    // O backend responde em UTF-8, mas sem charset no header — sem isso os
    // acentos das mensagens de erro chegam quebrados.
    final body = utf8.decode(response.bodyBytes);

    if (status >= 200 && status < 300) {
      if (body.isEmpty) return null;
      return jsonDecode(body);
    }

    if (status == 401 && _session.token.value != null) onUnauthorized?.call();

    throw _errorFrom(status, body);
  }

  ApiException _errorFrom(int status, String body) {
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) json = decoded;
    } on FormatException {
      // 403 e alguns erros do Spring não vêm em JSON — cai no texto padrão.
    }

    final campos = json?['campos'];

    return ApiException(
      statusCode: status,
      message: json?['error'] as String? ?? _defaultMessage(status),
      code: json?['code'] as String?,
      fields: campos is Map
          ? campos.map((k, v) => MapEntry('$k', '$v'))
          : null,
    );
  }

  String _defaultMessage(int status) => switch (status) {
    400 => 'Requisição inválida.',
    401 => 'Sessão inválida ou expirada.',
    403 => 'Você não tem permissão para esta ação.',
    404 => 'Recurso não encontrado.',
    409 => 'A operação conflita com o estado atual.',
    502 => 'Falha na integração com o meio de pagamento.',
    _ => 'Erro inesperado do servidor ($status).',
  };

  void dispose() => _http.close();
}
