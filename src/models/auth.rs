use chrono::{DateTime, Utc};
use jsonwebtoken::{DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use super::UserRole;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,    // Subject (user ID)
    pub email: String,  // Email do usuário
    pub nome: String,   // Nome do usuário
    pub role: UserRole, // Role do usuário
    pub iat: i64,       // Issued at (timestamp)
    pub exp: i64,       // Expiration time (timestamp)
}

impl Claims {
    pub fn new(
        user_id: Uuid,
        email: String,
        nome: String,
        role: UserRole,
        expires_in_seconds: i64,
    ) -> Self {
        let now = Utc::now().timestamp();
        Self {
            sub: user_id.to_string(),
            email,
            nome,
            role,
            iat: now,
            exp: now + expires_in_seconds,
        }
    }

    pub fn get_user_id(&self) -> Result<Uuid, uuid::Error> {
        Uuid::parse_str(&self.sub)
    }

    pub fn is_expired(&self) -> bool {
        Utc::now().timestamp() > self.exp
    }

    pub fn is_admin(&self) -> bool {
        matches!(self.role, UserRole::Admin)
    }
}

#[derive(Clone)]
pub struct JwtConfig {
    pub secret: String,
    pub expires_in_seconds: i64,
    pub encoding_key: EncodingKey,
    pub decoding_key: DecodingKey,
    pub validation: Validation,
}

impl std::fmt::Debug for JwtConfig {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("JwtConfig")
            .field("secret", &"[REDACTED]")
            .field("expires_in_seconds", &self.expires_in_seconds)
            .field("encoding_key", &"[REDACTED]")
            .field("decoding_key", &"[REDACTED]")
            .field("validation", &self.validation)
            .finish()
    }
}

impl JwtConfig {
    pub fn new(secret: String, expires_in_seconds: i64) -> Self {
        let encoding_key = EncodingKey::from_secret(secret.as_bytes());
        let decoding_key = DecodingKey::from_secret(secret.as_bytes());
        let validation = Validation::default();

        Self {
            secret,
            expires_in_seconds,
            encoding_key,
            decoding_key,
            validation,
        }
    }

    pub fn generate_token(&self, claims: &Claims) -> Result<String, jsonwebtoken::errors::Error> {
        jsonwebtoken::encode(&Header::default(), claims, &self.encoding_key)
    }

    pub fn verify_token(&self, token: &str) -> Result<Claims, jsonwebtoken::errors::Error> {
        let token_data =
            jsonwebtoken::decode::<Claims>(token, &self.decoding_key, &self.validation)?;
        Ok(token_data.claims)
    }
}

#[derive(Debug, Serialize)]
pub struct TokenInfo {
    pub user_id: Uuid,
    pub email: String,
    pub nome: String,
    pub role: UserRole,
    pub expires_at: DateTime<Utc>,
}

impl From<Claims> for TokenInfo {
    fn from(claims: Claims) -> Self {
        Self {
            user_id: claims.get_user_id().unwrap_or_default(),
            email: claims.email,
            nome: claims.nome,
            role: claims.role,
            expires_at: DateTime::from_timestamp(claims.exp, 0).unwrap_or_else(Utc::now),
        }
    }
}
