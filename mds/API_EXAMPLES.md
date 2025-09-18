# 📚 Exemplos de Uso da API REST

Este documento contém exemplos práticos de como usar todos os endpoints da API REST de usuários.

## 🔧 Configuração Inicial

Antes de testar os endpoints, certifique-se de que:

1. O servidor está rodando: `make run`
2. O PostgreSQL está ativo: `make docker-up`
3. As migrações foram executadas: `make migrate`

## 🌐 Base URL

```
http://localhost:8080
```

## 📋 Exemplos de Endpoints

### 1. Health Check

Verificar se a API está funcionando.

**Requisição:**
```bash
curl -X GET http://localhost:8080/health
```

**Resposta:**
```json
{
  "status": "ok",
  "message": "API está funcionando"
}
```

---

### 2. Criar Usuário

Criar um novo usuário no sistema.

**Requisição:**
```bash
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Ana Silva",
    "email": "ana.silva@email.com",
    "senha": "senha123456"
  }'
```

**Resposta de Sucesso (201):**
```json
{
  "message": "Usuário criado com sucesso",
  "user": {
    "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "nome": "Ana Silva",
    "email": "ana.silva@email.com",
    "created_at": "2023-12-01T14:30:00Z",
    "updated_at": "2023-12-01T14:30:00Z"
  }
}
```

**Resposta de Erro (400):**
```json
{
  "error": "Email já está em uso"
}
```

---

### 3. Listar Usuários

Obter lista paginada de usuários.

#### Listar todos (página 1, 10 por página)
```bash
curl -X GET http://localhost:8080/api/v1/users
```

#### Com paginação personalizada (Admin)
```bash
curl -H "Authorization: Bearer YOUR_ADMIN_JWT_TOKEN" \
  "http://localhost:8080/api/v1/users?page=2&per_page=5"
```

#### Com busca por nome ou email (Admin)
```bash
curl -H "Authorization: Bearer YOUR_ADMIN_JWT_TOKEN" \
  "http://localhost:8080/api/v1/users?search=Ana"
```

#### Busca com paginação (Admin)
```bash
curl -H "Authorization: Bearer YOUR_ADMIN_JWT_TOKEN" \
  "http://localhost:8080/api/v1/users?page=1&per_page=3&search=Silva"
```
### GET /api/v1/users (Apenas Administradores)

**Request:**
```bash
curl -H "Authorization: Bearer YOUR_ADMIN_JWT_TOKEN" \
  http://localhost:8080/api/v1/users
```

**Response (200 OK):**
```json
{
  "users": [
    {
      "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
      "nome": "Ana Silva",
      "email": "ana.silva@email.com",
      "role": "USER",
      "created_at": "2023-12-01T14:30:00Z",
      "updated_at": "2023-12-01T14:30:00Z"
    },
    {
      "id": "6ba7b810-9dad-11d1-80b4-00c04fd430c8",
      "nome": "Carlos Santos",
      "email": "carlos@email.com",
      "role": "USER",
      "created_at": "2023-12-01T15:00:00Z",
      "updated_at": "2023-12-01T15:00:00Z"
    }
  ],
  "total": 25,
  "page": 1,
  "per_page": 10,
  "total_pages": 3
}
```

**Response (403 Forbidden) - Usuário comum tentando acessar:**
```json
{
  "error": "Acesso negado. Apenas administradores podem listar usuários."
}
```

---

### 4. Buscar Usuário por ID

Obter detalhes de um usuário específico.

**Requisição:**
```bash
curl -X GET http://localhost:8080/api/v1/users/f47ac10b-58cc-4372-a567-0e02b2c3d479
```

**Resposta de Sucesso (200):**
```json
{
  "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "nome": "Ana Silva",
  "email": "ana.silva@email.com",
  "created_at": "2023-12-01T14:30:00Z",
  "updated_at": "2023-12-01T14:30:00Z"
}
```

