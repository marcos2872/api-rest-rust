use actix_web::HttpResponse;
use serde_json::json;

// Helper function to create standardized JSON error responses
pub fn create_json_error_response(
    status_code: u16,
    error: &str,
    message: &str,
    code: &str,
) -> HttpResponse {
    let json_body = json!({
        "error": error,
        "message": message,
        "code": code,
        "timestamp": chrono::Utc::now().to_rfc3339()
    });

    match status_code {
        400 => HttpResponse::BadRequest().json(json_body),
        401 => HttpResponse::Unauthorized().json(json_body),
        403 => HttpResponse::Forbidden().json(json_body),
        404 => HttpResponse::NotFound().json(json_body),
        422 => HttpResponse::UnprocessableEntity().json(json_body),
        429 => HttpResponse::TooManyRequests().json(json_body),
        500 => HttpResponse::InternalServerError().json(json_body),
        _ => HttpResponse::InternalServerError().json(json!({
            "error": "Internal Server Error",
            "message": "An unexpected error occurred",
            "code": "UNKNOWN_ERROR",
            "timestamp": chrono::Utc::now().to_rfc3339()
        })),
    }
}

// Common error response creators
pub fn unauthorized_error(message: &str, code: &str) -> HttpResponse {
    create_json_error_response(401, "Unauthorized", message, code)
}

pub fn forbidden_error(message: &str, code: &str) -> HttpResponse {
    create_json_error_response(403, "Forbidden", message, code)
}

pub fn bad_request_error(message: &str, code: &str) -> HttpResponse {
    create_json_error_response(400, "Bad Request", message, code)
}

pub fn not_found_error(message: &str, code: &str) -> HttpResponse {
    create_json_error_response(404, "Not Found", message, code)
}

pub fn internal_server_error(message: &str, code: &str) -> HttpResponse {
    create_json_error_response(500, "Internal Server Error", message, code)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_json_error_response() {
        let response =
            create_json_error_response(401, "Unauthorized", "Token expired", "TOKEN_EXPIRED");
        assert_eq!(response.status(), 401);
    }

    #[test]
    fn test_unauthorized_error() {
        let response = unauthorized_error("Token expired", "TOKEN_EXPIRED");
        assert_eq!(response.status(), 401);
    }

    #[test]
    fn test_forbidden_error() {
        let response = forbidden_error("Access denied", "ACCESS_DENIED");
        assert_eq!(response.status(), 403);
    }

    #[test]
    fn test_create_json_error_response_unknown_status() {
        let response = create_json_error_response(999, "Unknown", "Unknown error", "UNKNOWN");
        assert_eq!(response.status(), 500);
    }
}
