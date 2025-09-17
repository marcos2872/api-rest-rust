# Makefile para API REST Rust
# Comandos para desenvolvimento e gerenciamento do projeto

.PHONY: help install build run test clean docker-up docker-down docker-logs migrate check format lint

# Variáveis
CARGO := cargo
DOCKER_COMPOSE := docker compose

# Ajuda - mostra todos os comandos disponíveis
help:
	@echo "🦀 API REST Rust - Comandos Disponíveis"
	@echo "======================================"
	@echo ""
	@echo "📦 Desenvolvimento:"
	@echo "  install     - Instala dependências do projeto"
	@echo "  build       - Compila o projeto"
	@echo "  run         - Executa o servidor"
	@echo "  check       - Verifica o código sem compilar"
	@echo "  test        - Executa testes"
	@echo "  format      - Formata o código"
	@echo "  lint        - Executa clippy (linter)"
	@echo ""
	@echo "🐳 Docker:"
	@echo "  docker-up   - Inicia PostgreSQL e PgAdmin"
	@echo "  docker-down - Para e remove containers"
	@echo "  docker-logs - Mostra logs dos containers"
	@echo ""
	@echo "🗄️  Database:"
	@echo "  migrate     - Executa migrações do banco"
	@echo ""
	@echo "🧹 Limpeza:"
	@echo "  clean       - Remove arquivos de build"
	@echo ""
	@echo "🧪 Teste da API:"
	@echo "  api-test    - Executa testes da API (requer servidor rodando)"

# Instala dependências
install:
	@echo "📦 Instalando dependências..."
	$(CARGO) fetch

# Compila o projeto
build:
	@echo "🔨 Compilando projeto..."
	$(CARGO) build

# Compila em modo release
build-release:
	@echo "🔨 Compilando em modo release..."
	$(CARGO) build --release

# Executa o servidor
run:
	@echo "🚀 Iniciando servidor..."
	$(CARGO) run

# Verifica o código
check:
	@echo "🔍 Verificando código..."
	$(CARGO) check

# Executa testes
test:
	@echo "🧪 Executando testes..."
	$(CARGO) test

# Formata o código
format:
	@echo "📝 Formatando código..."
	$(CARGO) fmt

# Executa clippy (linter)
lint:
	@echo "🔎 Executando clippy..."
	$(CARGO) clippy -- -D warnings

# Inicia containers Docker
docker-up:
	@echo "🐳 Iniciando PostgreSQL e PgAdmin..."
	$(DOCKER_COMPOSE) up -d
	@echo "✅ PostgreSQL: http://localhost:5432"
	@echo "✅ PgAdmin: http://localhost:8081"
	@echo "   Email: admin@example.com"
	@echo "   Senha: admin123"

# Para containers Docker
docker-down:
	@echo "🛑 Parando containers..."
	$(DOCKER_COMPOSE) down

# Mostra logs dos containers
docker-logs:
	@echo "📋 Logs dos containers:"
	$(DOCKER_COMPOSE) logs -f

# Executa migrações (requer sqlx-cli)
migrate:
	@echo "🗄️  Executando migrações..."
	@if ! command -v sqlx >/dev/null 2>&1; then \
		echo "❌ sqlx-cli não encontrado. Instalando..."; \
		$(CARGO) install sqlx-cli --no-default-features --features rustls,postgres; \
	fi
	sqlx migrate run

# Limpa arquivos de build
clean:
	@echo "🧹 Limpando arquivos de build..."
	$(CARGO) clean

# Executa todos os checks de qualidade
quality: format lint check test
	@echo "✅ Todos os checks de qualidade executados!"

# Setup completo do projeto
setup: install docker-up
	@echo "⏳ Aguardando PostgreSQL inicializar..."
	@sleep 10
	@make migrate
	@echo "🎉 Setup completo! Execute 'make run' para iniciar o servidor"

# Executa testes da API
api-test:
	@echo "🧪 Executando testes da API..."
	@if ! curl -s http://localhost:8080/health >/dev/null; then \
		echo "❌ Servidor não está rodando. Execute 'make run' primeiro"; \
		exit 1; \
	fi
	@./test_api.sh

# Monitora arquivos e reinicia automaticamente (requer cargo-watch)
watch:
	@echo "👁️  Monitorando arquivos para reinicialização automática..."
	@if ! command -v cargo-watch >/dev/null 2>&1; then \
		echo "📦 Instalando cargo-watch..."; \
		$(CARGO) install cargo-watch; \
	fi
	cargo-watch -x run

# Gera documentação
docs:
	@echo "📚 Gerando documentação..."
	$(CARGO) doc --open

# Comando de desenvolvimento completo
dev: format lint check build run

# Backup do banco de dados
db-backup:
	@echo "💾 Fazendo backup do banco..."
	@docker exec rust-api-postgres pg_dump -U rust_user rust_api_db > backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "✅ Backup salvo como backup_$(shell date +%Y%m%d_%H%M%S).sql"

# Informações do projeto
info:
	@echo "📋 Informações do Projeto"
	@echo "========================"
	@echo "Nome: API REST Rust"
	@echo "Versão: $(shell grep '^version' Cargo.toml | cut -d'"' -f2)"
	@echo "Rust: $(shell rustc --version)"
	@echo "Cargo: $(shell cargo --version)"
	@echo ""
	@echo "🔗 URLs:"
	@echo "  API: http://localhost:8080"
	@echo "  Health: http://localhost:8080/health"
	@echo "  PgAdmin: http://localhost:8081"
	@echo ""
	@echo "📁 Estrutura:"
	@echo "  src/          - Código fonte"
	@echo "  migrations/   - Migrações do banco"
	@echo "  target/       - Arquivos compilados"
