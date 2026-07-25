# Romeu Lanches — API Backend (referência para clientes)

Backend Spring Boot (Java) da lanchonete. Este documento descreve **todos** os endpoints
REST, o canal WebSocket, os contratos de dados e as regras de negócio observáveis pelo
cliente. Serve como referência para o app do cliente e o painel do admin.

---

## 1. Fundamentos

| Item | Valor |
|---|---|
| Base URL (local) | `http://localhost:8080` |
| Context path | nenhum — as rotas começam na raiz (`/auth`, `/public`, `/app`, `/admin`) |
| Autenticação | JWT via header `Authorization: Bearer <token>` |
| Formato | JSON (`application/json`) em requests e responses |
| Sessão | **stateless** — não há cookie de sessão, nem CSRF (desabilitado) |
| Swagger UI | `GET /swagger-ui/index.html` (público) |
| OpenAPI JSON | `GET /v3/api-docs` (público) |
| Health check | `GET /actuator/health` (público) |

### Convenções de tipos

- **IDs**: `UUID` em string (ex.: `"3fa85f64-5717-4562-b3fc-2c963f66afa6"`).
- **Dinheiro**: `BigDecimal` serializado como **número JSON** com 2 casas (ex.: `24.90`).
- **Datas**: `OffsetDateTime` em ISO-8601 com offset (ex.: `"2026-07-25T19:42:10.123-03:00"`);
  `LocalDate` como `"2026-07-25"`.
- **Enums**: sempre a string exata em MAIÚSCULAS (ver §2).

### Papéis (roles) e regras do filtro de segurança

O JWT carrega `sub` = UUID da entidade autenticada e a claim `role`:

| Role | `sub` do token | Emitido por |
|---|---|---|
| `ROLE_ADMIN` | id do `UsuarioAdmin` | `POST /auth/admin/login` |
| `ROLE_CLIENTE` | id do `Cliente` | `POST /auth/cliente/login` e `/register` |

Expiração padrão: **24 h** (`JWT_EXPIRATION_MS`, default `86400000`).

Regras de acesso (`SecurityConfig`):

| Rota | Acesso |
|---|---|
| `POST /auth/**` | público (**apenas POST**) |
| `GET /public/**` | público (**apenas GET**) |
| `POST /webhook/**` | público (protegido por assinatura HMAC do Mercado Pago) |
| `/ws/**` | handshake liberado; autenticação ocorre no CONNECT do STOMP |
| `GET /actuator/health`, `/swagger-ui/**`, `/v3/api-docs/**`, `/error` | público |
| `/admin/**` | exige `ROLE_ADMIN` |
| `/app/**` | exige **estar autenticado** (qualquer role) |
| qualquer outra | exige estar autenticado |

⚠️ **Detalhe importante para o front:** `/app/**` só exige "autenticado", não `ROLE_CLIENTE`.
Um token de admin passa pelo filtro, mas os serviços resolvem o cliente por
`UUID.fromString(sub)` — um admin em `/app/**` recebe `404 {"error":"Cliente não encontrado"}`.
Trate `/app/**` como área exclusiva do app do cliente.

---

## 2. Enums

```
StatusPedido    : AGUARDANDO_PAGAMENTO | NOVO | EM_PREPARO | PRONTO | CONCLUIDO | CANCELADO
StatusPagamento : PENDENTE | APROVADO | RECUSADO | EXPIRADO | CANCELADO
TipoEntrega     : ENTREGA | RETIRADA
FormaPagamento  : PIX | CARTAO | DINHEIRO
```

### Máquina de estados do pedido

```
                    PIX  →  AGUARDANDO_PAGAMENTO ──(webhook: pagamento aprovado)──→ NOVO
                                     │
                                     └──(PIX expirado, job de 5 min)──→ CANCELADO

  DINHEIRO/CARTAO  →  NOVO ──aceitar──→ EM_PREPARO ──pronto──→ PRONTO ──concluir──→ CONCLUIDO
                       │                    │                    │
                       └──── cancelar ──────┴────────────────────┘  → CANCELADO
```

Transições permitidas pelas rotas de admin (qualquer outra → **409**):

| De | Para |
|---|---|
| `NOVO` | `EM_PREPARO`, `CANCELADO` |
| `EM_PREPARO` | `PRONTO`, `CANCELADO` |
| `PRONTO` | `CONCLUIDO`, `CANCELADO` |

