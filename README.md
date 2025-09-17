# API REST em Rust

API REST desenvolvida em Rust usando Actix-web e SQLx com PostgreSQL para cadastro de usuários.

## 🚀 Funcionalidades

- Cadastro de usuários com validação
- Criptografia de senhas com bcrypt
- Conexão com PostgreSQL usando SQLx
- Validação de email único
- Migrações automáticas de banco de dados

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

## 📡 Endpoints

### Verificar status da API
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

### Cadastrar usuário
```http
POST /api/v1/users/register
Content-Type: application/json

{
  "nome": "João Silva",
  "email": "joao@exemplo.com",
  "senha": "minhasenha123"
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
    "created_at": "2023-12-01T10:30:00Z",
    "updated_at": "2023-12-01T10:30:00Z"
  }
}
```

**Resposta de erro (400):**
```json
{
  "error": "Email já está em uso"
}
```

## 🧪 Testando a API

### Usando script de teste (Recomendado)
```bash
# Certifique-se de que o servidor está rodando
make run

# Em outro terminal, execute os testes
make api-test
```

### Testando com curl manualmente
```bash
# Verificar se a API está funcionando
curl http://localhost:8080/health

# Cadastrar um usuário
curl -X POST http://localhost:8080/api/v1/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "João Silva",
    "email": "joao@exemplo.com",
    "senha": "minhasenha123"
  }'
```

### Usando PgAdmin
Acesse `http://localhost:8081` para gerenciar o banco:
- **Email:** admin@example.com
- **Senha:** admin123

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

## 📝 Próximos Passos

- [ ] Implementar autenticação JWT
- [ ] Adicionar endpoint de login
- [ ] Implementar validação de dados mais robusta
- [ ] Adicionar testes unitários e de integração
- [ ] Implementar paginação
- [ ] Adicionar documentação Swagger/OpenAPI
- [ ] Adicionar rate limiting
- [ ] Implementar logs estruturados

## 🤝 Contribuindo

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.