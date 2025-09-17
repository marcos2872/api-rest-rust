use actix_web::{web, HttpResponse, Result};
use sqlx::PgPool;
use uuid::Uuid;
use chrono::Utc;
use bcrypt::{hash, DEFAULT_COST};

use crate::models::{CreateUserRequest, User, UserResponse};

pub async fn register_user(
    pool: web::Data<PgPool>,
    user_data: web::Json<CreateUserRequest>,
) -> Result<HttpResponse> {
    // Verificar se o email já existe
    let existing_user = sqlx::query_as::<_, User>(
        "SELECT * FROM users WHERE email = $1"
    )
    .bind(&user_data.email)
    .fetch_optional(pool.get_ref())
    .await;

    match existing_user {
        Ok(Some(_)) => {
            return Ok(HttpResponse::BadRequest().json(serde_json::json!({
                "error": "Email já está em uso"
            })));
        }
        Ok(None) => {
            // Email disponível, continuar com o cadastro
        }
        Err(e) => {
            eprintln!("Erro ao verificar email: {:?}", e);
            return Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Erro interno do servidor"
            })));
        }
    }

    // Hash da senha
    let hashed_password = match hash(&user_data.senha, DEFAULT_COST) {
        Ok(hashed) => hashed,
        Err(e) => {
            eprintln!("Erro ao fazer hash da senha: {:?}", e);
            return Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Erro interno do servidor"
            })));
        }
    };

    // Criar novo usuário
    let new_user_id = Uuid::new_v4();
    let now = Utc::now();

    let result = sqlx::query_as::<_, User>(
        r#"
        INSERT INTO users (id, nome, email, senha, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING *
        "#
    )
    .bind(new_user_id)
    .bind(&user_data.nome)
    .bind(&user_data.email)
    .bind(&hashed_password)
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
            Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Erro ao criar usuário"
            })))
        }
    }
}

pub fn config(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/users")
            .route("/register", web::post().to(register_user))
    );
}