⚠️ `AGUARDANDO_PAGAMENTO` **não** tem transição manual: o admin não consegue aceitar nem
cancelar um pedido PIX não pago (retorna 409). Ele sai desse estado só pelo webhook
(→ `NOVO`) ou pelo job de expiração (→ `CANCELADO`).

---

## 3. Autenticação — `/auth` (público, POST)

### `POST /auth/admin/login`
```json
// request  — LoginAdminRequest
{ "email": "admin@romeu.com", "senha": "segredo" }
// 200 — LoginResponse
{ "token": "eyJhbGciOi...", "nome": "Romeu" }
```
Erros: `401 {"error":"Credenciais inválidas"}`.

### `POST /auth/cliente/login`
```json
// request — LoginClienteRequest (CPF e telefone: pontuação é ignorada)
{ "cpf": "123.456.789-09", "telefone": "(51) 99999-8888" }
// 200 — LoginResponse
{ "token": "eyJhbGciOi...", "nome": "Maria" }
```
Erros:
- `404 {"code":"NAO_CADASTRADO"}` → CPF não existe. **Sinal para o front abrir o cadastro.**
  (note que esse corpo usa `code`, não `error`)
- `401 {"error":"Credenciais inválidas"}` → telefone não confere.

### `POST /auth/cliente/register`
```json
// request — RegisterClienteRequest
{ "cpf": "12345678909", "nome": "Maria", "telefone": "51999998888" }
// 200 — LoginResponse (já retorna token; não precisa logar depois)
{ "token": "eyJhbGciOi...", "nome": "Maria" }
```
Erros: `400 {"error":"CPF inválido"}` (dígitos verificadores), `409 {"error":"CPF já cadastrado"}`.

> Login do cliente é **CPF + telefone** — não há senha nem e-mail. O e-mail do cliente
> fica `null` no cadastro.

---

## 4. Público — `/public` (sem token, apenas GET)

### `GET /public/cardapio` → `CardapioResponse`
```json
{
  "categorias": [
    {
      "id": "uuid", "nome": "Lanches", "ordem": 1,
      "produtos": [
        {
          "id": "uuid", "categoriaId": "uuid", "categoriaNome": "Lanches",
          "nome": "X-Burger", "descricao": "pão, carne, queijo",
          "preco": 24.90, "disponivel": true,
          "imagemUrl": "https://...", "ordem": 1
        }
      ]
    }
  ]
}
```
Regras: retorna **apenas** categorias `ativo=true` **que tenham ao menos um produto
disponível**; produtos vêm ordenados. Categoria ativa sem produto disponível é omitida.

### `GET /public/produtos/{id}` → `ProdutoResponse`
Retorna o produto mesmo se `disponivel=false` ou de categoria inativa. `404` se não existir.

### `GET /public/produtos/{id}/adicionais` → `AdicionalResponse[]`
Adicionais **ativos vinculados à categoria do produto**, ordenados por nome.
```json
[ { "id": "uuid", "nome": "Bacon", "preco": 4.00, "ativo": true } ]
```

### `GET /public/adicionais` → `AdicionalResponse[]`
Todos os adicionais ativos do catálogo (sem vínculo de categoria).

### `GET /public/loja/status` → `LojaStatusResponse`
```json
{ "aberta": true }
```
Só expõe `aberta` — flags internas (taxa, formas de pagamento) não vazam aqui.

---

## 5. App do cliente — `/app` (exige `ROLE_CLIENTE`)

### 5.1 Endereços — `/app/enderecos`

Todos escopados ao cliente do token. Remoção é **soft delete** (`ativo=false`);
endereços removidos não aparecem na listagem e não podem ser usados em pedidos.

| Método | Rota | Body | Sucesso |
|---|---|---|---|
| `POST` | `/app/enderecos` | `EnderecoRequest` | **201** `EnderecoResponse` |
| `GET` | `/app/enderecos` | — | 200 `EnderecoResponse[]` (mais recentes primeiro) |
| `PUT` | `/app/enderecos/{id}` | `EnderecoRequest` | 200 `EnderecoResponse` |
| `DELETE` | `/app/enderecos/{id}` | — | **204** sem corpo |