**Resposta de Erro (404):**
```json
{
  "error": "Usuário não encontrado"
}
```

---

### 5. Atualizar Usuário

Atualizar informações de um usuário existente.

#### Atualizar apenas o nome
```bash
curl -X PUT http://localhost:8080/api/v1/users/f47ac10b-58cc-4372-a567-0e02b2c3d479 \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Ana Silva Santos"
  }'
```

#### Atualizar nome e email
```bash
curl -X PUT http://localhost:8080/api/v1/users/f47ac10b-58cc-4372-a567-0e02b2c3d479 \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Ana Silva Santos",
    "email": "ana.santos@email.com"
  }'
```

#### Atualizar todos os campos
```bash
curl -X PUT http://localhost:8080/api/v1/users/f47ac10b-58cc-4372-a567-0e02b2c3d479 \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Ana Silva Santos",
    "email": "ana.santos@email.com",
    "senha": "novasenha123"
  }'
```

**Resposta de Sucesso (200):**
```json
{
  "message": "Usuário atualizado com sucesso",
  "user": {
    "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "nome": "Ana Silva Santos",
    "email": "ana.santos@email.com",
    "created_at": "2023-12-01T14:30:00Z",
    "updated_at": "2023-12-01T16:45:00Z"
  }
}
```

**Resposta de Erro (400):**
```json
{
  "error": "Email já está em uso por outro usuário"
}
```

---

### 6. Alterar Senha

Alterar a senha de um usuário (requer senha atual).

**Requisição:**
```bash
curl -X PATCH http://localhost:8080/api/v1/users/f47ac10b-58cc-4372-a567-0e02b2c3d479/change-password \
  -H "Content-Type: application/json" \
  -d '{
    "senha_atual": "senha123456",
    "senha_nova": "minhaNovaSenh@123"
  }'
```

**Resposta de Sucesso (200):**
```json
{
  "message": "Senha alterada com sucesso"
}
```

**Resposta de Erro (400):**
```json
{
  "error": "Senha atual incorreta"
}
```

---

### 7. Deletar Usuário

Remover um usuário do sistema.

**Requisição:**
```bash
curl -X DELETE http://localhost:8080/api/v1/users/f47ac10b-58cc-4372-a567-0e02b2c3d479
```

**Resposta de Sucesso (200):**
```json
{
  "message": "Usuário deletado com sucesso"
}
```

**Resposta de Erro (404):**
```json
{
  "error": "Usuário não encontrado"
}
```

---

## 🧪 Cenários de Teste

### Fluxo Completo de Usuário

```bash
#!/bin/bash

# 1. Criar usuário
echo "=== Criando usuário ==="
USER_RESPONSE=$(curl -s -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Teste User",
    "email": "teste@email.com",
    "senha": "senha123"
  }')

echo $USER_RESPONSE | jq .

# 2. Extrair ID do usuário
USER_ID=$(echo $USER_RESPONSE | jq -r '.user.id')
echo "User ID: $USER_ID"

# 3. Buscar usuário criado
echo "=== Buscando usuário ==="
curl -s -X GET http://localhost:8080/api/v1/users/$USER_ID | jq .

# 4. Atualizar usuário
echo "=== Atualizando usuário ==="
curl -s -X PUT http://localhost:8080/api/v1/users/$USER_ID \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Teste User Atualizado",
    "email": "teste.atualizado@email.com"
  }' | jq .

# 5. Alterar senha
echo "=== Alterando senha ==="
curl -s -X PATCH http://localhost:8080/api/v1/users/$USER_ID/change-password \
  -H "Content-Type: application/json" \
  -d '{
    "senha_atual": "senha123",
    "senha_nova": "novaSenha456"
  }' | jq .

# 6. Listar usuários
echo "=== Listando usuários ==="
curl -s -X GET http://localhost:8080/api/v1/users | jq .

# 7. Deletar usuário
echo "=== Deletando usuário ==="
curl -s -X DELETE http://localhost:8080/api/v1/users/$USER_ID | jq .
```

