# 🚨 Respostas de Erro Padronizadas

Documentação completa das respostas de erro JSON estruturadas da API REST Rust.

## 📋 Visão Geral

Todas as respostas de erro da API agora seguem um formato padronizado com:
- **Campo `error`**: Tipo do erro (ex: "Unauthorized", "Bad Request")
- **Campo `message`**: Mensagem descritiva para humanos
- **Campo `code`**: Código identificador para máquinas
- **Campo `timestamp`**: Timestamp UTC da ocorrência do erro

## 🔍 Formato Padrão

```json
{
  "error": "Error Type",
  "message": "Human-readable error description",
  "code": "MACHINE_READABLE_CODE",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

## 🚨 Códigos de Status e Exemplos

### HTTP 400 - Bad Request

#### Email já existe
```json
{
  "error": "Bad Request",
  "message": "Email já está em uso",
  "code": "EMAIL_ALREADY_EXISTS",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

#### Senha atual incorreta
```json
{
  "error": "Bad Request",
  "message": "Senha atual incorreta",
  "code": "INVALID_PASSWORD",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

#### ID de usuário inválido
```json
{
  "error": "Bad Request",
  "message": "ID de usuário inválido no token",
  "code": "INVALID_USER_ID",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

#### JSON malformado
```json
{
  "error": "Bad Request",
  "message": "Invalid JSON format or content type. Please ensure your request body contains valid JSON.",
  "code": "INVALID_JSON",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

### HTTP 401 - Unauthorized

#### Credenciais inválidas (Login)
```json
{
  "error": "Unauthorized",
  "message": "Credenciais inválidas",
  "code": "INVALID_CREDENTIALS",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

#### Token expirado
```json
{
  "error": "Unauthorized",
  "message": "Token expirado",
  "code": "TOKEN_EXPIRED",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

#### Token inválido
```json
{
  "error": "Unauthorized",
  "message": "Token inválido",
  "code": "INVALID_TOKEN",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

#### Token ausente
```json
{
  "error": "Unauthorized",
  "message": "Token JWT não encontrado",
  "code": "TOKEN_MISSING",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

#### Token de refresh inválido
```json
{
  "error": "Unauthorized",
  "message": "Token inválido para refresh",
  "code": "INVALID_REFRESH_TOKEN",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

### HTTP 403 - Forbidden

#### Acesso negado - dados próprios
```json
{
  "error": "Forbidden",
  "message": "Acesso negado. Você só pode ver seus próprios dados.",
  "code": "ACCESS_DENIED",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

#### Permissões de administrador necessárias
```json
{
  "error": "Forbidden",
  "message": "Acesso negado. Apenas administradores podem listar usuários.",
  "code": "ADMIN_REQUIRED",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

#### Alterar role requer admin
```json
{
  "error": "Forbidden",
  "message": "Apenas administradores podem alterar roles de usuário.",
  "code": "ADMIN_REQUIRED",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

### HTTP 404 - Not Found

#### Usuário não encontrado
```json
{
  "error": "Not Found",
  "message": "Usuário não encontrado",
  "code": "USER_NOT_FOUND",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

#### Endpoint não encontrado
```json
{
  "error": "Not Found",
  "message": "The requested endpoint was not found",
  "code": "ENDPOINT_NOT_FOUND",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

### HTTP 429 - Too Many Requests (Rate Limiting)

```json
{
  "error": "Rate limit exceeded",
  "message": "Too many requests. Limit: 60 requests per minute",
  "retry_after_seconds": 30
}
```

**Headers adicionais:**
- `Retry-After: 30`
- `X-RateLimit-Limit: 60`
- `X-RateLimit-Remaining: 0`

### HTTP 500 - Internal Server Error

#### Erro de banco de dados
```json
{
  "error": "Internal Server Error",
  "message": "Erro interno do servidor",
  "code": "DATABASE_ERROR",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

#### Erro de hash de senha
```json
{
  "error": "Internal Server Error",
  "message": "Erro interno do servidor",
  "code": "PASSWORD_HASH_ERROR",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

#### Erro de geração de token
```json
{
  "error": "Internal Server Error",
  "message": "Erro interno do servidor",
  "code": "TOKEN_GENERATION_ERROR",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

#### Erro de criação de usuário
```json
{
  "error": "Internal Server Error",
  "message": "Erro ao criar usuário",
  "code": "USER_CREATION_ERROR",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

## 📖 Códigos de Erro por Categoria

### 🔐 Autenticação e Autorização
| Código | Descrição | HTTP Status |
|--------|-----------|-------------|
| `INVALID_CREDENTIALS` | Email/senha incorretos | 401 |
| `TOKEN_EXPIRED` | Token JWT expirado | 401 |
| `INVALID_TOKEN` | Token JWT inválido/malformado | 401 |
| `TOKEN_MISSING` | Header Authorization ausente | 401 |
| `INVALID_REFRESH_TOKEN` | Token para refresh inválido | 401 |
| `ACCESS_DENIED` | Acesso negado aos dados | 403 |
| `ADMIN_REQUIRED` | Requer privilégios de admin | 403 |

### 👤 Usuários
| Código | Descrição | HTTP Status |
|--------|-----------|-------------|
| `EMAIL_ALREADY_EXISTS` | Email já cadastrado | 400 |
| `INVALID_PASSWORD` | Senha atual incorreta | 400 |
| `INVALID_USER_ID` | ID de usuário inválido | 400 |
| `USER_NOT_FOUND` | Usuário não existe | 404 |
| `USER_CREATION_ERROR` | Falha ao criar usuário | 500 |

### 🛠️ Sistema
| Código | Descrição | HTTP Status |
|--------|-----------|-------------|
| `DATABASE_ERROR` | Erro de banco de dados | 500 |
| `PASSWORD_HASH_ERROR` | Erro ao criptografar senha | 500 |
| `TOKEN_GENERATION_ERROR` | Erro ao gerar JWT | 500 |
| `PASSWORD_VERIFICATION_ERROR` | Erro ao verificar senha | 500 |
| `INVALID_JSON` | JSON malformado | 400 |
| `PAYLOAD_TOO_LARGE` | Payload muito grande | 413 |

## 🧪 Testando Respostas de Erro

### Teste de Credenciais Inválidas
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@sistema.com","senha":"senhaerrada"}'
```

**Resposta:**
```json
{
  "error": "Unauthorized",
  "message": "Credenciais inválidas",
  "code": "INVALID_CREDENTIALS",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

### Teste de Token Ausente
```bash
curl http://localhost:8080/api/v1/users/me
```

**Resposta:**
```json
{
  "error": "Unauthorized",
  "message": "Token JWT não encontrado",
  "code": "TOKEN_MISSING",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

### Teste de Acesso Negado
```bash
# Usuário comum tentando listar usuários
curl -H "Authorization: Bearer USER_TOKEN" \
  http://localhost:8080/api/v1/users
```

**Resposta:**
```json
{
  "error": "Forbidden",
  "message": "Acesso negado. Apenas administradores podem listar usuários.",
  "code": "ADMIN_REQUIRED",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

### Teste de JSON Inválido
```bash
curl -X POST http://localhost:8080/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"nome": "Test", "email"'  # JSON incompleto
```

**Resposta:**
```json
{
  "error": "Bad Request",
  "message": "Invalid JSON format or content type. Please ensure your request body contains valid JSON.",
  "code": "INVALID_JSON",
  "timestamp": "2023-12-01T10:30:00.000Z"
}
```

## 🎯 Como Usar os Códigos de Erro

### No Frontend/Cliente
```javascript
// Exemplo em JavaScript
try {
  const response = await fetch('/api/v1/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });

  if (!response.ok) {
    const error = await response.json();
    
    switch (error.code) {
      case 'INVALID_CREDENTIALS':
        showError('Email ou senha incorretos');
        break;
      case 'TOKEN_EXPIRED':
        redirectToLogin();
        break;
      case 'ADMIN_REQUIRED':
        showError('Você não tem permissão para esta ação');
        break;
      default:
        showError(error.message);
    }
    return;
  }
  
  // Sucesso
  const data = await response.json();
} catch (err) {
  showError('Erro de conexão');
}
```

### Em Logs/Monitoramento
- Use o campo `code` para alertas automatizados
- Use o campo `message` para logs humanos
- Use o `timestamp` para correlação temporal
- Monitore códigos específicos para métricas

### Para Debug
1. **Campo `code`**: Identifica o tipo exato do erro
2. **Campo `message`**: Fornece contexto para desenvolvedores
3. **Campo `timestamp`**: Ajuda na correlação com logs do servidor
4. **HTTP Status**: Indica a categoria geral do problema

## 🔍 Troubleshooting por Código

### Erros de Autenticação (4xx)
- `INVALID_CREDENTIALS` → Verificar email/senha
- `TOKEN_EXPIRED` → Fazer novo login
- `INVALID_TOKEN` → Verificar formato do token
- `ACCESS_DENIED` → Verificar permissões do usuário

### Erros do Sistema (5xx)
- `DATABASE_ERROR` → Verificar conexão com PostgreSQL
- `PASSWORD_HASH_ERROR` → Verificar configuração do bcrypt
- `TOKEN_GENERATION_ERROR` → Verificar configuração JWT

## 📊 Monitoramento Recomendado

### Alertas por Código de Erro
- `DATABASE_ERROR` → Alta prioridade
- `TOKEN_GENERATION_ERROR` → Alta prioridade
- `INVALID_CREDENTIALS` → Monitorar tentativas de força bruta
- `ADMIN_REQUIRED` → Monitorar tentativas de escalação

### Métricas Sugeridas
- Taxa de erros 401 por endpoint
- Frequência de `INVALID_CREDENTIALS`
- Contagem de `TOKEN_EXPIRED` (indicador de UX)
- Erros 500 por tipo de código

---

**💡 Dica:** Use sempre o campo `code` em vez do campo `message` para lógica de aplicação, pois as mensagens podem mudar enquanto os códigos permanecem estáveis.