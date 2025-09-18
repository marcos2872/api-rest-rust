use actix_web::{web, HttpResponse, Result};
use bcrypt::verify;
use chrono::{Duration, Utc};
use sqlx::PgPool;

use crate::models::{Claims, JwtConfig, LoginRequest, LoginResponse, User, UserResponse};

pub async fn login(
    pool: web::Data<PgPool>,
    jwt_config: web::Data<JwtConfig>,
    login_data: web::Json<LoginRequest>,
) -> Result<HttpResponse> {
    // Buscar usuário por email
    let user = sqlx::query_as::<_, User>("SELECT * FROM users WHERE email = $1")
        .bind(&login_data.email)
        .fetch_optional(pool.get_ref())
        .await;

    let user = match user {
        Ok(Some(user)) => user,
        Ok(None) => {
            return Ok(HttpResponse::Unauthorized().json(serde_json::json!({
                "error": "Credenciais inválidas"
            })));
        }
        Err(e) => {
            eprintln!("Erro ao buscar usuário: {:?}", e);
            return Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Erro interno do servidor"
            })));
        }
    };

    // Verificar senha
    let password_valid = match verify(&login_data.senha, &user.senha) {
        Ok(valid) => valid,
        Err(e) => {
            eprintln!("Erro ao verificar senha: {:?}", e);
            return Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Erro interno do servidor"
            })));
        }
    };

    if !password_valid {
        return Ok(HttpResponse::Unauthorized().json(serde_json::json!({
            "error": "Credenciais inválidas"
        })));
    }

    // Gerar JWT token
    let claims = Claims::new(
        user.id,
        user.email.clone(),
        user.nome.clone(),
        user.role.clone(),
        jwt_config.expires_in_seconds,
    );

    let token = match jwt_config.generate_token(&claims) {
        Ok(token) => token,
        Err(e) => {
            eprintln!("Erro ao gerar token: {:?}", e);
            return Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Erro interno do servidor"
            })));
        }
    };

    // Calcular data de expiração
    let expires_at = Utc::now() + Duration::seconds(jwt_config.expires_in_seconds);

    // Preparar resposta (sem a senha)
    let user_response = UserResponse::from(user);
    let login_response = LoginResponse {
        user: user_response,
        token,
        expires_at,
    };

    Ok(HttpResponse::Ok().json(login_response))
}

// Endpoint para verificar token (opcional)
pub async fn verify_token(
    jwt_config: web::Data<JwtConfig>,
    token: web::Path<String>,
) -> Result<HttpResponse> {
    let token = token.into_inner();

    match jwt_config.verify_token(&token) {
        Ok(claims) => {
            if claims.is_expired() {
                return Ok(HttpResponse::Unauthorized().json(serde_json::json!({
                    "error": "Token expirado"
                })));
            }

            Ok(HttpResponse::Ok().json(serde_json::json!({
                "valid": true,
                "user_id": claims.sub,
                "email": claims.email,
                "nome": claims.nome,
                "role": claims.role,
                "expires_at": claims.exp
            })))
        }
        Err(e) => {
            eprintln!("Erro ao verificar token: {:?}", e);
            Ok(HttpResponse::Unauthorized().json(serde_json::json!({
                "error": "Token inválido"
            })))
        }
    }
}

// Endpoint para refresh token (opcional)
pub async fn refresh_token(
    jwt_config: web::Data<JwtConfig>,
    old_token: web::Path<String>,
) -> Result<HttpResponse> {
    let token = old_token.into_inner();

    match jwt_config.verify_token(&token) {
        Ok(claims) => {
            // Gerar novo token com os mesmos dados mas nova expiração
            let new_claims = Claims::new(
                claims.get_user_id().unwrap_or_default(),
                claims.email,
                claims.nome,
                claims.role,
                jwt_config.expires_in_seconds,
            );

            match jwt_config.generate_token(&new_claims) {
                Ok(new_token) => {
                    let expires_at = Utc::now() + Duration::seconds(jwt_config.expires_in_seconds);

                    Ok(HttpResponse::Ok().json(serde_json::json!({
                        "token": new_token,
                        "expires_at": expires_at
                    })))
                }
                Err(e) => {
                    eprintln!("Erro ao gerar novo token: {:?}", e);
                    Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                        "error": "Erro interno do servidor"
                    })))
                }
            }
        }
        Err(e) => {
            eprintln!("Erro ao verificar token para refresh: {:?}", e);
            Ok(HttpResponse::Unauthorized().json(serde_json::json!({
                "error": "Token inválido para refresh"
            })))
        }
    }
}

pub fn config(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/auth")
            .route("/login", web::post().to(login))
            .route("/verify/{token}", web::get().to(verify_token))
            .route("/refresh/{token}", web::post().to(refresh_token)),
    );
}
