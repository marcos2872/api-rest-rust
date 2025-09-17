use actix_web::{web, App, HttpServer, middleware::Logger};
use dotenv::dotenv;
use std::env;

mod models;
mod handlers;
mod config;

use config::database::{create_pool, run_migrations};
use handlers::user_handler;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Carregar variáveis de ambiente do arquivo .env
    dotenv().ok();

    // Configurar logger
    env_logger::init();

    // Configurar conexão com o banco de dados
    let pool = create_pool().await.expect("Falha ao conectar com o banco de dados");

    // Executar migrações
    run_migrations(&pool).await.expect("Falha ao executar migrações");

    // Configurar servidor
    let host = env::var("SERVER_HOST").unwrap_or_else(|_| "127.0.0.1".to_string());
    let port = env::var("SERVER_PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse::<u16>()
        .expect("PORT deve ser um número válido");

    println!("🚀 Servidor rodando em http://{}:{}", host, port);

    HttpServer::new(move || {
        App::new()
            .app_data(web::Data::new(pool.clone()))
            .wrap(Logger::default())
            .service(
                web::scope("/api/v1")
                    .configure(user_handler::config)
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