```json
// EnderecoRequest — rua, numero, bairro obrigatórios
{ "rua": "Av. Brasil", "numero": "1200", "bairro": "Centro",
  "complemento": "ap 302", "referencia": "ao lado da praça" }

// EnderecoResponse
{ "id": "uuid", "rua": "Av. Brasil", "numero": "1200", "bairro": "Centro",
  "complemento": "ap 302", "referencia": "ao lado da praça" }
```
`404 {"error":"Endereço não encontrado"}` se o id não existir, for de outro cliente ou já removido.

### 5.2 Pedidos — `/app/pedidos`

#### `POST /app/pedidos` → **201** `PedidoResponse`
```json
// CriarPedidoRequest
{
  "tipoEntrega": "ENTREGA",           // obrigatório
  "formaPagamento": "PIX",            // obrigatório
  "enderecoId": "uuid",               // obrigatório se tipoEntrega=ENTREGA; ignorado em RETIRADA
  "observacao": "sem cebola",
  "itens": [                          // obrigatório, não vazio
    {
      "produtoId": "uuid",            // obrigatório
      "quantidade": 2,                // > 0
      "adicionalIds": ["uuid", "uuid"],   // opcional; duplicados são deduplicados
      "observacao": "bem passado"
    }
  ]
}
```

Regras de criação, na ordem em que falham:
1. **Loja fechada** (`aberta=false`) → `409 {"error":"Loja fechada no momento"}`.
2. **Forma de pagamento não habilitada** na config → `400 {"error":"Forma de pagamento não aceita"}`.
3. `ENTREGA` **sem** `enderecoId` → `400 {"error":"Endereço é obrigatório para entrega"}`;
   endereço inexistente / de outro cliente / removido → `400 {"error":"Endereço inválido"}`.
4. Produto inexistente → `404`; produto com `disponivel=false` → `409 {"error":"Produto indisponível: X"}`.
5. Adicional que não pertence à categoria do produto, ou inativo →
   `400 {"error":"Adicional inválido para este produto"}`.

Cálculo (feito no servidor — o front **não** envia preços):
- `precoUnitario = preco(produto) + soma(precos dos adicionais)`
- `subtotal(item) = precoUnitario × quantidade`
- `subtotal(pedido) = soma dos itens`
- `taxaEntrega = config.taxaEntrega` se `ENTREGA`, senão `0.00`
- `total = subtotal + taxaEntrega` (2 casas, HALF_UP)

Preços e nomes são **congelados (snapshot)** no pedido: alterar o produto depois não muda
pedidos já feitos.

Status inicial: `PIX` → `AGUARDANDO_PAGAMENTO`; `DINHEIRO`/`CARTAO` → `NOVO`.
Pedido PIX **não aparece no kanban do admin** até o pagamento ser aprovado.

```json
// PedidoResponse
{
  "id": "uuid",
  "numero": 1042,                      // número sequencial legível
  "status": "AGUARDANDO_PAGAMENTO",
  "tipoEntrega": "ENTREGA",
  "formaPagamento": "PIX",
  "endereco": {                        // null quando tipoEntrega=RETIRADA
    "rua": "Av. Brasil", "numero": "1200", "bairro": "Centro",
    "complemento": "ap 302", "referencia": "ao lado da praça"
  },
  "subtotal": 49.80,
  "taxaEntrega": 8.00,
  "total": 57.80,
  "observacao": "sem cebola",
  "criadoEm": "2026-07-25T19:42:10.123-03:00",
  "itens": [
    {
      "id": "uuid", "nome": "X-Burger", "precoUnitario": 24.90,
      "quantidade": 2, "subtotal": 49.80, "observacao": "bem passado",
      "adicionais": [ { "id": "uuid", "nome": "Bacon", "preco": 4.00 } ]
    }
  ]
}
```
⚠️ `precoUnitario` do item é o **preço do produto** (snapshot), sem os adicionais;
os adicionais estão somados dentro de `subtotal`.

#### `GET /app/pedidos` → `PedidoResumoResponse[]`
Só os pedidos do cliente autenticado.
```json
[{
  "id": "uuid", "numero": 1042, "status": "EM_PREPARO",
  "tipoEntrega": "ENTREGA", "formaPagamento": "PIX",
  "nomeCliente": "Maria", "total": 57.80, "quantidadeItens": 2,
  "criadoEm": "2026-07-25T19:42:10.123-03:00"
}]
```

