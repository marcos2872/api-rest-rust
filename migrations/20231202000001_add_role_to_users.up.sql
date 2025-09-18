-- Adicionar coluna role à tabela users
-- Role pode ser 'USER' ou 'ADMIN'

-- Criar tipo enum para roles
CREATE TYPE user_role AS ENUM ('USER', 'ADMIN');

-- Adicionar coluna role com valor padrão USER
ALTER TABLE users
ADD COLUMN role user_role DEFAULT 'USER' NOT NULL;

-- Criar índice na coluna role para consultas mais rápidas
CREATE INDEX idx_users_role ON users(role);

-- Comentários para documentação
COMMENT ON TYPE user_role IS 'Tipos de role disponíveis: USER (usuário comum) e ADMIN (administrador)';
COMMENT ON COLUMN users.role IS 'Role do usuário no sistema (USER ou ADMIN)';
