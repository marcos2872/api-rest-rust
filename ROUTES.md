# 🛣️ Rotas da API REST

Documentação completa das rotas disponíveis na API REST de usuários.

## 📍 Base URL
```
http://localhost:8080
```

## 🔐 Autenticação Bearer Token

Para rotas protegidas, inclua o token JWT no header Authorization:

```
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
```

## 🔍 Health Check

### GET /health
Verifica se a API está funcionando.

**Resposta:**
- **200 OK:** API funcionando

---

## 🔑 Autenticação

### POST /api/v1/auth/login
Fazer login e obter token JWT.

**Body:**
```json
{
  "email": "string (obrigatório)",
  "senha": "string (obrigatório)"
}
```

**Respostas:**
- **200 OK:** Login realizado com sucesso, retorna user + token
- **401 Unauthorized:** Credenciais inválidas

---

### GET /api/v1/auth/verify/{token}
Verificar se um token JWT é válido.

**Path Parameters:**
- `token`: Token JWT para verificação

**Respostas:**
- **200 OK:** Token válido com informações do usuário
- **401 Unauthorized:** Token inválido ou expirado

---

### POST /api/v1/auth/refresh/{token}
Renovar um token JWT válido.

**Path Parameters:**
- `token`: Token JWT atual para renovação

**Respostas:**
- **200 OK:** Novo token gerado com sucesso
- **401 Unauthorized:** Token inválido para renovação

---

## 👥 Usuários

### 🔓 Rotas Públicas (sem autenticação)
- `POST /api/v1/users` - Criar usuário
- `POST /api/v1/users/register` - Criar usuário (alias)
- `GET /api/v1/users` - Listar usuários

### 🔑 Rotas Protegidas (requer JWT)
- `GET /api/v1/users/{id}` - Buscar usuário por ID
- `PUT /api/v1/users/{id}` - Atualizar usuário
- `PATCH /api/v1/users/{id}/change-password` - Alterar senha
- `GET /api/v1/users/me` - Dados do usuário logado

### 👑 Rotas Admin (requer JWT de Admin)
- `DELETE /api/v1/users/{id}` - Deletar usuário

### POST /api/v1/users
### POST /api/v1/users/register
Criar um novo usuário.

**Body:**
```json
{
  "nome": "string (obrigatório)",
  "email": "string (obrigatório, único)",
  "senha": "string (obrigatório)",
  "role": "USER|ADMIN (opcional, padrão: USER)"
}
```

**Respostas:**
- **201 Created:** Usuário criado com sucesso
- **400 Bad Request:** Email já existe ou dados inválidos

---

### GET /api/v1/users 🔓
Listar usuários com paginação e busca. **Rota pública.**

**Query Parameters:**
- `page`: Número da página (padrão: 1)
- `per_page`: Itens por página (padrão: 10, max: 100)
- `search`: Buscar por nome ou email

**Exemplos:**
```
GET /api/v1/users
GET /api/v1/users?page=2&per_page=5
GET /api/v1/users?search=João
GET /api/v1/users?page=1&per_page=3&search=Silva
```

**Respostas:**
- **200 OK:** Lista de usuários com metadados de paginação

---

### GET /api/v1/users/{id} 🔑
Buscar usuário específico por ID. **Requer autenticação JWT.**

**Headers:**
```
Authorization: Bearer {jwt_token}
```

**Path Parameters:**
- `id`: UUID do usuário

**Permissões:**
- Usuários podem ver apenas seus próprios dados
- Admins podem ver qualquer usuário

**Respostas:**
- **200 OK:** Dados do usuário
- **401 Unauthorized:** Token inválido ou ausente
- **403 Forbidden:** Sem permissão para ver este usuário
- **404 Not Found:** Usuário não encontrado

---

### GET /api/v1/users/me 🔑
Obter dados do usuário logado. **Requer autenticação JWT.**

**Headers:**
```
Authorization: Bearer {jwt_token}
```

**Respostas:**
- **200 OK:** Dados do usuário logado
- **401 Unauthorized:** Token inválido ou ausente

---

### PUT /api/v1/users/{id} 🔑
Atualizar dados do usuário. **Requer autenticação JWT.**

**Headers:**
```
Authorization: Bearer {jwt_token}
```

**Path Parameters:**
- `id`: UUID do usuário

**Body (todos os campos são opcionais):**
```json
{
  "nome": "string (opcional)",
  "email": "string (opcional)",
  "senha": "string (opcional)",
  "role": "USER|ADMIN (opcional)"
}
```

**Permissões:**
- Usuários podem atualizar apenas seus próprios dados
- Apenas admins podem alterar roles
- Admins podem atualizar qualquer usuário

**Respostas:**
- **200 OK:** Usuário atualizado com sucesso
- **400 Bad Request:** Email já usado por outro usuário
- **401 Unauthorized:** Token inválido ou ausente
- **403 Forbidden:** Sem permissão para atualizar este usuário
- **404 Not Found:** Usuário não encontrado

