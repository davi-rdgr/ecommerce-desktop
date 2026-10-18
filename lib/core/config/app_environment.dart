/// Ambiente de backend que o app consome, escolhido em tempo de compilação.
///
/// O ambiente vem da dart-define `ENV` (`local`, `hml` ou `prod`). Sem nada,
/// assume [local] — nunca produção por acidente.
///
/// ```sh
/// # Rodar local (o define é opcional, local já é o default)
/// flutter run -d windows --dart-define=ENV=local
///
/// # Rodar contra homologação
/// flutter run -d windows --dart-define=ENV=hml
///
/// # Versão de ENTREGA ao cliente — SEMPRE com ENV=prod
/// flutter build windows --dart-define=ENV=prod
/// ```
///
/// Fora de prod, o app mostra uma faixa com [label] no canto da tela. Se ela
/// aparecer no build de entrega, o build está apontando para o backend errado.
///
/// Só URLs moram aqui — nada de segredo. Credenciais ficam no backend.
enum AppEnvironment {
  local(label: 'LOCAL', baseUrl: 'http://localhost:8080'),

  // TODO: preencher quando o ambiente de homologação for criado.
  hml(label: 'HML', baseUrl: 'https://COLOCAR-URL-HML'),

  prod(label: 'PROD', baseUrl: 'https://romeu-backend-2ms6.onrender.com');

  /// Nome curto exibido na faixa de ambiente.
  final String label;

  /// Raiz da API REST, sem barra no final.
  final String baseUrl;

  const AppEnvironment({required this.label, required this.baseUrl});

  /// Endpoint do canal em tempo real.
  ///
  /// Fica em http(s) porque o cliente é SockJS: ele mesmo troca para
  /// ws(s):// ao abrir o WebSocket (local → ws://localhost:8080/ws,
  /// prod → wss://romeu-backend-2ms6.onrender.com/ws).
  String get wsUrl => '$baseUrl/ws';

  bool get isLocal => this == local;
  bool get isHml => this == hml;
  bool get isProd => this == prod;

  static const _rawEnv = String.fromEnvironment('ENV', defaultValue: 'local');

  /// Ambiente deste build. Lança [StateError] se `ENV` tiver um valor
  /// desconhecido ou apontar para um ambiente ainda sem URL — melhor o app
  /// não subir do que subir chamando o backend errado.
  static final AppEnvironment current = _resolve();

  static AppEnvironment _resolve() {
    final env = values
        .where((e) => e.name == _rawEnv.toLowerCase())
        .firstOrNull;
    if (env == null) {
      throw StateError(
        'ENV inválido: "$_rawEnv". Use --dart-define=ENV=local, hml ou prod.',
      );
    }
    if (env.baseUrl.contains('COLOCAR-URL')) {
      throw StateError(
        'O ambiente ${env.label} ainda não tem URL configurada em '
        'app_environment.dart.',
      );
    }
    return env;
  }
}