#### `GET /app/pedidos/{id}` → `PedidoResponse`
`404` se o pedido não for do cliente autenticado (não vaza existência).

#### `POST /app/pedidos/{id}/pagamento` → `PagamentoResponse`
Gera a cobrança PIX no Mercado Pago.
```json
{
  "pixCopiaCola": "00020126580014BR.GOV.BCB.PIX...",
  "pixQrBase64": "iVBORw0KGgoAAAANS...",     // PNG em base64, sem prefixo data:
  "expiraEm": "2026-07-25T20:12:10.123-03:00",
  "valor": 57.80,
  "status": "PENDENTE"
}
```
Regras:
- Só funciona com `formaPagamento=PIX` **e** `status=AGUARDANDO_PAGAMENTO`;
  senão `409 {"error":"Pedido não está aguardando pagamento PIX"}`.
- **Idempotente**: se já existe PIX `PENDENTE` não expirado, devolve o mesmo QR
  (pode chamar de novo sem gerar cobrança duplicada).
- Expira em **30 minutos**.
- Falha na integração com o MP → `502 {"error":"Falha ao gerar pagamento"}`.
- Um job varre a cada 5 min: PIX vencido sem pagamento → pagamento `EXPIRADO` e
  pedido `CANCELADO` (o cliente recebe evento `STATUS_ATUALIZADO` no WebSocket).

O front **nunca** confirma pagamento: a confirmação chega pelo webhook do MP e é
propagada via WebSocket (pedido vai de `AGUARDANDO_PAGAMENTO` para `NOVO`).

---

## 6. Painel admin — `/admin` (exige `ROLE_ADMIN`)

### 6.1 Pedidos — `/admin/pedidos`

#### `GET /admin/pedidos?status=NOVO` → `PedidoResumoResponse[]`
⚠️ `status` é **obrigatório** e não tem default — sem ele: `400`. Valor deve ser um
`StatusPedido` exato (maiúsculas). Para montar um kanban, faça uma chamada por coluna.

#### `GET /admin/pedidos/{id}` → `PedidoResponse`
Sem filtro por cliente (admin vê qualquer pedido). `404` se não existir.

#### Transições (todas `PATCH`, sem body, retornam `PedidoResponse`)

| Rota | Efeito | Exige status atual |
|---|---|---|
| `PATCH /admin/pedidos/{id}/aceitar` | → `EM_PREPARO` | `NOVO` |
| `PATCH /admin/pedidos/{id}/pronto` | → `PRONTO` | `EM_PREPARO` |
| `PATCH /admin/pedidos/{id}/concluir` | → `CONCLUIDO` | `PRONTO` |
| `PATCH /admin/pedidos/{id}/cancelar` | → `CANCELADO` | `NOVO`, `EM_PREPARO` ou `PRONTO` |

Status incompatível → `409 {"error":"Não é possível aceitar um pedido com status PRONTO"}`.
Edição concorrente (dois atendentes) → `409 {"error":"O pedido foi modificado, tente novamente"}`
(lock otimista) — o front deve recarregar e tentar de novo.

### 6.2 Produtos — `/admin/produtos`

| Método | Rota | Body | Retorno |
|---|---|---|---|
| `GET` | `/admin/produtos` | — | `ProdutoResponse[]` (todos, inclusive indisponíveis) |
| `POST` | `/admin/produtos` | `ProdutoRequest` | **200** `ProdutoResponse` |
| `PUT` | `/admin/produtos/{id}` | `ProdutoRequest` | 200 `ProdutoResponse` |
| `PATCH` | `/admin/produtos/{id}/disponibilidade` | `{"disponivel": false}` | 200 `ProdutoResponse` |

```json
// ProdutoRequest — categoriaId, nome e preco obrigatórios; preco >= 0
{ "categoriaId": "uuid", "nome": "X-Burger", "descricao": "...",
  "preco": 24.90, "imagemUrl": "https://...", "ordem": 1 }
```
- Na criação, `disponivel` é sempre `true` (não é aceito no body); mude via `PATCH .../disponibilidade`.
- `PUT` **não** altera `disponivel` — só os campos do `ProdutoRequest`.
- `categoriaId` inexistente → `404 {"error":"Categoria não encontrada"}`.
- ⚠️ Criação retorna **200**, não 201.

