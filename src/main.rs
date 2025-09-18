use actix_web::{web, App, HttpServer};
use dotenv::dotenv;
use std::env;
use tracing_actix_web::TracingLogger;

mod config;
mod handlers;
mod middleware;
mod models;
mod telemetry;

use config::database::{create_pool, run_migrations};
use handlers::{auth_handler, user_handler};
use middleware::{custom_rate_limiter, rate_limit_middleware};
use models::JwtConfig;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Carregar variáveis de ambiente do arquivo .env
    dotenv().ok();

    // Inicializar telemetria (tracing e métricas)
    telemetry::init_telemetry();
    // env_logger::init();

    // Configurar conexão com o banco de dados
    let pool = create_pool()
        .await
        .expect("Falha ao conectar com o banco de dados");

    // Executar migrações
    run_migrations(&pool)
        .await
        .expect("Falha ao executar migrações");

    // Configurar JWT
    let jwt_secret = env::var("JWT_SECRET")
        .unwrap_or_else(|_| "your-secret-key-change-this-in-production".to_string());
    let jwt_expiration = env::var("JWT_EXPIRATION")
        .unwrap_or_else(|_| "3600".to_string())
        .parse::<i64>()
        .expect("JWT_EXPIRATION deve ser um número válido");

    let jwt_config = JwtConfig::new(jwt_secret, jwt_expiration);

    // Configurar rate limiting
    let rate_limit_rpm = env::var("RATE_LIMIT_RPM")
        .unwrap_or_else(|_| "60".to_string())
        .parse::<u32>()
        .expect("RATE_LIMIT_RPM deve ser um número válido");

    let rate_limit_burst = env::var("RATE_LIMIT_BURST")
        .unwrap_or_else(|_| "10".to_string())
        .parse::<u32>()
        .expect("RATE_LIMIT_BURST deve ser um número válido");

    let rate_limiter = custom_rate_limiter(rate_limit_rpm, rate_limit_burst);

    // Configurar servidor
    let host = env::var("SERVER_HOST").unwrap_or_else(|_| "127.0.0.1".to_string());
    let port = env::var("SERVER_PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse::<u16>()
        .expect("PORT deve ser um número válido");

    println!("🚀 Servidor rodando em http://{}:{}", host, port);
    println!(
        "🔑 JWT configurado com expiração de {} segundos",
        jwt_expiration
    );
    println!(
        "🚦 Rate limiting: {} requisições/minuto, burst de {}",
        rate_limit_rpm, rate_limit_burst
    );

    HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(pool.clone()))
            .app_data(web::Data::new(jwt_config.clone()))
            .app_data(rate_limiter.clone())
            .wrap(TracingLogger::default())
            .wrap(actix_web_lab::middleware::from_fn(rate_limit_middleware))
            .service(
                web::scope("/api/v1")
                    .configure(auth_handler::config)
                    .configure(user_handler::config),
            )
            .route("/health", web::get().to(health_check))
    })
    .bind((host, port))?
    .run()
    .await
}

async fn health_check() -> actix_web::Result<actix_web::HttpResponse> {
    Ok(actix_web::HttpResponse::Ok().json(serde_json::json!({
        "status": "ok",
        "message": "API está funcionando"
    })))
}
