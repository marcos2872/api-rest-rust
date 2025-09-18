use actix_web::{web, HttpRequest, HttpResponse, Result};
use bcrypt::{hash, verify, DEFAULT_COST};
use chrono::Utc;
use sqlx::PgPool;
use uuid::Uuid;

use crate::middleware::{
    bad_request_error, forbidden_error, get_claims_from_http_request, internal_server_error,
    not_found_error, unauthorized_error,
};
use crate::models::{
    ChangePasswordRequest, CreateUserRequest, UpdateUserRequest, User, UserListResponse,
    UserQueryParams, UserResponse, UserRole,
};

pub async fn register_user(
    pool: web::Data<PgPool>,
    user_data: web::Json<CreateUserRequest>,
) -> Result<HttpResponse> {
    // Verificar se o email já existe
    let existing_user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE email = $1")
        .bind(&user_data.email)
        .fetch_optional(pool.get_ref())
        .await;

    match existing_user {
        Ok(Some(_)) => {
            return Ok(bad_request_error(
                "Email já está em uso",
                "EMAIL_ALREADY_EXISTS",
            ));
        }
        Ok(None) => {
            // Email disponível, continuar com o cadastro
        }
        Err(e) => {
            eprintln!("Erro ao verificar email: {:?}", e);
            return Ok(internal_server_error(
                "Erro interno do servidor",
                "DATABASE_ERROR",
            ));
        }
    }

    // Hash da senha
    let hashed_password = match hash(&user_data.senha, DEFAULT_COST) {
        Ok(hashed) => hashed,
        Err(e) => {
            eprintln!("Erro ao fazer hash da senha: {:?}", e);
            return Ok(internal_server_error(
                "Erro interno do servidor",
                "PASSWORD_HASH_ERROR",
            ));
        }
    };

    // Criar novo usuário
    let new_user_id = Uuid::new_v4();
    let now = Utc::now();
    let user_role = user_data.role.clone().unwrap_or(UserRole::User);

    let result = sqlx::query_as::<_, User>(
        r#"
        INSERT INTO users (id, nome, email, senha, role, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING *
        "#,
    )
    .bind(new_user_id)
    .bind(&user_data.nome)
    .bind(&user_data.email)
    .bind(&hashed_password)
    .bind(user_role)
    .bind(now)
    .bind(now)
    .fetch_one(pool.get_ref())
    .await;

    match result {
        Ok(user) => {
            let user_response = UserResponse::from(user);
            Ok(HttpResponse::Created().json(serde_json::json!({
                "message": "Usuário criado com sucesso",
                "user": user_response
            })))
        }
        Err(e) => {
            eprintln!("Erro ao criar usuário: {:?}", e);
            Ok(internal_server_error(
                "Erro ao criar usuário",
                "USER_CREATION_ERROR",
            ))
        }
    }
}

// Listar usuários com paginação e busca (protegida por JWT - apenas admins)
pub async fn list_users(
    pool: web::Data<PgPool>,
    query: web::Query<UserQueryParams>,
    req: HttpRequest,
) -> Result<HttpResponse> {
    // Extrair claims do token JWT e verificar se é admin
    if let Some(claims) = get_claims_from_http_request(&req) {
        if !claims.is_admin() {
            return Ok(forbidden_error(
                "Acesso negado. Apenas administradores podem listar usuários.",
                "ADMIN_REQUIRED",
            ));
        }
    } else {
        return Ok(unauthorized_error(
            "Token JWT não encontrado",
            "TOKEN_MISSING",
        ));
    }
    let page = query.page.unwrap_or(1).max(1);
    let per_page = query.per_page.unwrap_or(10).min(100).max(1);
    let offset = (page - 1) * per_page;

    // Construir query com busca opcional
    let (where_clause, search_param) = if let Some(search) = &query.search {
        (
            "WHERE nome ILIKE $3 OR email ILIKE $3",
            Some(format!("%{}%", search)),
        )
    } else {
        ("", None)
    };

    // Contar total de usuários
    let count_query = format!("SELECT COUNT(*) FROM users {}", where_clause);
    let total_result = if let Some(search) = &search_param {
        sqlx::query_as(&count_query)
            .bind(search)
            .fetch_one(pool.get_ref())
            .await
    } else {
        sqlx::query_as(&count_query).fetch_one(pool.get_ref()).await
    };

    let total: (i64,) = match total_result {
        Ok(count) => count,
        Err(e) => {
            eprintln!("Erro ao contar usuários: {:?}", e);
            return Ok(internal_server_error(
                "Erro interno do servidor",
                "DATABASE_ERROR",
            ));
        }
    };

    // Buscar usuários
    let users_query = format!(
        "SELECT * FROM users {} ORDER BY created_at DESC LIMIT $1 OFFSET $2",
        where_clause
    );

    let users_result = if let Some(search) = &search_param {
        sqlx::query_as(&users_query)
            .bind(per_page)
            .bind(offset)
            .bind(search)
            .fetch_all(pool.get_ref())
            .await
    } else {
        sqlx::query_as(&users_query)
            .bind(per_page)
            .bind(offset)
            .fetch_all(pool.get_ref())
            .await
    };

    let users: Vec<User> = match users_result {
        Ok(users_vec) => users_vec,
        Err(e) => {
            eprintln!("Erro ao buscar usuários: {:?}", e);
            return Ok(internal_server_error(
                "Erro interno do servidor",
                "DATABASE_ERROR",
            ));
        }
    };

    let total_pages = (total.0 as f64 / per_page as f64).ceil() as i64;
    let user_responses: Vec<UserResponse> = users.into_iter().map(UserResponse::from).collect();

    let response = UserListResponse {
        users: user_responses,
        total: total.0,
        page,
        per_page,
        total_pages,
    };

    Ok(HttpResponse::Ok().json(response))
}

// Buscar usuário por ID (protegida por JWT)
pub async fn get_user(
    pool: web::Data<PgPool>,
    path: web::Path<Uuid>,
    req: HttpRequest,
) -> Result<HttpResponse> {
    let user_id = path.into_inner();

    // Extrair claims do token JWT
    if let Some(claims) = get_claims_from_http_request(&req) {
        let requesting_user_id = claims.get_user_id().unwrap_or_default();

        // Verificar se usuário está tentando acessar seus próprios dados ou é admin
        if user_id != requesting_user_id && !claims.is_admin() {
            return Ok(forbidden_error(
                "Acesso negado. Você só pode ver seus próprios dados.",
                "ACCESS_DENIED",
            ));
        }
    }

    let user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = $1")
        .bind(user_id)
        .fetch_optional(pool.get_ref())
        .await;

    match user {
        Ok(Some(user)) => {
            let user_response = UserResponse::from(user);
            Ok(HttpResponse::Ok().json(user_response))
        }
        Ok(None) => Ok(not_found_error("Usuário não encontrado", "USER_NOT_FOUND")),
        Err(e) => {
            eprintln!("Erro ao buscar usuário: {:?}", e);
            Ok(internal_server_error(
                "Erro interno do servidor",
                "DATABASE_ERROR",
            ))
        }
    }
}

// Atualizar usuário (protegida por JWT)
pub async fn update_user(
    pool: web::Data<PgPool>,
    path: web::Path<Uuid>,
    user_data: web::Json<UpdateUserRequest>,
    req: HttpRequest,
) -> Result<HttpResponse> {
    let user_id = path.into_inner();

    // Extrair claims do token JWT
    if let Some(claims) = get_claims_from_http_request(&req) {
        let requesting_user_id = claims.get_user_id().unwrap_or_default();

        // Verificar se usuário está tentando atualizar seus próprios dados ou é admin
        if user_id != requesting_user_id && !claims.is_admin() {
            return Ok(forbidden_error(
                "Acesso negado. Você só pode atualizar seus próprios dados.",
                "ACCESS_DENIED",
            ));
        }

        // Verificar se usuário não-admin está tentando alterar role
        if let Some(ref new_role) = user_data.role {
            if !claims.is_admin() && *new_role != UserRole::User {
                return Ok(forbidden_error(
                    "Apenas administradores podem alterar roles de usuário.",
                    "ADMIN_REQUIRED",
                ));
            }
        }
    }

    // Verificar se usuário existe
    let existing_user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = $1")
        .bind(user_id)
        .fetch_optional(pool.get_ref())
        .await;

    let current_user = match existing_user {
        Ok(Some(user)) => user,
        Ok(None) => {
            return Ok(not_found_error("Usuário não encontrado", "USER_NOT_FOUND"));
        }
        Err(e) => {
            eprintln!("Erro ao buscar usuário: {:?}", e);
            return Ok(internal_server_error(
                "Erro interno do servidor",
                "DATABASE_ERROR",
            ));
        }
    };

    // Se email está sendo atualizado, verificar se não existe outro usuário com o mesmo email
    if let Some(ref email) = user_data.email {
        if email != &current_user.email {
            let email_exists =
                sqlx::query_as::<_, User>("SELECT * FROM users WHERE email = $1 AND id != $2")
                    .bind(email)
                    .bind(user_id)
                    .fetch_optional(pool.get_ref())
                    .await;

            match email_exists {
                Ok(Some(_)) => {
                    return Ok(bad_request_error(
                        "Email já está em uso por outro usuário",
                        "EMAIL_ALREADY_EXISTS",
                    ));
                }
                Ok(None) => {
                    // Email disponível
                }
                Err(e) => {
                    eprintln!("Erro ao verificar email: {:?}", e);
                    return Ok(internal_server_error(
                        "Erro interno do servidor",
                        "DATABASE_ERROR",
                    ));
                }
            }
        }
    }

    // Preparar dados para atualização
    let nome = user_data.nome.as_ref().unwrap_or(&current_user.nome);
    let email = user_data.email.as_ref().unwrap_or(&current_user.email);
    let role = user_data.role.as_ref().unwrap_or(&current_user.role);

    // Hash da nova senha se fornecida
    let senha = if let Some(ref new_password) = user_data.senha {
        match hash(new_password, DEFAULT_COST) {
            Ok(hashed) => hashed,
            Err(e) => {
                eprintln!("Erro ao fazer hash da senha: {:?}", e);
                return Ok(internal_server_error(
                    "Erro interno do servidor",
                    "PASSWORD_HASH_ERROR",
                ));
            }
        }
    } else {
        current_user.senha.clone()
    };

    let now = Utc::now();

    // Atualizar usuário
    let updated_user = sqlx::query_as::<_, User>(
        r#"
        UPDATE users
        SET nome = $1, email = $2, senha = $3, role = $4, updated_at = $5
        WHERE id = $6
        RETURNING *
        "#,
    )
    .bind(nome)
    .bind(email)
    .bind(&senha)
    .bind(role)
    .bind(now)
    .bind(user_id)
    .fetch_one(pool.get_ref())
    .await;

    match updated_user {
        Ok(user) => {
            let user_response = UserResponse::from(user);
            Ok(HttpResponse::Ok().json(serde_json::json!({
                "message": "Usuário atualizado com sucesso",
                "user": user_response
            })))
        }
        Err(e) => {
            eprintln!("Erro ao atualizar usuário: {:?}", e);
            Ok(internal_server_error(
                "Erro ao atualizar usuário",
                "DATABASE_ERROR",
            ))
        }
    }
}

// Alterar senha do usuário (protegida por JWT)
pub async fn change_password(
    pool: web::Data<PgPool>,
    path: web::Path<Uuid>,
    password_data: web::Json<ChangePasswordRequest>,
    req: HttpRequest,
) -> Result<HttpResponse> {
    let user_id = path.into_inner();

    // Extrair claims do token JWT
    if let Some(claims) = get_claims_from_http_request(&req) {
        let requesting_user_id = claims.get_user_id().unwrap_or_default();

        // Verificar se usuário está tentando alterar sua própria senha ou é admin
        if user_id != requesting_user_id && !claims.is_admin() {
            return Ok(forbidden_error(
                "Acesso negado. Você só pode alterar sua própria senha.",
                "ACCESS_DENIED",
            ));
        }
    }

    // Buscar usuário atual
    let current_user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = $1")
        .bind(user_id)
        .fetch_optional(pool.get_ref())
        .await;

    let user = match current_user {
        Ok(Some(user)) => user,
        Ok(None) => {
            return Ok(not_found_error("Usuário não encontrado", "USER_NOT_FOUND"));
        }
        Err(e) => {
            eprintln!("Erro ao buscar usuário: {:?}", e);
            return Ok(internal_server_error(
                "Erro interno do servidor",
                "DATABASE_ERROR",
            ));
        }
    };

    // Verificar senha atual
    let password_valid = match verify(&password_data.senha_atual, &user.senha) {
        Ok(valid) => valid,
        Err(e) => {
            eprintln!("Erro ao verificar senha: {:?}", e);
            return Ok(internal_server_error(
                "Erro interno do servidor",
                "PASSWORD_VERIFICATION_ERROR",
            ));
        }
    };

    if !password_valid {
        return Ok(bad_request_error(
            "Senha atual incorreta",
            "INVALID_PASSWORD",
        ));
    }

    // Hash da nova senha
    let new_password_hash = match hash(&password_data.senha_nova, DEFAULT_COST) {
        Ok(hashed) => hashed,
        Err(e) => {
            eprintln!("Erro ao fazer hash da senha: {:?}", e);
            return Ok(internal_server_error(
                "Erro interno do servidor",
                "PASSWORD_HASH_ERROR",
            ));
        }
    };

    let now = Utc::now();

    // Atualizar senha
    let result = sqlx::query("UPDATE users SET senha = $1, updated_at = $2 WHERE id = $3")
        .bind(&new_password_hash)
        .bind(now)
        .bind(user_id)
        .execute(pool.get_ref())
        .await;

    match result {
        Ok(_) => Ok(HttpResponse::Ok().json(serde_json::json!({
            "message": "Senha alterada com sucesso"
        }))),
        Err(e) => {
            eprintln!("Erro ao alterar senha: {:?}", e);
            Ok(internal_server_error(
                "Erro ao alterar senha",
                "DATABASE_ERROR",
            ))
        }
    }
}

// Deletar usuário (apenas admins)
pub async fn delete_user(
    pool: web::Data<PgPool>,
    path: web::Path<Uuid>,
    req: HttpRequest,
) -> Result<HttpResponse> {
    let user_id = path.into_inner();

    // Extrair claims do token JWT e verificar se é admin
    if let Some(claims) = get_claims_from_http_request(&req) {
        if !claims.is_admin() {
            return Ok(forbidden_error(
                "Acesso negado. Apenas administradores podem deletar usuários.",
                "ADMIN_REQUIRED",
            ));
        }
    }

    // Verificar se usuário existe
    let user_exists = sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = $1")
        .bind(user_id)
        .fetch_optional(pool.get_ref())
        .await;

    let _user = match user_exists {
        Ok(Some(user)) => user,
        Ok(None) => {
            return Ok(not_found_error("Usuário não encontrado", "USER_NOT_FOUND"));
        }
        Err(e) => {
            eprintln!("Erro ao buscar usuário: {:?}", e);
            return Ok(internal_server_error(
                "Erro interno do servidor",
                "DATABASE_ERROR",
            ));
        }
    };

    // Deletar usuário
    let result = sqlx::query("DELETE FROM users WHERE id = $1")
        .bind(user_id)
        .execute(pool.get_ref())
        .await;

    match result {
        Ok(_) => Ok(HttpResponse::Ok().json(serde_json::json!({
            "message": "Usuário deletado com sucesso"
        }))),
        Err(e) => {
            eprintln!("Erro ao deletar usuário: {:?}", e);
            Ok(internal_server_error(
                "Erro ao deletar usuário",
                "DATABASE_ERROR",
            ))
        }
    }
}

// Endpoint para obter dados do usuário logado
pub async fn get_current_user(pool: web::Data<PgPool>, req: HttpRequest) -> Result<HttpResponse> {
    // Extrair claims do token JWT
    if let Some(claims) = get_claims_from_http_request(&req) {
        let user_id = match claims.get_user_id() {
            Ok(id) => id,
            Err(_) => {
                return Ok(bad_request_error(
                    "ID de usuário inválido no token",
                    "INVALID_USER_ID",
                ));
            }
        };

        let user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE id = $1")
            .bind(user_id)
            .fetch_optional(pool.get_ref())
            .await;

        match user {
            Ok(Some(user)) => {
                let user_response = UserResponse::from(user);
                Ok(HttpResponse::Ok().json(user_response))
            }
            Ok(None) => Ok(not_found_error("Usuário não encontrado", "USER_NOT_FOUND")),
            Err(e) => {
                eprintln!("Erro ao buscar usuário atual: {:?}", e);
                Ok(internal_server_error(
                    "Erro interno do servidor",
                    "DATABASE_ERROR",
                ))
            }
        }
    } else {
        Ok(unauthorized_error(
            "Token JWT não encontrado",
            "TOKEN_MISSING",
        ))
    }
}

pub fn config(cfg: &mut web::ServiceConfig) {
    use crate::middleware::{admin_required, jwt_validator};
    use actix_web_httpauth::middleware::HttpAuthentication;

    cfg.service(
        web::scope("/users")
            .route("", web::post().to(register_user)) // POST /users - Criar usuário (público)
            .route("/register", web::post().to(register_user)) // POST /users/register - Alias para criar (público)
            .service(
                web::resource("/{id}/change-password")
                    .route(web::patch().to(change_password)) // PATCH /users/{id}/change-password (JWT)
                    .wrap(HttpAuthentication::bearer(jwt_validator)),
            )
            .service(
                web::scope("")
                    .wrap(HttpAuthentication::bearer(jwt_validator))
                    .route("/{id}", web::get().to(get_user)) // GET /users/{id} - Buscar usuário por ID (JWT)
                    .route("/{id}", web::put().to(update_user)), // PUT /users/{id} - Atualizar usuário (JWT)
            )
            .service(
                web::scope("")
                    .wrap(HttpAuthentication::bearer(admin_required))
                    .route("", web::get().to(list_users)) // GET /users - Listar usuários (Admin)
                    .route("/{id}", web::delete().to(delete_user)), // DELETE /users/{id} - Deletar usuário (Admin)
            )
            .service(
                web::resource("/me")
                    .route(web::get().to(get_current_user)) // GET /users/me - Dados do usuário logado (JWT)
                    .wrap(HttpAuthentication::bearer(jwt_validator)),
            ),
    );
}
