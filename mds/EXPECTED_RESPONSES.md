# 📋 Respostas Esperadas da API

Este documento contém exemplos das respostas esperadas de cada endpoint da API para ajudar no troubleshooting e validação.

## 🔍 Health Check

### GET /health

**Request:**
```bash
curl http://localhost:8080/health
```

**Response (200 OK):**
```json
{
  "status": "ok",
  "message": "API está funcionando"
}
```

---

## 🔑 Autenticação

### POST /api/v1/auth/login

**Request:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sistema.com","senha":"admin123"}'
```

**Response (200 OK):**
```json
{
  "user": {
    "id": "00000000-0000-0000-0000-000000000001",
    "nome": "Administrador",
    "email": "admin@sistema.com",
    "role": "ADMIN",
    "created_at": "2023-12-01T10:00:00Z",
    "updated_at": "2023-12-01T10:00:00Z"
  },
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDEiLCJlbWFpbCI6ImFkbWluQHNpc3RlbWEuY29tIiwibm9tZSI6IkFkbWluaXN0cmFkb3IiLCJyb2xlIjoiQURNSU4iLCJpYXQiOjE3MDE0MzIwMDAsImV4cCI6MTcwMTQzNTYwMH0.example_signature",
  "expires_at": "2023-12-01T11:00:00Z"
}
```

**Response (401 Unauthorized) - Credenciais inválidas:**
```json
{
  "error": "Credenciais inválidas"
}
```

### GET /api/v1/auth/verify/{token}

**Response (200 OK):**
```json
{
  "valid": true,
  "user_id": "00000000-0000-0000-0000-000000000001",
  "email": "admin@sistema.com",
  "nome": "Administrador",
  "role": "ADMIN",
  "expires_at": 1701435600
}
```

**Response (401 Unauthorized) - Token inválido:**
```json
{
  "error": "Token inválido"
}
```

---

## 👥 Usuários

### POST /api/v1/users

**Request:**
```bash
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"nome":"João Silva","email":"joao@email.com","senha":"senha123","role":"USER"}'
```

**Response (201 Created):**
```json
{
  "message": "Usuário criado com sucesso",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "nome": "João Silva",
    "email": "joao@email.com",
    "role": "USER",
    "created_at": "2023-12-01T10:30:00Z",
    "updated_at": "2023-12-01T10:30:00Z"
  }
}
```

**Response (400 Bad Request) - Email duplicado:**
```json
{
  "error": "Email já está em uso"
}
```

### GET /api/v1/users

**Response (200 OK):**
```json
{
  "users": [
    {
      "id": "00000000-0000-0000-0000-000000000001",
      "nome": "Administrador",
      "email": "admin@sistema.com",
      "role": "ADMIN",
      "created_at": "2023-12-01T10:00:00Z",
      "updated_at": "2023-12-01T10:00:00Z"
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "nome": "João Silva",
      "email": "joao@email.com",
      "role": "USER",
      "created_at": "2023-12-01T10:30:00Z",
      "updated_at": "2023-12-01T10:30:00Z"
    }
  ],
  "total": 2,
  "page": 1,
  "per_page": 10,
  "total_pages": 1
}
```

### GET /api/v1/users/me 🔑

**Request:**
```bash
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:8080/api/v1/users/me
```

**Response (200 OK):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "nome": "João Silva",
  "email": "joao@email.com",
  "role": "USER",
  "created_at": "2023-12-01T10:30:00Z",
  "updated_at": "2023-12-01T10:30:00Z"
}
```

**Response (401 Unauthorized) - Token ausente:**
```json
{
  "error": "Token JWT não encontrado"
}
```

### GET /api/v1/users/{id} 🔑

