# 🚦 Rate Limiting - Documentação Completa

Sistema de rate limiting implementado na API REST Rust para controle de tráfego e proteção contra abuso.

## 📋 Visão Geral

O rate limiting é implementado usando o algoritmo **Token Bucket** por endereço IP, oferecendo:

- ✅ Controle de requisições por minuto por IP
- ✅ Suporte a rajadas (burst) de requisições
- ✅ Headers informativos nas respostas
- ✅ Suporte a reverse proxy (X-Forwarded-For, X-Real-IP)
- ✅ Cleanup automático de entradas antigas
- ✅ Configuração via variáveis de ambiente

## ⚙️ Configuração

### Variáveis de Ambiente

```env
# Número máximo de requisições por minuto por IP
RATE_LIMIT_RPM=60

# Número de requisições em rajada permitidas
RATE_LIMIT_BURST=10
```

### Configurações Predefinidas

| Perfil | RPM | Burst | Uso |
|--------|-----|-------|-----|
| **Strict** | 30 | 5 | Produção alta segurança |
| **Default** | 60 | 10 | Uso geral |
| **Lenient** | 120 | 20 | Desenvolvimento/testes |

## 🔧 Algoritmo Token Bucket

### Como Funciona

1. **Bucket inicial**: Cada IP recebe um "balde" com tokens igual ao `RATE_LIMIT_BURST`
2. **Consumo**: Cada requisição consome 1 token
3. **Recarga**: Tokens são adicionados a uma taxa de `RATE_LIMIT_RPM / 60` por segundo
4. **Limite**: O bucket nunca excede `RATE_LIMIT_BURST` tokens
5. **Bloqueio**: Requisições são negadas quando não há tokens disponíveis

### Exemplo Prático

```
Configuração: RPM=60, BURST=10

Tempo 0s:  [🪙🪙🪙🪙🪙🪙🪙🪙🪙🪙] (10 tokens)
Requisição 1-10: ✅ Aceitas (consome todos os tokens)
Requisição 11: ❌ Negada (sem tokens)

Tempo 60s: [🪙] (1 token adicionado)
Requisição: ✅ Aceita

Tempo 120s: [🪙🪙] (mais 1 token)
```

## 📊 Detecção de IP

O sistema detecta IPs na seguinte ordem de prioridade:

1. **X-Forwarded-For** (primeiro IP da lista)
2. **X-Real-IP** 
3. **Peer Address** (conexão direta)

### Headers Suportados

```http
X-Forwarded-For: 203.0.113.1, 198.51.100.1
X-Real-IP: 203.0.113.1
```

## 🚨 Resposta de Rate Limit

### HTTP 429 - Too Many Requests

```http
HTTP/1.1 429 Too Many Requests
Retry-After: 30
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 0
Content-Type: application/json

{
  "error": "Rate limit exceeded",
  "message": "Too many requests. Limit: 60 requests per minute",
  "retry_after_seconds": 30
}
```

### Headers de Resposta

| Header | Descrição | Exemplo |
|--------|-----------|---------|
| `Retry-After` | Segundos até próxima tentativa | `30` |
| `X-RateLimit-Limit` | Limite de requisições/minuto | `60` |
| `X-RateLimit-Remaining` | Tokens restantes | `5` |

## 🧪 Testes

### Teste Automático

```bash
# Executar suite completa de testes
make rate-limit-test

# Script direto
./test_rate_limit.sh
```

### Teste Manual

```bash
# Enviar múltiplas requisições rapidamente
for i in {1..20}; do
  curl -w "HTTP: %{http_code}\n" http://localhost:8080/health &
done
wait

# Verificar rate limiting específico
curl -i http://localhost:8080/health
```

### Teste com Scripts

```bash
#!/bin/bash
# Teste de burst
for i in {1..15}; do
  response=$(curl -s -w "%{http_code}" http://localhost:8080/health)
  echo "Request $i: ${response: -3}"
  sleep 0.1
done
```

## 📈 Monitoramento

### Logs do Servidor

```log
🚀 Servidor rodando em http://127.0.0.1:8080
🔑 JWT configurado com expiração de 3600 segundos
🚦 Rate limiting: 60 requisições/minuto, burst de 10
```

