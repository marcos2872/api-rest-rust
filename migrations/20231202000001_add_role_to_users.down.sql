-- Remover coluna role e tipo enum da tabela users

-- Remover índice
DROP INDEX IF EXISTS idx_users_role;

-- Remover coluna role
ALTER TABLE users DROP COLUMN IF EXISTS role;

-- Remover tipo enum
DROP TYPE IF EXISTS user_role;
