-- Remover usuário administrador padrão

DELETE FROM users
WHERE email = 'admin@sistema.com'
AND role = 'ADMIN'
AND id = '00000000-0000-0000-0000-000000000001'::uuid;

-- Log da operação
DO $$
BEGIN
    RAISE NOTICE 'Usuário administrador padrão removido';
END $$;