### 6.3 Categorias — `/admin/categorias`

| Método | Rota | Body | Retorno |
|---|---|---|---|
| `GET` | `/admin/categorias` | — | `CategoriaResponse[]` (ordenado por `ordem`) |
| `POST` | `/admin/categorias` | `CategoriaRequest` | 200 `CategoriaResponse` |
| `PUT` | `/admin/categorias/{id}` | `CategoriaRequest` | 200 `CategoriaResponse` |
| `PATCH` | `/admin/categorias/{id}/ativo` | `{"ativo": false}` | 200 `CategoriaResponse` |
| `PUT` | `/admin/categorias/{id}/adicionais` | `VincularAdicionaisRequest` | 200 `CategoriaComAdicionaisResponse` |
| `GET` | `/admin/categorias/{id}/adicionais` | — | `AdicionalResponse[]` (ordenado por nome) |

```json
// CategoriaRequest — nome obrigatório; ativo opcional (default true na criação)
{ "nome": "Lanches", "ordem": 1, "ativo": true }
// CategoriaResponse
{ "id": "uuid", "nome": "Lanches", "ordem": 1, "ativo": true }
```
⚠️ `PUT /admin/categorias/{id}` **ignora** o campo `ativo` — só `nome` e `ordem` são
atualizados. Para ativar/desativar use `PATCH .../ativo`.

```json
// VincularAdicionaisRequest — SUBSTITUI o conjunto inteiro (não é append)
{ "adicionalIds": ["uuid", "uuid"] }
// para desvincular todos: { "adicionalIds": [] }

// CategoriaComAdicionaisResponse
{ "id": "uuid", "nome": "Lanches",
  "adicionais": [ { "id": "uuid", "nome": "Bacon", "preco": 4.00, "ativo": true } ] }
```
Qualquer id inexistente na lista → `404 {"error":"Adicional não encontrado"}` (nada é gravado).

> **Modelo dos adicionais:** o vínculo é **adicional ↔ categoria**, não adicional ↔ produto.
> Um adicional só pode ser escolhido num item se estiver vinculado à categoria daquele produto.

### 6.4 Adicionais — `/admin/adicionais`

| Método | Rota | Body | Retorno |
|---|---|---|---|
| `GET` | `/admin/adicionais` | — | `AdicionalResponse[]` (todos, inclusive inativos) |
| `POST` | `/admin/adicionais` | `{"nome":"Bacon","preco":4.00}` | 200 `AdicionalResponse` |
| `PUT` | `/admin/adicionais/{id}` | `{"nome":"Bacon","preco":5.00}` | 200 `AdicionalResponse` |
| `PATCH` | `/admin/adicionais/{id}/ativo` | `{"ativo": false}` | 200 `AdicionalResponse` |

`nome` obrigatório, `preco` obrigatório e `>= 0`. Criação sempre nasce `ativo=true`;
`PUT` não altera `ativo`.

### 6.5 Configuração da loja — `/admin/config`

A config é um **singleton** (uma única linha no banco).

#### `GET /admin/config` → `ConfigLojaResponse`
```json
{ "aberta": true, "taxaEntrega": 8.00,
  "aceitaPix": true, "aceitaCartao": true, "aceitaDinheiro": true }
```

#### `PATCH /admin/config/aberta` → `ConfigLojaResponse`
```json
{ "aberta": false }   // obrigatório
```
Fechar a loja bloqueia **novos** pedidos (409 no `POST /app/pedidos`); pedidos em andamento
seguem o fluxo normalmente.

⚠️ Não há endpoint para alterar `taxaEntrega` nem as flags `aceita*` — hoje são só leitura
via API (mudança direta no banco).

### 6.6 Relatório — `/admin/relatorio`

#### `GET /admin/relatorio/dia` → `RelatorioDiaResponse`
```json
{
  "data": "2026-07-25",
  "faturamento": 1840.50,
  "quantidadePedidos": 32,
  "ticketMedio": 57.52,
  "maisVendidos": [ { "nome": "X-Burger", "quantidade": 41 } ]
}
```
Regras: considera **apenas pedidos `CONCLUIDO`** do dia civil em `America/Sao_Paulo`;
top **10** mais vendidos; dia sem vendas retorna `0.00` / `0` (nunca `null`).

