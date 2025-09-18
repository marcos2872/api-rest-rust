# API REST em Rust

API REST desenvolvida em Rust usando Actix-web e SQLx com PostgreSQL para gerenciamento completo de usuários com autenticação JWT.

## 🚀 Funcionalidades

- ✅ CRUD completo de usuários
- ✅ Sistema de autenticação JWT
- ✅ Roles de usuário (USER/ADMIN)
- ✅ Usuário administrador padrão
- ✅ Paginação e busca de usuários
- ✅ Criptografia de senhas com bcrypt
- ✅ Validação de dados e email único
- ✅ Rate limiting por IP
- ✅ Migrações automáticas de banco de dados
- ✅ Testes automatizados completos

## 📋 Pré-requisitos

- Rust 1.70+ instalado
- PostgreSQL 12+ rodando
- Cargo (vem com o Rust)

## ⚙️ Configuração

### Método 1: Setup Automático (Recomendado)
```bash
# Clone o projeto
git clone <url-do-repositório>
cd api-rest-rust

# Configure as variáveis de ambiente
cp .env.example .env

# Setup completo (instala dependências, inicia PostgreSQL e executa migrações)
make setup
```

### Método 2: Setup Manual
1. **Clone o projeto:**
```bash
git clone <url-do-repositório>
cd api-rest-rust
```

2. **Configure as variáveis de ambiente:**
```bash
cp .env.example .env
```

3. **Inicie o PostgreSQL com Docker:**
```bash
make docker-up
```

4. **Instale dependências e execute migrações:**
```bash
make install
make migrate
```

## 🏃‍♂️ Como executar

### Usando Makefile (Recomendado)
```bash
# Iniciar servidor
make run

# Ou para desenvolvimento com reload automático
make watch
```

### Usando Cargo diretamente
```bash
cargo run
```

O servidor estará disponível em `http://127.0.0.1:8080`

### Comandos úteis
```bash
make help          # Ver todos os comandos disponíveis
make check          # Verificar código
make test           # Executar testes
make api-test       # Testar endpoints da API
make docker-up      # Iniciar PostgreSQL
make docker-down    # Parar PostgreSQL
```

## 📡 Endpoints da API

### 🔑 Autenticação

#### Login
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "usuario@email.com",
  "senha": "senha123"
}
```
**Resposta de sucesso (200):**
```json
{
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "nome": "João Silva",
    "email": "joao@email.com",
    "role": "USER",
    "created_at": "2023-12-01T10:30:00Z",
    "updated_at": "2023-12-01T10:30:00Z"
  },
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "expires_at": "2023-12-01T11:30:00Z"
}
```

#### Verificar Token
```http
GET /api/v1/auth/verify/{token}
```

#### Refresh Token
```http
POST /api/v1/auth/refresh/{token}
```

### 🔐 Rotas Protegidas

As seguintes rotas requerem autenticação Bearer Token:

**🔑 Autenticação JWT Obrigatória:**
- `GET /api/v1/users/{id}` - Buscar usuário por ID
- `PUT /api/v1/users/{id}` - Atualizar usuário
- `PATCH /api/v1/users/{id}/change-password` - Alterar senha
- `GET /api/v1/users/me` - Dados do usuário logado

**👑 Apenas Administradores:**
- `GET /api/v1/users` - Listar usuários
- `DELETE /api/v1/users/{id}` - Deletar usuário

**📋 Rotas Públicas (sem autenticação):**
- `POST /api/v1/auth/login` - Login
- `POST /api/v1/users` - Criar usuário
- `GET /health` - Health check

### 🚦 Rate Limiting

Todos os endpoints têm rate limiting aplicado por IP:
- **Limite padrão**: 60 requisições por minuto
- **Burst**: 10 requisições em rajada
- **Headers de resposta**: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `Retry-After`
- **Resposta quando limite excedido**: HTTP 429 Too Many Requests

```json
{
  "error": "Rate limit exceeded",
  "message": "Too many requests. Limit: 60 requests per minute",
  "retry_after_seconds": 30
}
```

### 🔍 Health Check
```http
GET /health
```
**Resposta:**
```json
{
  "status": "ok",
  "message": "API está funcionando"
}
```

### 👥 CRUD de Usuários

#### 1. Criar Usuário
```http
POST /api/v1/users
POST /api/v1/users/register  (alias)
Content-Type: application/json