---

### PATCH /api/v1/users/{id}/change-password 🔑
Alterar senha do usuário. **Requer autenticação JWT.**

**Headers:**
```
Authorization: Bearer {jwt_token}
```

**Path Parameters:**
- `id`: UUID do usuário

**Body:**
```json
{
  "senha_atual": "string (obrigatório)",
  "senha_nova": "string (obrigatório)"
}
```

**Permissões:**
- Usuários podem alterar apenas sua própria senha
- Admins podem alterar senha de qualquer usuário

**Respostas:**
- **200 OK:** Senha alterada com sucesso
- **400 Bad Request:** Senha atual incorreta
- **401 Unauthorized:** Token inválido ou ausente
- **403 Forbidden:** Sem permissão para alterar senha deste usuário
- **404 Not Found:** Usuário não encontrado

---

### DELETE /api/v1/users/{id} 👑
Deletar usuário. **Requer JWT de administrador.**

**Headers:**
```
Authorization: Bearer {admin_jwt_token}
```

**Path Parameters:**
- `id`: UUID do usuário

**Permissões:**
- Apenas administradores podem deletar usuários

**Respostas:**
- **200 OK:** Usuário deletado com sucesso
- **401 Unauthorized:** Token inválido ou ausente
- **403 Forbidden:** Usuário não é administrador
- **404 Not Found:** Usuário não encontrado

---

## 📊 Códigos de Status

| Código | Status | Descrição |
|--------|---------|-----------|
| 200 | OK | Operação realizada com sucesso |
| 201 | Created | Recurso criado com sucesso |
| 400 | Bad Request | Dados inválidos na requisição |
| 401 | Unauthorized | Token inválido, ausente ou expirado |
| 403 | Forbidden | Token válido mas sem permissão |
| 404 | Not Found | Recurso não encontrado |
| 422 | Unprocessable Entity | JSON malformado |
| 500 | Internal Server Error | Erro interno do servidor |

## 🗂️ Estrutura de Resposta

### Usuário (UserResponse)
```json
{
  "id": "uuid",
  "nome": "string",
  "email": "string",
  "role": "USER|ADMIN",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### Lista de Usuários (UserListResponse)
```json
{
  "users": [UserResponse],
  "total": "number",
  "page": "number",
  "per_page": "number", 
  "total_pages": "number"
}
```

### Mensagem de Sucesso
```json
{
  "message": "string",
  "user": UserResponse // opcional
}
```

### Mensagem de Erro
```json
{
  "error": "string"
}
```

## 🧪 Testando as Rotas

### Com curl
```bash
# Health check
curl http://localhost:8080/health

# Login
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sistema.com","senha":"admin123"}'

# Criar usuário (público)
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"nome":"João","email":"joao@test.com","senha":"123456","role":"USER"}'

# Listar usuários (público)
curl http://localhost:8080/api/v1/users

# Buscar usuário atual (requer JWT)
curl -H "Authorization: Bearer {token}" \
  http://localhost:8080/api/v1/users/me

# Buscar por ID (requer JWT)
curl -H "Authorization: Bearer {token}" \
  http://localhost:8080/api/v1/users/{user-id}

# Atualizar usuário (requer JWT)
curl -X PUT http://localhost:8080/api/v1/users/{user-id} \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{"nome":"João Silva"}'

# Alterar senha (requer JWT)
curl -X PATCH http://localhost:8080/api/v1/users/{user-id}/change-password \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{"senha_atual":"123456","senha_nova":"new123"}'

# Deletar usuário (requer JWT de Admin)
curl -X DELETE http://localhost:8080/api/v1/users/{user-id} \
  -H "Authorization: Bearer {admin_token}"
```

### Com script automático
```bash
make api-test
```

## 📝 Notas Importantes

1. **UUIDs:** Todos os IDs de usuário são UUIDs v4
2. **Senhas:** São automaticamente criptografadas com bcrypt
3. **Paginação:** Limite máximo de 100 itens por página
4. **Busca:** Funciona com ILIKE (case-insensitive) em nome e email
5. **Validação:** Email deve ser único no sistema
6. **Timestamps:** Todos em formato UTC (ISO 8601)
7. **Roles:** USER (padrão) ou ADMIN
8. **Usuário Admin Padrão:** email `admin@sistema.com`, senha `admin123`
9. **JWT:** Tokens expiram em 1 hora (configurável)
10. **Bearer Token:** Formato `Authorization: Bearer {token}`
11. **Permissões:** Usuários comuns só acessam seus dados, admins acessam todos
12. **Middleware:** Rotas protegidas validam JWT automaticamente

## 🔐 Símbolos de Autenticação

- 🔓 **Público:** Não requer autenticação
- 🔑 **JWT:** Requer token JWT válido
- 👑 **Admin:** Requer token JWT de administrador