### Métricas Recomendadas

- Número de requisições rate limited por minuto
- IPs mais ativos
- Endpoints mais afetados
- Tempo médio de reset

## 🛡️ Estratégias de Proteção

### Configurações por Ambiente

**Desenvolvimento:**
```env
RATE_LIMIT_RPM=120
RATE_LIMIT_BURST=20
```

**Produção:**
```env
RATE_LIMIT_RPM=30
RATE_LIMIT_BURST=5
```

**API Pública:**
```env
RATE_LIMIT_RPM=100
RATE_LIMIT_BURST=15
```

### Endpoints Críticos

Para endpoints sensíveis, considere:
- Rate limiting mais restritivo
- Rate limiting baseado em usuário autenticado
- Whitelist de IPs confiáveis

## 🔄 Bypass e Exceções

### Cenários Especiais

```rust
// Exemplo de bypass para IPs específicos (futuro)
if is_whitelisted_ip(client_ip) {
    return next.call(req).await;
}

// Rate limiting diferenciado por endpoint
let config = match req.path() {
    "/api/v1/auth/login" => strict_config(),
    "/health" => lenient_config(),
    _ => default_config(),
};
```

## 🚀 Otimizações

### Performance

1. **Cleanup**: Entradas antigas são removidas automaticamente
2. **Memória**: HashMap em memória para velocidade
3. **Locks**: Mutex granular por operação

### Escalabilidade

Para alta escala, considere:
- Redis para state compartilhado
- Rate limiting no load balancer
- CDN com rate limiting

## 🐛 Troubleshooting

### Problemas Comuns

**1. Rate limiting não funciona:**
```bash
# Verificar configuração
make api-diagnose

# Verificar logs do servidor
RUST_LOG=debug make run
```

**2. Muitos false positives:**
```env
# Aumentar limites
RATE_LIMIT_RPM=120
RATE_LIMIT_BURST=20
```

**3. Rate limiting muito permissivo:**
```env
# Diminuir limites
RATE_LIMIT_RPM=30
RATE_LIMIT_BURST=5
```

### Debug

```bash
# Testar com curl verbose
curl -v -i http://localhost:8080/health

# Verificar headers de rate limit
curl -I http://localhost:8080/health

# Teste de stress
ab -n 100 -c 10 http://localhost:8080/health
```

## 📚 Implementação

### Estrutura do Código

```
src/middleware/rate_limit.rs
├── RateLimitConfig     # Configuração
├── ClientState         # Estado por IP
├── RateLimiter        # Lógica principal
└── rate_limit_middleware # Middleware Actix-web
```

### Integração

```rust
// main.rs
let rate_limiter = custom_rate_limiter(rpm, burst);

App::new()
    .app_data(rate_limiter.clone())
    .wrap(from_fn(rate_limit_middleware))
```

## 🔮 Roadmap Futuro

- [ ] Rate limiting por usuário autenticado
- [ ] Redis backend para clustering
- [ ] Métricas Prometheus
- [ ] Rate limiting adaptativo
- [ ] Whitelist/blacklist de IPs
- [ ] Rate limiting por endpoint
- [ ] Dashboard de monitoramento

## 📖 Referências

- [Token Bucket Algorithm](https://en.wikipedia.org/wiki/Token_bucket)
- [HTTP 429 Too Many Requests](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/429)
- [Actix-web Middleware](https://actix.rs/docs/middleware)
- [Rate Limiting Patterns](https://cloud.google.com/solutions/rate-limiting-strategies-techniques)

## ⚡ Quick Start

```bash
# 1. Configurar rate limiting
echo "RATE_LIMIT_RPM=60" >> .env
echo "RATE_LIMIT_BURST=10" >> .env

# 2. Iniciar servidor
make run

# 3. Testar rate limiting
make rate-limit-test

# 4. Verificar logs
# Servidor mostrará: "🚦 Rate limiting: 60 requisições/minuto, burst de 10"
```

---

**💡 Dica:** Ajuste os valores de rate limiting baseado no seu caso de uso específico. Monitore logs e métricas para encontrar o equilíbrio ideal entre proteção e usabilidade.