{
  "nome": "João Silva",
  "email": "joao@exemplo.com",
  "senha": "minhasenha123",
  "role": "USER"
}
```
**Resposta de sucesso (201):**
```json
{
  "message": "Usuário criado com sucesso",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "nome": "João Silva",
    "email": "joao@exemplo.com",
    "role": "USER",
    "created_at": "2023-12-01T10:30:00Z",
    "updated_at": "2023-12-01T10:30:00Z"
  }
}
```

#### 2. Listar Usuários (com paginação e busca)
```http
GET /api/v1/users
GET /api/v1/users?page=1&per_page=10
GET /api/v1/users?search=João
GET /api/v1/users?page=2&per_page=5&search=Silva
```
**Parâmetros de Query:**
- `page` - Número da página (padrão: 1)
- `per_page` - Usuários por página (padrão: 10, máximo: 100)
- `search` - Busca por nome ou email

**Resposta (200):**
```json
{
  "users": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "nome": "João Silva",
      "email": "joao@exemplo.com",
      "role": "USER",
      "created_at": "2023-12-01T10:30:00Z",
      "updated_at": "2023-12-01T10:30:00Z"
    }
  ],
  "total": 1,
  "page": 1,
  "per_page": 10,
  "total_pages": 1
}
```

#### 3. Buscar Usuário por ID
```http
GET /api/v1/users/{id}
```
**Resposta de sucesso (200):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "nome": "João Silva",
  "email": "joao@exemplo.com",
  "role": "USER",
  "created_at": "2023-12-01T10:30:00Z",
  "updated_at": "2023-12-01T10:30:00Z"
}
```

#### 4. Atualizar Usuário
```http
PUT /api/v1/users/{id}
Content-Type: application/json

{
  "nome": "João Silva Santos",
  "email": "joao.santos@exemplo.com",
  "senha": "novasenha123",  // opcional
  "role": "ADMIN"          // opcional
}
```
**Resposta de sucesso (200):**
```json
{
  "message": "Usuário atualizado com sucesso",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "nome": "João Silva Santos",
    "email": "joao.santos@exemplo.com",
    "role": "ADMIN",
    "created_at": "2023-12-01T10:30:00Z",
    "updated_at": "2023-12-01T10:35:00Z"
  }
}
```

#### 5. Alterar Senha
```http
PATCH /api/v1/users/{id}/change-password
Content-Type: application/json

{
  "senha_atual": "senhaatual123",
  "senha_nova": "novasenha456"
}
```
**Resposta de sucesso (200):**
```json
{
  "message": "Senha alterada com sucesso"
}
```

#### 6. Deletar Usuário
```http
DELETE /api/v1/users/{id}
```
**Resposta de sucesso (200):**
```json
{
  "message": "Usuário deletado com sucesso"
}
```

### ❌ Respostas de Erro Comuns

**400 Bad Request:**
```json
{
  "error": "Email já está em uso"
}
```

**404 Not Found:**
```json
{
  "error": "Usuário não encontrado"
}
```

**422 Unprocessable Entity:**
```json
{
  "error": "Dados inválidos"
}
```

**500 Internal Server Error:**
```json
{
  "error": "Erro interno do servidor"
}
```

## 🧪 Testando a API

### Usando script de teste (Recomendado)
```bash
# Certifique-se de que o servidor está rodando
make run

# Em outro terminal, execute os testes completos
make api-test

# Se houver problemas, execute diagnóstico
make api-diagnose

# Testar rate limiting
make rate-limit-test
```

### Testando autenticação

#### Login
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@sistema.com",
    "senha": "admin123"
  }'
```

#### Verificar token
```bash
curl http://localhost:8080/api/v1/auth/verify/YOUR_JWT_TOKEN_HERE
```

#### Usar token em rotas protegidas
```bash
# Obter dados do usuário logado
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:8080/api/v1/users/me

# Buscar usuário por ID (requer autenticação)
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:8080/api/v1/users/USER_ID
```

#### Diagnóstico automático
```bash
# Executar diagnóstico da API
make api-diagnose
# ou
./test_api.sh --diagnose
```

### Testando operações CRUD com curl

#### Criar usuário
```bash
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "João Silva",
    "email": "joao@exemplo.com",
    "senha": "minhasenha123",
    "role": "USER"
  }'
