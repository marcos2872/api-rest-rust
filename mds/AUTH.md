# 🔐 Sistema de Autenticação JWT

Documentação completa do sistema de autenticação da API REST em Rust.

## 📋 Visão Geral

A API utiliza JWT (JSON Web Tokens) para autenticação e autorização de usuários. O sistema inclui:

- ✅ Autenticação via email/senha
- ✅ Tokens JWT com expiração configurável
- ✅ Sistema de roles (USER/ADMIN)
- ✅ Usuário administrador padrão
- ✅ Refresh e verificação de tokens

## 🏗️ Arquitetura

### Fluxo de Autenticação

```
1. Cliente faz login com email/senha
2. API valida credenciais no banco
3. API gera JWT token com claims do usuário
4. Cliente recebe token e dados do usuário
5. Cliente envia token no header Authorization
6. API valida token em cada requisição
```

### Estrutura do Token JWT

```json
{
  "sub": "uuid-do-usuario",
  "email": "usuario@email.com", 
  "nome": "Nome do Usuário",
  "role": "USER",
  "iat": 1701432000,
  "exp": 1701435600
}
```

## 👥 Sistema de Roles

### Tipos de Usuário

| Role | Descrição | Permissões |
|------|-----------|------------|
| `USER` | Usuário comum | Acesso básico à aplicação |
| `ADMIN` | Administrador | Acesso total ao sistema |

### Role Enum

```rust
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, sqlx::Type)]
#[sqlx(type_name = "user_role")]
#[sqlx(rename_all = "UPPERCASE")]
pub enum UserRole {
    User,   // "USER"
    Admin,  // "ADMIN"
}
```

## 🔑 Endpoints de Autenticação

### 1. Login
**POST** `/api/v1/auth/login`

Autentica um usuário e retorna JWT token.

**Request:**
```json
{
  "email": "usuario@email.com",
  "senha": "senha123"
}
```

**Response (200 OK):**
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

**Response (401 Unauthorized):**
```json
{
  "error": "Credenciais inválidas"
}
```

### 2. Verificar Token
**GET** `/api/v1/auth/verify/{token}`

Verifica se um token JWT é válido.

**Response (200 OK):**
```json
{
  "valid": true,
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "joao@email.com",
  "nome": "João Silva",
  "role": "USER",
  "expires_at": 1701435600
}
```

**Response (401 Unauthorized):**
```json
{
  "error": "Token inválido"
}
```

### 3. Refresh Token
**POST** `/api/v1/auth/refresh/{token}`

Gera um novo token com base em um token válido existente.

**Response (200 OK):**
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "expires_at": "2023-12-01T12:30:00Z"
}
```

## 👑 Usuário Administrador Padrão

### Credenciais Padrão
- **Email:** `admin@sistema.com`
- **Senha:** `admin123`
- **Role:** `ADMIN`
- **ID:** `00000000-0000-0000-0000-000000000001`

### ⚠️ Segurança
**IMPORTANTE:** Altere a senha padrão imediatamente após o primeiro login!

### Como Alterar a Senha do Admin

```bash
# 1. Login como admin
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@sistema.com",
    "senha": "admin123"
  }'

# 2. Extrair o ID do usuário da resposta
# 3. Alterar a senha
curl -X PATCH http://localhost:8080/api/v1/users/00000000-0000-0000-0000-000000000001/change-password \
  -H "Content-Type: application/json" \
  -d '{
    "senha_atual": "admin123",
    "senha_nova": "nova_senha_super_segura"
  }'
```

## ⚙️ Configuração JWT

### Variáveis de Ambiente

```env
# Chave secreta para assinar tokens (MUDE EM PRODUÇÃO!)
JWT_SECRET=sua-chave-secreta-jwt-mude-em-producao-deve-ser-longa-e-segura

# Tempo de expiração em segundos (3600 = 1 hora)
JWT_EXPIRATION=3600
```

### Configuração no Código

```rust
// Configurar JWT no main.rs
let jwt_secret = env::var("JWT_SECRET")
    .unwrap_or_else(|_| "your-secret-key-change-this-in-production".to_string());