### Teste de Validação

```bash
# Tentar criar usuário com dados inválidos
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "",
    "email": "email-invalido",
    "senha": "123"
  }'

# Tentar buscar usuário inexistente
curl -X GET http://localhost:8080/api/v1/users/00000000-0000-0000-0000-000000000000

# Tentar alterar senha com senha atual errada
curl -X PATCH http://localhost:8080/api/v1/users/f47ac10b-58cc-4372-a567-0e02b2c3d479/change-password \
  -H "Content-Type: application/json" \
  -d '{
    "senha_atual": "senha_errada",
    "senha_nova": "nova_senha"
  }'
```

---

## 🔗 Usando com Outras Ferramentas

### Postman

Importe esta coleção JSON no Postman:

```json
{
  "info": {
    "name": "API REST Rust - Users",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Health Check",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "{{baseUrl}}/health",
          "host": ["{{baseUrl}}"],
          "path": ["health"]
        }
      }
    },
    {
      "name": "Create User",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"nome\": \"{{$randomFirstName}} {{$randomLastName}}\",\n  \"email\": \"{{$randomEmail}}\",\n  \"senha\": \"password123\"\n}"
        },
        "url": {
          "raw": "{{baseUrl}}/api/v1/users",
          "host": ["{{baseUrl}}"],
          "path": ["api", "v1", "users"]
        }
      }
    }
  ],
  "variable": [
    {
      "key": "baseUrl",
      "value": "http://localhost:8080"
    }
  ]
}
```

### Insomnia

Importe este arquivo no Insomnia:

```json
{
  "_type": "export",
  "__export_format": 4,
  "resources": [
    {
      "_id": "req_health",
      "_type": "request",
      "method": "GET",
      "name": "Health Check",
      "url": "{{ _.baseUrl }}/health"
    },
    {
      "_id": "req_create_user",
      "_type": "request",
      "method": "POST",
      "name": "Create User",
      "url": "{{ _.baseUrl }}/api/v1/users",
      "headers": [
        {
          "name": "Content-Type",
          "value": "application/json"
        }
      ],
      "body": {
        "mimeType": "application/json",
        "text": "{\n  \"nome\": \"João Silva\",\n  \"email\": \"joao@email.com\",\n  \"senha\": \"senha123\"\n}"
      }
    }
  ]
}
```

---

## 📊 Códigos de Status HTTP

| Código | Significado | Quando Acontece |
|--------|-------------|-----------------|
| 200 | OK | Operação realizada com sucesso |
| 201 | Created | Usuário criado com sucesso |
| 400 | Bad Request | Dados inválidos ou email duplicado |
| 404 | Not Found | Usuário não encontrado |
| 422 | Unprocessable Entity | JSON malformado |
| 500 | Internal Server Error | Erro interno do servidor |

---

## 🛠️ Troubleshooting

### Problemas Comuns

**1. Erro de conexão:**
```bash
curl: (7) Failed to connect to localhost port 8080
```
**Solução:** Verificar se o servidor está rodando com `make run`

**2. Erro de banco de dados:**
```json
{"error": "Erro interno do servidor"}
```
**Solução:** Verificar se PostgreSQL está rodando com `make docker-up`

**3. UUID inválido:**
```json
{"error": "Usuário não encontrado"}
```
**Solução:** Verificar se o ID do usuário está no formato UUID correto

### Logs de Debug

Para ver logs detalhados:
```bash
RUST_LOG=debug make run
```

### Verificar Banco de Dados

Para verificar dados no banco:
```bash
# Acessar PostgreSQL
docker exec -it rust-api-postgres psql -U rust_user -d rust_api_db

# Listar usuários
SELECT id, nome, email, created_at FROM users;

# Contar usuários
SELECT COUNT(*) FROM users;
```