```

#### Listar usuários (requer JWT de Admin)
```bash
# Listar todos (precisa ser admin)
curl -H "Authorization: Bearer YOUR_ADMIN_JWT_TOKEN" \
  http://localhost:8080/api/v1/users

# Com paginação (precisa ser admin)
curl -H "Authorization: Bearer YOUR_ADMIN_JWT_TOKEN" \
  "http://localhost:8080/api/v1/users?page=1&per_page=5"

# Com busca (precisa ser admin)
curl -H "Authorization: Bearer YOUR_ADMIN_JWT_TOKEN" \
  "http://localhost:8080/api/v1/users?search=João"
```

#### Buscar usuário por ID (requer JWT)
```bash
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:8080/api/v1/users/550e8400-e29b-41d4-a716-446655440000
```

#### Atualizar usuário (requer JWT)
```bash
curl -X PUT http://localhost:8080/api/v1/users/550e8400-e29b-41d4-a716-446655440000 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "nome": "João Silva Santos",
    "email": "joao.santos@exemplo.com",
    "role": "ADMIN"
  }'
```

#### Alterar senha (requer JWT)
```bash
curl -X PATCH http://localhost:8080/api/v1/users/550e8400-e29b-41d4-a716-446655440000/change-password \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "senha_atual": "minhasenha123",
    "senha_nova": "novasenha456"
  }'
```

#### Deletar usuário (requer JWT de Admin)
```bash
curl -X DELETE http://localhost:8080/api/v1/users/550e8400-e29b-41d4-a716-446655440000 \
  -H "Authorization: Bearer YOUR_ADMIN_JWT_TOKEN"
```

### Usando PgAdmin
Acesse `http://localhost:8081` para gerenciar o banco:
- **Email:** admin@example.com
- **Senha:** admin123

### 🔑 Usuário Administrador Padrão
- **Email:** admin@sistema.com
- **Senha:** admin123 (ALTERE IMEDIATAMENTE!)
- **Role:** ADMIN

## 🏗️ Estrutura do Projeto

```
api-rest-rust/
├── src/
│   ├── config/
│   │   ├── mod.rs
│   │   └── database.rs      # Configuração do banco de dados
│   ├── handlers/
│   │   ├── mod.rs
│   │   └── user_handler.rs  # Handlers dos usuários
│   ├── models/
│   │   ├── mod.rs
│   │   └── user.rs          # Modelos de dados
│   └── main.rs              # Arquivo principal
├── migrations/              # Migrações do banco
│   ├── 20231201000001_create_users_table.up.sql
│   └── 20231201000001_create_users_table.down.sql
├── docker-compose.yml       # Configuração PostgreSQL + PgAdmin
├── init.sql                 # Inicialização do banco
├── test_api.sh             # Script de testes da API
├── Makefile                # Comandos de desenvolvimento
├── .env.example            # Exemplo de configuração
├── Cargo.toml              # Dependências do projeto
└── README.md
```

## 📦 Dependências Principais

- **actix-web**: Framework web para Rust
- **sqlx**: Driver assíncrono para PostgreSQL
- **tokio**: Runtime assíncrono
- **serde**: Serialização/deserialização JSON
- **bcrypt**: Criptografia de senhas
- **uuid**: Geração de UUIDs
- **chrono**: Manipulação de datas
- **dotenv**: Carregamento de variáveis de ambiente

## 🔐 Segurança

- Senhas são criptografadas usando bcrypt com custo padrão
- Validação de email único no banco de dados
- Uso de UUIDs como identificadores únicos
- Prepared statements para prevenir SQL injection

## 🐛 Logs

Os logs são configurados automaticamente. Para ver logs detalhados, execute:

```bash
RUST_LOG=debug cargo run
```

## 🚀 Comandos Make Disponíveis

| Comando | Descrição |
|---------|-----------|
| `make help` | Mostra todos os comandos disponíveis |
| `make setup` | Setup completo do projeto |
| `make install` | Instala dependências |
| `make build` | Compila o projeto |
| `make run` | Executa o servidor |
| `make watch` | Executa com reload automático |
| `make check` | Verifica código |
| `make test` | Executa testes |
| `make api-test` | Testa endpoints da API |
| `make format` | Formata código |
| `make lint` | Executa linter |
| `make docker-up` | Inicia PostgreSQL |
| `make docker-down` | Para PostgreSQL |
| `make migrate` | Executa migrações |
| `make clean` | Limpa arquivos de build |
| `make api-diagnose` | Diagnóstico automático da API |
| `make rate-limit-test` | Testa funcionalidade de rate limiting |

