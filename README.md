# romeu_lanches_admin

Painel administrativo (desktop) do Romeu Lanches.

## Ambientes

O backend que o app chama é escolhido **no momento do build**, pela dart-define
`ENV`. A configuração fica toda em
[`lib/core/config/app_environment.dart`](lib/core/config/app_environment.dart).

| `ENV`   | API                                       | Tempo real (SockJS)                          |
| ------- | ----------------------------------------- | -------------------------------------------- |
| `local` | `http://localhost:8080`                   | `ws://localhost:8080/ws`                     |
| `hml`   | _ainda não existe — preencher no arquivo_ | —                                            |
| `prod`  | `https://romeu-backend-2ms6.onrender.com` | `wss://romeu-backend-2ms6.onrender.com/ws`   |

```sh
# Rodar local (o define é opcional: sem ENV, o app assume local)
flutter run -d windows --dart-define=ENV=local

# Rodar contra homologação
flutter run -d windows --dart-define=ENV=hml

# Build de ENTREGA ao cliente
flutter build windows --dart-define=ENV=prod
```

> **A versão entregue ao cliente SEMPRE é gerada com `--dart-define=ENV=prod`.**
> Sem o define, o build aponta para `localhost` e não funciona na máquina do
> cliente.

Proteções:

- O default é `local`: esquecer o define nunca aponta para produção por acidente.
- Fora de prod, aparece uma faixa **LOCAL** (verde) ou **HML** (roxa) no canto
  inferior esquerdo. Se ela aparecer no build de entrega, o build está errado.
- Um `ENV` desconhecido (ex.: `ENV=production`) ou um ambiente sem URL
  configurada faz o app falhar na abertura, em vez de chamar o backend errado.

Ali só moram URLs, que não são segredo. Credenciais continuam no backend.

## Gerar a versão de produção

Passo a passo para gerar o executável que vai para o cliente:

1. **Atualize a versão** em [`pubspec.yaml`](pubspec.yaml) (`version: X.Y.Z+N`):
   suba o `X.Y.Z` conforme a mudança e sempre incremente o `+N`.
2. **Gere um build limpo, com `ENV=prod`:**

   ```sh
   flutter clean
   flutter pub get
   flutter build windows --release --dart-define=ENV=prod
   ```

3. **Confira antes de entregar:** abra
   `build\windows\x64\runner\Release\romeu_lanches_admin.exe` e verifique que
   **não aparece nenhuma faixa** (LOCAL/HML) no canto inferior esquerdo, que o
   login funciona e que o painel mostra "Ao vivo".
4. **Entregue a pasta `Release` inteira**, não só o `.exe`: ele depende das DLLs
   e da pasta `data` que ficam ao lado. Compacte a pasta em `.zip` e envie.

> Se aparecer a faixa **LOCAL** ou **HML**, o build foi gerado sem
> `--dart-define=ENV=prod`. Gere de novo.

## Adaptar para outro cliente

Troque as URLs no enum `AppEnvironment`. Nada mais no app conhece a URL do
backend.