**Response (200 OK):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "nome": "João Silva",
  "email": "joao@email.com",
  "role": "USER",
  "created_at": "2023-12-01T10:30:00Z",
  "updated_at": "2023-12-01T10:30:00Z"
}
```

**Response (403 Forbidden) - Tentativa de ver dados de outro usuário:**
```json
{
  "error": "Acesso negado. Você só pode ver seus próprios dados."
}
```

**Response (404 Not Found):**
```json
{
  "error": "Usuário não encontrado"
}
```

### PUT /api/v1/users/{id} 🔑

**Request:**
```bash
curl -X PUT http://localhost:8080/api/v1/users/550e8400-e29b-41d4-a716-446655440000 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nome":"João Silva Santos","email":"joao.santos@email.com"}'
```

**Response (200 OK):**
```json
{
  "message": "Usuário atualizado com sucesso",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "nome": "João Silva Santos",
    "email": "joao.santos@email.com",
    "role": "USER",
    "created_at": "2023-12-01T10:30:00Z",
    "updated_at": "2023-12-01T11:00:00Z"
  }
}
```

**Response (403 Forbidden) - Usuário comum tentando alterar role:**
```json
{
  "error": "Apenas administradores podem alterar roles de usuário."
}
```

### PATCH /api/v1/users/{id}/change-password 🔑

**Request:**
```bash
curl -X PATCH http://localhost:8080/api/v1/users/550e8400-e29b-41d4-a716-446655440000/change-password \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"senha_atual":"senha123","senha_nova":"novasenha456"}'
```

**Response (200 OK):**
```json
{
  "message": "Senha alterada com sucesso"
}
```

**Response (400 Bad Request) - Senha atual incorreta:**
```json
{
  "error": "Senha atual incorreta"
}
```

### DELETE /api/v1/users/{id} 👑

**Request (Admin apenas):**
```bash
curl -X DELETE http://localhost:8080/api/v1/users/550e8400-e29b-41d4-a716-446655440000 \
  -H "Authorization: Bearer YOUR_ADMIN_JWT_TOKEN"
```

**Response (200 OK):**
```json
{
  "message": "Usuário deletado com sucesso"
}
```

**Response (403 Forbidden) - Usuário comum tentando deletar:**
```json
{
  "error": "Acesso negado. Apenas administradores podem deletar usuários."
}
```

---

## 🚨 Respostas de Erro Comuns

### Erro 401 - Token JWT Inválido ou Expirado

**Diferentes formatos de erro 401:**

```json
{
  "error": "Token inválido"
}
```

```json
{
  "error": "Token expirado"
}
```

```json
{
  "error": "Credenciais inválidas"
}
```

### Erro 403 - Permissão Negada

```json
{
  "error": "Acesso negado. Você só pode ver seus próprios dados."
}
```

```json
{
  "error": "Acesso negado. Apenas administradores podem deletar usuários."
}
```

### Erro 422 - JSON Malformado

**Request com JSON inválido:**
```bash
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"nome": "Test", "email": "invalid"'  # JSON incompleto
```

**Response (400 Bad Request):**
```json
{
  "error": "Invalid JSON format"
}
```

### Erro 500 - Erro Interno

```json
{
  "error": "Erro interno do servidor"
}
```

---

## 🔧 Troubleshooting com Respostas

### ✅ Se você recebe estas respostas, tudo está funcionando:

- **Health check retorna** `{"status":"ok","message":"API está funcionando"}`
- **Login admin retorna** token JWT válido com role "ADMIN"
- **Registro de usuário retorna** HTTP 201 com dados do usuário
- **Rotas protegidas retornam** 401 sem token e 200 com token válido

### ❌ Problemas Comuns e Suas Respostas:

**1. Servidor não está rodando:**
```bash
curl: (7) Failed to connect to localhost port 8080: Connection refused
```
**Solução:** `make run`

**2. Admin não foi criado:**
```json
{
  "error": "Credenciais inválidas"
}
```
**Solução:** `make migrate`

**3. Token não está sendo enviado:**
```json
{
  "error": "Token JWT não encontrado"
}
```
**Solução:** Adicionar header `Authorization: Bearer TOKEN`

**4. Token malformado:**
```
HTTP 401 com mensagem sobre token inválido
```
**Solução:** Verificar formato do token e header Authorization

### 📊 Validando Estrutura de Resposta:

**Todos os endpoints devem retornar:**
- Content-Type: application/json
- HTTP status codes apropriados
- Estrutura JSON consistente
- Campos obrigatórios presentes

**Login deve retornar:**
- Campo `user` com dados do usuário (sem senha)
- Campo `token` com JWT válido
- Campo `expires_at` com timestamp de expiração

**Listagem deve retornar:**
- Array `users` com usuários
- Metadados de paginação (`total`, `page`, `per_page`, `total_pages`)
- Campos de usuário sem senhas

### 🎯 Como Usar Este Documento:

1. **Compare** as respostas da sua API com os exemplos aqui
2. **Identifique** discrepâncias na estrutura ou conteúdo
3. **Verifique** códigos HTTP de status
4. **Confirme** que campos obrigatórios estão presentes
5. **Valide** que dados sensíveis (senhas) não estão expostos

---

**💡 Dica:** Use `jq` para formatar JSON responses:
```bash
curl http://localhost:8080/api/v1/users | jq .
```