## ✅ Funcionalidades Implementadas

- ✅ **Autenticação JWT completa**
  - Login com email/senha
  - Token JWT com expiração
  - Verificação e refresh de tokens
  - **Autenticação Bearer Token em rotas protegidas**
- ✅ **Sistema de Roles**
  - USER (usuário comum)
  - ADMIN (administrador)
  - Usuário admin padrão criado automaticamente
  - **Middleware de autorização por role**
- ✅ **CRUD completo de usuários**
  - Criar, listar, buscar, atualizar, deletar
  - Paginação e busca por nome/email
  - Validação de dados e email único
  - **Rotas protegidas por autenticação JWT**
- ✅ **Segurança robusta**
  - Senhas criptografadas com bcrypt
  - JWT com claims personalizadas
  - Validações de entrada
  - **Controle de acesso por usuário/admin**
  - **Rate limiting por IP com token bucket**
- ✅ **Infraestrutura completa**
  - PostgreSQL com migrações automáticas
  - Docker Compose para desenvolvimento
  - Testes automatizados (24+ cenários)
  - Rate limiting testing suite
  - Logs estruturados

## 🔒 Sistema de Autenticação

### Como Funciona

1. **Login:** Usuário faz login com email/senha
2. **Token JWT:** API retorna token JWT válido
3. **Autenticação:** Cliente envia token no header `Authorization: Bearer {token}`
4. **Validação:** Middleware valida token em cada requisição
5. **Autorização:** Sistema verifica permissões baseadas no role do usuário
6. **Rate Limiting:** Sistema controla número de requisições por IP

### Rate Limiting

- **Algoritmo:** Token Bucket per IP
- **Configuração:** Via variáveis de ambiente
- **Headers:** `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `Retry-After`
- **Proxy Support:** Suporte a `X-Forwarded-For` e `X-Real-IP`
- **Testes:** `make rate-limit-test`

### Controle de Acesso

- **Usuários comuns:** Podem ver/editar apenas seus próprios dados
- **Administradores:** Acesso total a todos os usuários
- **Rotas públicas:** Não requerem autenticação
- **Rotas protegidas:** Requerem JWT válido

## 📝 Próximos Passos

- [x] ~~Middleware de autorização por role~~
- [x] ~~Endpoints protegidos por JWT~~
- [ ] Implementar soft delete
- [ ] Adicionar validação de email
- [ ] Implementar upload de avatar
- [ ] Adicionar auditoria de mudanças
- [ ] Adicionar documentação Swagger/OpenAPI
- [ ] Implementar rate limiting
- [ ] Adicionar testes unitários e de integração
- [ ] Implementar cache com Redis
- [ ] Adicionar métricas e monitoramento
- [ ] Blacklist de tokens (logout real)
- [ ] Two-factor authentication (2FA)

## 🔧 Troubleshooting

### Problemas Comuns

**API não responde:**
```bash
make api-diagnose  # Diagnóstico automático
```

**Testes falham:**
```bash
# Verificar se server está rodando
curl http://localhost:8080/health

# Executar diagnóstico
./test_api.sh --diagnose
```

**Rate limiting não funciona:**
```bash
# Testar rate limiting
make rate-limit-test

# Configurar limites mais baixos (no .env)
RATE_LIMIT_RPM=10
RATE_LIMIT_BURST=3
```

**Token extraction fails:**
- Instale `python3` ou `jq` para melhor parsing JSON
- Se HTTP responses são 200/201, a API está funcionando

### Documentação Adicional

- **`AUTH.md`** - Documentação completa de autenticação
- **`ROUTES.md`** - Especificação de todas as rotas
- **`API_EXAMPLES.md`** - Exemplos práticos de uso
- **`EXPECTED_RESPONSES.md`** - Respostas esperadas para troubleshooting
- **`test_rate_limit.sh`** - Testes específicos de rate limiting

## 🤝 Contribuindo

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.