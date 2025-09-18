use actix_web::{
    dev::{ServiceRequest, ServiceResponse},
    Error, HttpResponse,
};
use actix_web_lab::middleware::Next;
use std::{
    collections::HashMap,
    net::IpAddr,
    sync::{Arc, Mutex},
    time::{Duration, Instant},
};

#[derive(Clone, Debug)]
pub struct RateLimitConfig {
    pub requests_per_minute: u32,
    pub burst_size: u32,
}

impl Default for RateLimitConfig {
    fn default() -> Self {
        Self {
            requests_per_minute: 60,
            burst_size: 10,
        }
    }
}

impl RateLimitConfig {
    pub fn new(requests_per_minute: u32, burst_size: u32) -> Self {
        Self {
            requests_per_minute,
            burst_size,
        }
    }

    #[allow(dead_code)]
    pub fn strict() -> Self {
        Self::new(30, 5)
    }

    #[allow(dead_code)]
    pub fn lenient() -> Self {
        Self::new(120, 20)
    }
}

#[derive(Debug)]
struct ClientState {
    tokens: u32,
    last_refill: Instant,
}

impl ClientState {
    fn new(burst_size: u32) -> Self {
        Self {
            tokens: burst_size,
            last_refill: Instant::now(),
        }
    }

    fn can_consume(&mut self, config: &RateLimitConfig) -> bool {
        self.refill_tokens(config);

        if self.tokens > 0 {
            self.tokens -= 1;
            true
        } else {
            false
        }
    }

    fn refill_tokens(&mut self, config: &RateLimitConfig) {
        let now = Instant::now();
        let time_passed = now.duration_since(self.last_refill);
        let seconds_passed = time_passed.as_secs_f64();

        let tokens_to_add = (seconds_passed * config.requests_per_minute as f64 / 60.0) as u32;

        if tokens_to_add > 0 {
            self.tokens = (self.tokens + tokens_to_add).min(config.burst_size);
            self.last_refill = now;
        }
    }

    fn time_until_next_token(&self, config: &RateLimitConfig) -> Duration {
        let seconds_per_token = 60.0 / config.requests_per_minute as f64;
        Duration::from_secs_f64(seconds_per_token)
    }
}

type ClientMap = Arc<Mutex<HashMap<IpAddr, ClientState>>>;

#[derive(Clone)]
pub struct RateLimiter {
    config: RateLimitConfig,
    clients: ClientMap,
}

impl RateLimiter {
    pub fn new(config: RateLimitConfig) -> Self {
        Self {
            config,
            clients: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    fn extract_ip(&self, req: &ServiceRequest) -> Option<IpAddr> {
        // Try x-forwarded-for first
        if let Some(forwarded_for) = req.headers().get("x-forwarded-for") {
            if let Ok(header_str) = forwarded_for.to_str() {
                if let Some(first_ip) = header_str.split(',').next() {
                    if let Ok(ip) = first_ip.trim().parse::<IpAddr>() {
                        return Some(ip);
                    }
                }
            }
        }

        // Try x-real-ip header
        if let Some(real_ip) = req.headers().get("x-real-ip") {
            if let Ok(header_str) = real_ip.to_str() {
                if let Ok(ip) = header_str.parse::<IpAddr>() {
                    return Some(ip);
                }
            }
        }

        // Fall back to peer address
        req.peer_addr().map(|addr| addr.ip())
    }

    fn is_rate_limited(&self, ip: IpAddr) -> (bool, Duration) {
        let mut clients = self.clients.lock().unwrap();

        let client_state = clients
            .entry(ip)
            .or_insert_with(|| ClientState::new(self.config.burst_size));

        if client_state.can_consume(&self.config) {
            (false, Duration::from_secs(0))
        } else {
            let retry_after = client_state.time_until_next_token(&self.config);
            (true, retry_after)
        }
    }
}

pub async fn rate_limit_middleware(
    req: ServiceRequest,
    next: Next<impl actix_web::body::MessageBody + 'static>,
) -> Result<ServiceResponse<actix_web::body::BoxBody>, Error> {
    // Get rate limiter from app data
    if let Some(limiter) = req.app_data::<RateLimiter>() {
        if let Some(client_ip) = limiter.extract_ip(&req) {
            let (is_limited, retry_after) = limiter.is_rate_limited(client_ip);

            if is_limited {
                let retry_after_secs = retry_after.as_secs();

                let response = HttpResponse::TooManyRequests()
                    .insert_header(("Retry-After", retry_after_secs.to_string()))
                    .insert_header((
                        "X-RateLimit-Limit",
                        limiter.config.requests_per_minute.to_string(),
                    ))
                    .insert_header(("X-RateLimit-Remaining", "0"))
                    .json(serde_json::json!({
                        "error": "Rate limit exceeded",
                        "message": format!("Too many requests. Limit: {} requests per minute", limiter.config.requests_per_minute),
                        "retry_after_seconds": retry_after_secs
                    }));

                return Ok(req.into_response(response));
            }
        }
    }

    next.call(req).await.map(|res| res.map_into_boxed_body())
}

// Convenience functions
#[allow(dead_code)]
pub fn strict_rate_limiter() -> RateLimiter {
    RateLimiter::new(RateLimitConfig::strict())
}

#[allow(dead_code)]
pub fn default_rate_limiter() -> RateLimiter {
    RateLimiter::new(RateLimitConfig::default())
}

#[allow(dead_code)]
pub fn lenient_rate_limiter() -> RateLimiter {
    RateLimiter::new(RateLimitConfig::lenient())
}

pub fn custom_rate_limiter(requests_per_minute: u32, burst_size: u32) -> RateLimiter {
    RateLimiter::new(RateLimitConfig::new(requests_per_minute, burst_size))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rate_limit_config() {
        let default = RateLimitConfig::default();
        assert_eq!(default.requests_per_minute, 60);
        assert_eq!(default.burst_size, 10);

        let strict = RateLimitConfig::strict();
        assert_eq!(strict.requests_per_minute, 30);
        assert_eq!(strict.burst_size, 5);

        let lenient = RateLimitConfig::lenient();
        assert_eq!(lenient.requests_per_minute, 120);
        assert_eq!(lenient.burst_size, 20);
    }

    #[test]
    fn test_client_state_token_bucket() {
        let config = RateLimitConfig::new(60, 5);
        let mut client = ClientState::new(config.burst_size);

        // Should allow burst_size requests immediately
        for _ in 0..config.burst_size {
            assert!(client.can_consume(&config));
        }

        // Next request should be denied
        assert!(!client.can_consume(&config));
    }

    #[test]
    fn test_rate_limiter_creation() {
        let limiter = custom_rate_limiter(100, 15);
        assert_eq!(limiter.config.requests_per_minute, 100);
        assert_eq!(limiter.config.burst_size, 15);
    }
}
