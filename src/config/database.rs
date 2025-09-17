use sqlx::{postgres::PgPoolOptions, Pool, Postgres};
use std::env;
use anyhow::Result;

pub type DbPool = Pool<Postgres>;

pub async fn create_pool() -> Result<DbPool> {
    let database_url = env::var("DATABASE_URL")
        .expect("DATABASE_URL deve estar definida no arquivo .env");

    let pool = PgPoolOptions::new()
        .max_connections(10)
        .connect(&database_url)
        .await?;

    Ok(pool)
}

pub async fn run_migrations(pool: &DbPool) -> Result<()> {
    sqlx::migrate!("./migrations").run(pool).await?;
    Ok(())
}