let jwt_expiration = env::var("JWT_EXPIRATION")
    .unwrap_or_else(|_| "3600".to_string())
    .parse::<i64>()
    .expect("JWT_EXPIRATION deve ser um número válido");

let jwt_config = JwtConfig::new(jwt_secret, jwt_expiration);
```

## 🧪 Testando Autenticação

### 1. Login Básico
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@sistema.com",
    "senha": "admin123"
  }'
```

### 2. Login de Usuário Comum
```bash
# Primeiro, criar um usuário
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "João Silva",
    "email": "joao@email.com",
    "senha": "senha123"
  }'

# Depois, fazer login
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "joao@email.com",
    "senha": "senha123"
  }'
```

### 3. Verificar Token
```bash
# Substitua TOKEN pelo token recebido no login
curl http://localhost:8080/api/v1/auth/verify/TOKEN
```

### 4. Refresh Token
```bash
curl -X POST http://localhost:8080/api/v1/auth/refresh/TOKEN
```

## 🔒 Usando Tokens em Requisições

### Header Authorization
```http
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

### Exemplo com curl
```bash
# Usar token em uma requisição protegida (quando implementado)
curl -H "Authorization: Bearer TOKEN" \
  http://localhost:8080/api/v1/protected-endpoint
```

## 📊 Códigos de Erro

### Autenticação
| Código | Erro | Descrição |
|--------|------|-----------|
| 401 | Unauthorized | Credenciais inválidas ou token expirado |
| 400 | Bad Request | Dados de login malformados |
| 500 | Internal Error | Erro interno do servidor |

### Mensagens de Erro Comuns

```json
// Login inválido
{
  "error": "Credenciais inválidas"
}

// Token expirado
{
  "error": "Token expirado"
}

// Token inválido
{
  "error": "Token inválido"
}
```

## 🛡️ Segurança

### Melhores Práticas Implementadas

1. **Senhas Criptografadas:** bcrypt com cost 12
2. **Tokens JWT:** Assinados com chave secreta
3. **Expiração:** Tokens com tempo limitado
4. **Validação:** Verificação de entrada rigorosa
5. **Roles:** Sistema de permissões por tipo de usuário

### Recomendações para Produção

1. **Chave JWT Forte:** Use uma chave longa e aleatória
2. **HTTPS:** Sempre use conexões seguras
3. **Tempo de Expiração:** Configure adequadamente (1-24h)
4. **Rate Limiting:** Implemente controle de taxa
5. **Logs de Segurança:** Monitore tentativas de login

## 🔧 Implementação Futura

### Middleware de Autorização
```rust
// Próximos passos: middleware para proteger rotas
pub async fn jwt_middleware(
    req: ServiceRequest,
    credentials: BearerAuth,
) -> Result<ServiceRequest, Error> {
    // Validar token JWT
    // Extrair claims do usuário
    // Verificar permissões por role
}
```

### Rotas Protegidas
```rust
// Exemplo de rota que requer autenticação
.route("/protected", web::get().to(protected_endpoint))
  .wrap(HttpAuthentication::bearer(jwt_middleware))
```

### Permissões por Role
```rust
// Verificar se usuário é admin
if !claims.is_admin() {
    return Err(AuthError::Forbidden);
}
```

## 📝 Notas Importantes

1. **Token Storage:** Cliente deve armazenar token de forma segura
2. **Refresh Strategy:** Implementar refresh automático antes da expiração
3. **Logout:** Tokens são stateless, logout é do lado do cliente
4. **Multiple Devices:** Um usuário pode ter múltiplos tokens válidos
5. **Security Headers:** Implementar CORS e outros headers de segurança

## 🚀 Próximos Passos

- [ ] Middleware de autorização automática
- [ ] Rotas protegidas por role
- [ ] Blacklist de tokens (logout real)
- [ ] Two-factor authentication (2FA)
- [ ] OAuth2 integration
- [ ] Session management
- [ ] Audit logs de autenticação