---

## 7. Webhook Mercado Pago — `/webhook` (não usar no front)

`POST /webhook/mercadopago` — consumido **pelo Mercado Pago**, não pelos apps.
Validado por assinatura HMAC (`x-signature` + `x-request-id`); sempre responde **200**
(inclusive em rejeição ou erro) para o MP não reenviar infinitamente. O status do
pagamento é sempre **reconsultado na API do MP** — o payload do webhook não é confiado —
e o valor confirmado é conferido contra o valor local antes de aprovar.

Efeito ao aprovar: pagamento → `APROVADO` e pedido `AGUARDANDO_PAGAMENTO` → `NOVO`,
disparando eventos WebSocket para admin e cliente.

---

## 8. WebSocket / STOMP — tempo real

| Item | Valor |
|---|---|
| Endpoint | `/ws` (**SockJS habilitado** — use um cliente SockJS + STOMP, ex. `@stomp/stompjs` + `sockjs-client`) |
| Autenticação | header **nativo STOMP** `Authorization: Bearer <token>` no frame **CONNECT** |
| Broker | in-memory, prefixo de tópicos `/topic` |
| Origens | `*` em dev (restringir em produção) |

Token ausente ou inválido no CONNECT **derruba a conexão**.

### Tópicos

| Tópico | Quem pode assinar |
|---|---|
| `/topic/admin/pedidos` | apenas `ROLE_ADMIN` |
| `/topic/cliente/{clienteId}` | apenas `ROLE_CLIENTE`, e **só** se `{clienteId}` == `sub` do token |

Assinar o canal de outro cliente, ou qualquer outro `/topic/**`, é rejeitado.
`{clienteId}` é o `sub` do JWT do cliente.

### Envelope do evento

```json
{ "tipo": "PEDIDO_CRIADO", "dado": { /* ... */ } }
```

| `tipo` | Quando |
|---|---|
| `PEDIDO_CRIADO` | pedido novo entra no fluxo (criação em dinheiro/cartão, ou PIX aprovado) |
| `STATUS_ATUALIZADO` | qualquer mudança de status (transição do admin, PIX aprovado, PIX expirado) |

O formato de `dado` **depende do canal**:
- `/topic/admin/pedidos` → `PedidoResumoResponse` (o resumo do kanban)
- `/topic/cliente/{id}` → `PedidoResponse` (o pedido completo)

### Quem recebe o quê

| Fato | Canal admin | Canal do cliente |
|---|---|---|
| Pedido criado (DINHEIRO/CARTAO, nasce `NOVO`) | `PEDIDO_CRIADO` | `PEDIDO_CRIADO` |
| Pedido criado (PIX, nasce `AGUARDANDO_PAGAMENTO`) | — nada | `PEDIDO_CRIADO` |
| PIX aprovado (pedido → `NOVO`) | `PEDIDO_CRIADO` | `STATUS_ATUALIZADO` |
| Transição do admin (aceitar/pronto/concluir/cancelar) | `STATUS_ATUALIZADO` | `STATUS_ATUALIZADO` |
| PIX expirado (pedido → `CANCELADO`) | — nada | `STATUS_ATUALIZADO` |

Notas para o front:
- O envio é **best-effort e pós-commit**: se o WebSocket falhar, o dado já está persistido —
  não confie apenas em eventos, mantenha o refetch/polling como fallback.
- Um pedido PIX aparece no admin com `PEDIDO_CRIADO` (não `STATUS_ATUALIZADO`) quando o
  pagamento é aprovado — trate esse tipo como "inserir na coluna NOVO".
- Cancelamento por PIX expirado **não** notifica o admin (o pedido nunca esteve no kanban).

---

## 9. Formato dos erros

Todo erro tratado devolve JSON. Há **dois** formatos:

```json
// 1) Genérico
{ "error": "mensagem legível" }

// 2) Validação de body (400)
{ "error": "Dados inválidos",
  "campos": { "nome": "must not be blank", "itens": "must not be empty" } }

// 3) Exceção — cliente não cadastrado no login (404)
{ "code": "NAO_CADASTRADO" }
```

