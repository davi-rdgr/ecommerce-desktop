/// Erro vindo da API, já normalizado nos formatos que o backend usa:
/// `{"error": "..."}`, `{"error": "Dados inválidos", "campos": {...}}` e `{"code": "..."}`.
class ApiException implements Exception {
  /// `null` quando a requisição nem chegou ao servidor (offline, timeout, backend fora).
  final int? statusCode;
  final String message;

  /// Código de negócio, quando o backend manda um (ex.: `NAO_CADASTRADO`).
  final String? code;

  /// Erros de validação por campo, no 400 `{"error": "Dados inválidos", "campos": {...}}`.
  final Map<String, String>? fields;

  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.fields,
  });

  const ApiException.network(this.message)
    : statusCode = null,
      code = null,
      fields = null;

  bool get isNetworkFailure => statusCode == null;

  /// Token ausente, inválido ou expirado — ou credenciais erradas no login.
  bool get isUnauthorized => statusCode == 401;

  /// Autenticado, mas sem a role exigida.
  bool get isForbidden => statusCode == 403;

  bool get isNotFound => statusCode == 404;

  /// Conflito de estado: loja fechada, transição inválida, edição concorrente...
  bool get isConflict => statusCode == 409;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
