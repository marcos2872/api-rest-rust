-- Criar usuário administrador padrão
-- Senha padrão: admin123 (deve ser alterada após primeiro login)

INSERT INTO users (id, nome, email, senha, role, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000001'::uuid,
    'Administrador',
    'admin@sistema.com',
    '$2b$12$TcWd/dBbtG16Q7LXDrjKdubheLLzdoHT/Z55SKko/1vOcus8BYzDy', -- admin123
    'ADMIN',
    NOW(),
    NOW()
)
ON CONFLICT (email) DO NOTHING;

-- Comentário para documentação (removido devido a sintaxe PostgreSQL)
-- COMMENT ON CONSTRAINT users_email_key IS 'Email deve ser único - admin@sistema.com é reservado para administrador padrão';

-- Log da operação
DO $$
BEGIN
    RAISE NOTICE 'Usuário administrador criado com sucesso';
    RAISE NOTICE 'Email: admin@sistema.com';
    RAISE NOTICE 'Senha padrão: admin123 (ALTERE IMEDIATAMENTE!)';
    RAISE NOTICE 'Role: ADMIN';
END $$;
