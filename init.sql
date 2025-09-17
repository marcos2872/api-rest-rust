-- Inicialização do banco de dados para API REST Rust
-- Este arquivo será executado automaticamente quando o container PostgreSQL for iniciado

-- Habilitar extensão UUID (caso não esteja habilitada)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Criar schema se não existir
CREATE SCHEMA IF NOT EXISTS public;

-- Definir timezone padrão
SET timezone = 'UTC';

-- Log de inicialização
DO $$
BEGIN
    RAISE NOTICE 'Inicializando banco de dados para API REST Rust...';
    RAISE NOTICE 'Database: rust_api_db';
    RAISE NOTICE 'User: rust_user';
    RAISE NOTICE 'Extensions habilitadas: uuid-ossp';
END $$;