### Tabela de status

| Status | Situação |
|---|---|
| `400` | body inválido (`campos`), CPF inválido, endereço inválido/faltando, adicional inválido, forma de pagamento não aceita, `status` ausente em `GET /admin/pedidos` |
| `401` | token ausente/inválido/expirado; credenciais erradas no login |
| `403` | token válido mas sem a role exigida (ex.: cliente chamando `/admin/**`) — corpo padrão do Spring, **não** o JSON acima |
| `404` | recurso não encontrado ou não pertencente ao cliente autenticado; `{"code":"NAO_CADASTRADO"}` no login |
| `409` | conflito de estado: loja fechada, produto indisponível, CPF já cadastrado, transição inválida, pagamento em estado inválido, edição concorrente |
| `502` | falha na integração com o Mercado Pago (`{"error":"Falha ao gerar pagamento"}`) |

---

## 10. Resumo — todos os endpoints

```
PÚBLICO
POST   /auth/admin/login
POST   /auth/cliente/login
POST   /auth/cliente/register
GET    /public/cardapio
GET    /public/produtos/{id}
GET    /public/produtos/{id}/adicionais
GET    /public/adicionais
GET    /public/loja/status
POST   /webhook/mercadopago                        (só Mercado Pago)
GET    /actuator/health

CLIENTE (Bearer, ROLE_CLIENTE)
POST   /app/enderecos                              201
GET    /app/enderecos
PUT    /app/enderecos/{id}
DELETE /app/enderecos/{id}                         204
POST   /app/pedidos                                201
GET    /app/pedidos
GET    /app/pedidos/{id}
POST   /app/pedidos/{id}/pagamento

ADMIN (Bearer, ROLE_ADMIN)
GET    /admin/pedidos?status={StatusPedido}        status obrigatório
GET    /admin/pedidos/{id}
PATCH  /admin/pedidos/{id}/aceitar
PATCH  /admin/pedidos/{id}/pronto
PATCH  /admin/pedidos/{id}/concluir
PATCH  /admin/pedidos/{id}/cancelar
GET    /admin/produtos
POST   /admin/produtos
PUT    /admin/produtos/{id}
PATCH  /admin/produtos/{id}/disponibilidade
GET    /admin/categorias
POST   /admin/categorias
PUT    /admin/categorias/{id}
PATCH  /admin/categorias/{id}/ativo
PUT    /admin/categorias/{id}/adicionais
GET    /admin/categorias/{id}/adicionais
GET    /admin/adicionais
POST   /admin/adicionais
PUT    /admin/adicionais/{id}
PATCH  /admin/adicionais/{id}/ativo
GET    /admin/config
PATCH  /admin/config/aberta
GET    /admin/relatorio/dia

WEBSOCKET
/ws  (SockJS + STOMP, Authorization no CONNECT)
  SUBSCRIBE /topic/admin/pedidos           ROLE_ADMIN
  SUBSCRIBE /topic/cliente/{clienteId}     ROLE_CLIENTE, só o próprio id
```

---

## 11. Armadilhas conhecidas (leia antes de implementar)

1. `GET /admin/pedidos` **exige** `?status=` — sem ele é 400. Não existe "listar todos".
2. Não existe `DELETE` para produto, categoria ou adicional — a desativação é via
   `PATCH .../ativo` (ou `.../disponibilidade` em produto).
3. `PUT` de produto/categoria/adicional **não** mexe nas flags `ativo`/`disponivel`.
4. `PUT /admin/categorias/{id}/adicionais` **substitui** a lista inteira.
5. `POST` de admin retorna **200**; `POST` de pedido e endereço retornam **201**;
   `DELETE` de endereço retorna **204**.
6. `precoUnitario` no item do pedido não inclui adicionais — o total do item está em `subtotal`.
7. `endereco` vem `null` em pedidos `RETIRADA`.
8. O front nunca envia preço nem total: tudo é calculado no servidor.
9. Não há refresh token; token expirado → `401`, refaça o login.
10. Não há endpoint de perfil do cliente nem de listagem/CRUD de admins.
11. `adicionalIds` só aceita adicionais vinculados à **categoria** do produto do item.
12. Pedido PIX só aparece no kanban do admin depois do pagamento aprovado.
