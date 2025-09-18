use actix_web::{dev::ServiceRequest, Error, HttpMessage};
use actix_web_httpauth::extractors::bearer::{BearerAuth, Config};
use actix_web_httpauth::extractors::AuthenticationError;

use crate::models::{Claims, JwtConfig};

pub async fn jwt_validator(
    req: ServiceRequest,
    credentials: BearerAuth,
) -> Result<ServiceRequest, (Error, ServiceRequest)> {
    // Extrair configuração JWT do app data
    let jwt_config = match req.app_data::<actix_web::web::Data<JwtConfig>>() {
        Some(config) => config.get_ref(),
        None => {
            let config = Config::default().realm("Restricted area");
            return Err((AuthenticationError::from(config).into(), req));
        }
    };

    // Verificar token
    let token = credentials.token();

    match jwt_config.verify_token(token) {
        Ok(claims) => {
            // Verificar se token não expirou
            if claims.is_expired() {
                let config = Config::default()
                    .realm("Restricted area")
                    .scope("token expired");
                return Err((AuthenticationError::from(config).into(), req));
            }

            // Adicionar claims às extensões da requisição para uso posterior
            req.extensions_mut().insert(claims);
            Ok(req)
        }
        Err(_) => {
            let config = Config::default()
                .realm("Restricted area")
                .scope("invalid token");
            Err((AuthenticationError::from(config).into(), req))
        }
    }
}

// Helper para extrair claims da requisição
pub fn get_claims_from_request(req: &ServiceRequest) -> Option<Claims> {
    req.extensions().get::<Claims>().cloned()
}

// Helper para extrair claims do HttpRequest (para handlers)
pub fn get_claims_from_http_request(req: &actix_web::HttpRequest) -> Option<Claims> {
    req.extensions().get::<Claims>().cloned()
}

// Middleware para verificar se usuário é admin
pub async fn admin_required(
    req: ServiceRequest,
    credentials: BearerAuth,
) -> Result<ServiceRequest, (Error, ServiceRequest)> {
    // Primeiro, validar o JWT
    let req = match jwt_validator(req, credentials).await {
        Ok(req) => req,
        Err((err, req)) => return Err((err, req)),
    };

    // Verificar se usuário é admin
    if let Some(claims) = get_claims_from_request(&req) {
        if claims.is_admin() {
            Ok(req)
        } else {
            Err((Error::from(actix_web::error::ErrorForbidden("")), req))
        }
    } else {
        Err((
            Error::from(actix_web::error::ErrorInternalServerError(
                "Erro interno: claims não encontrados após a validação do token.".to_string(),
            )),
            req,
        ))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::{JwtConfig, UserRole};
    use uuid::Uuid;

    #[test]
    fn test_jwt_config() {
        let config = JwtConfig::new("test_secret".to_string(), 3600);

        let claims = Claims::new(
            Uuid::new_v4(),
            "test@example.com".to_string(),
            "Test User".to_string(),
            UserRole::User,
            3600,
        );

        let token = config.generate_token(&claims).unwrap();
        let verified_claims = config.verify_token(&token).unwrap();

        assert_eq!(claims.email, verified_claims.email);
        assert_eq!(claims.nome, verified_claims.nome);
        assert_eq!(claims.role, verified_claims.role);
    }
}
