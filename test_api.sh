#!/bin/bash

# =============================================================================
# API REST Rust - Comprehensive Test Script
# =============================================================================
#
# This script tests all endpoints of the API REST Rust with authentication:
# - Health check
# - Authentication (login, token verification, refresh)
# - User CRUD operations with Bearer token protection
# - Role-based access control (USER vs ADMIN)
# - Error handling and validation
#
# REQUIREMENTS:
# - Server must be running (make run or cargo run)
# - curl, grep, cut commands available
# - Optional: python3 for better JSON parsing
#
# USAGE:
#   ./test_api.sh
#   make api-test
#
# FEATURES TESTED:
# ✅ 26+ test scenarios
# ✅ JWT Bearer token authentication
# ✅ Role-based authorization
# ✅ CRUD operations with proper permissions
# ✅ Error cases and edge scenarios
#
# =============================================================================

BASE_URL="http://localhost:8080"
JWT_TOKEN=""
USER_ID=""
ADMIN_TOKEN=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check dependencies
check_dependencies() {
    local missing_deps=0

    if ! command -v curl >/dev/null 2>&1; then
        echo "❌ curl is required but not installed."
        missing_deps=1
    fi

    if ! command -v grep >/dev/null 2>&1; then
        echo "❌ grep is required but not installed."
        missing_deps=1
    fi

    if ! command -v cut >/dev/null 2>&1; then
        echo "❌ cut is required but not installed."
        missing_deps=1
    fi

    if [ $missing_deps -eq 1 ]; then
        echo "Please install the missing dependencies and try again."
        exit 1
    fi
}

# Check if server is running
check_server() {
    if ! curl -s "$BASE_URL/health" >/dev/null 2>&1; then
        echo "❌ Server is not running at $BASE_URL"
        echo "Please start the server with 'make run' or 'cargo run' and try again."
        exit 1
    fi
}

# Diagnostic function to help troubleshoot issues
run_diagnostics() {
    echo ""
    print_info "🔍 Running diagnostics..."

    # Check server status
    if curl -s "$BASE_URL/health" >/dev/null 2>&1; then
        print_status 0 "Server connectivity: OK"
    else
        print_status 1 "Server connectivity: FAILED"
        echo "  Try: make run (in another terminal)"
        return 1
    fi

    # Check database connection (via health endpoint response)
    local health_response=$(curl -s "$BASE_URL/health" 2>/dev/null)
    if echo "$health_response" | grep -q "API está funcionando"; then
        print_status 0 "API health check: OK"
    else
        print_status 1 "API health check: Unexpected response"
        echo "  Response: $health_response"
    fi

    # Test admin login
    local login_test=$(curl -s -w "%{http_code}" -o /dev/null \
        -X POST "$BASE_URL/api/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"email":"admin@sistema.com","senha":"admin123"}' 2>/dev/null)

    if [ "${login_test: -3}" = "200" ]; then
        print_status 0 "Admin login endpoint: OK"
    else
        print_status 1 "Admin login endpoint: FAILED (HTTP ${login_test: -3})"
        echo "  Try: make migrate (to create admin user)"
    fi

    # Check JSON parsing tools
    if command -v python3 >/dev/null 2>&1; then
        print_status 0 "JSON parsing (python3): Available"
    elif command -v jq >/dev/null 2>&1; then
        print_status 0 "JSON parsing (jq): Available"
    else
        print_status 1 "JSON parsing tools: Missing (install python3 or jq)"
        echo "  Try: apt install python3 (or jq)"
    fi

    echo ""
}

# Run dependency checks
check_dependencies
check_server

# Run diagnostics if --diagnose flag is passed
if [ "$1" = "--diagnose" ] || [ "$1" = "-d" ]; then
    run_diagnostics
    exit 0
fi

echo "🧪 Testing API REST Rust with Authentication"
echo "=============================================="
echo ""
print_info "💡 Tip: Run './test_api.sh --diagnose' for troubleshooting help"

# Test 1: Health check
echo ""
print_info "Test 1: Health check"
response=$(curl -s -w "%{http_code}" -o /tmp/health_response.json "$BASE_URL/health")
http_code="${response: -3}"

if [ "$http_code" -eq 200 ]; then
    print_status 0 "Health check passed (HTTP $http_code)"
    echo "Response: $(cat /tmp/health_response.json)"
else
    print_status 1 "Health check failed (HTTP $http_code)"
    echo "Response: $(cat /tmp/health_response.json 2>/dev/null || echo 'No response')"
fi

# Test 2: Login with admin user
echo ""
print_info "Test 2: Login with admin user"
admin_login_data='{
    "email": "admin@sistema.com",
    "senha": "admin123"
}'

response=$(curl -s -w "%{http_code}" -o /tmp/admin_login_response.json \
    -X POST "$BASE_URL/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -d "$admin_login_data")
http_code="${response: -3}"

if [ "$http_code" -eq 200 ]; then
    print_status 0 "Admin login passed (HTTP $http_code)"
    echo "Response: $(cat /tmp/admin_login_response.json)"
    # Extract admin token for later tests
    ADMIN_TOKEN=$(cat /tmp/admin_login_response.json | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])" 2>/dev/null || \
                  cat /tmp/admin_login_response.json | grep -o '"token":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "")
    if [ -n "$ADMIN_TOKEN" ]; then
        echo "Admin Token: ${ADMIN_TOKEN:0:50}..."
    else
        echo "⚠️ Failed to extract Admin Token - some tests may be skipped"
    fi
else
    print_status 1 "Admin login failed (HTTP $http_code)"
    echo "Response: $(cat /tmp/admin_login_response.json 2>/dev/null || echo 'No response')"
fi

# Test 3: Register new user
echo ""
print_info "Test 3: Register new user"
user_data='{
    "nome": "João Silva",
    "email": "joao.silva@exemplo.com",
    "senha": "minhasenha123"
}'

response=$(curl -s -w "%{http_code}" -o /tmp/register_response.json \
    -X POST "$BASE_URL/api/v1/users/register" \
    -H "Content-Type: application/json" \
    -d "$user_data")
http_code="${response: -3}"

if [ "$http_code" -eq 201 ]; then
    print_status 0 "User registration passed (HTTP $http_code)"
    echo "Response: $(cat /tmp/register_response.json)"
    # Extract user ID for later tests
    USER_ID=$(cat /tmp/register_response.json | python3 -c "import sys, json; print(json.load(sys.stdin)['user']['id'])" 2>/dev/null || \
              cat /tmp/register_response.json | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || echo "")
    if [ -n "$USER_ID" ]; then
        echo "User ID: $USER_ID"
    else
        echo "⚠️ Failed to extract User ID - some tests may be skipped"
    fi
else
    print_status 1 "User registration failed (HTTP $http_code)"
    echo "Response: $(cat /tmp/register_response.json 2>/dev/null || echo 'No response')"
fi

# Test 4: Login with new user
echo ""
print_info "Test 4: Login with new user"
user_login_data='{
    "email": "joao.silva@exemplo.com",
    "senha": "minhasenha123"
}'

response=$(curl -s -w "%{http_code}" -o /tmp/user_login_response.json \
    -X POST "$BASE_URL/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -d "$user_login_data")
http_code="${response: -3}"

if [ "$http_code" -eq 200 ]; then
    print_status 0 "User login passed (HTTP $http_code)"
    echo "Response: $(cat /tmp/user_login_response.json)"
    # Extract user token for later tests
    JWT_TOKEN=$(cat /tmp/user_login_response.json | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])" 2>/dev/null || \
                cat /tmp/user_login_response.json | grep -o '"token":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "")
    if [ -n "$JWT_TOKEN" ]; then
        echo "User Token: ${JWT_TOKEN:0:50}..."
    else
        echo "⚠️ Failed to extract User Token - some tests may be skipped"
    fi
else
    print_status 1 "User login failed (HTTP $http_code)"
    echo "Response: $(cat /tmp/user_login_response.json 2>/dev/null || echo 'No response')"
fi

# Test 5: Try to login with invalid credentials (should fail)
echo ""
print_info "Test 5: Try to login with invalid credentials (should fail)"
invalid_login_data='{
    "email": "joao.silva@exemplo.com",
    "senha": "senhaerrada"
}'

response=$(curl -s -w "%{http_code}" -o /tmp/invalid_login_response.json \
    -X POST "$BASE_URL/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -d "$invalid_login_data")
http_code="${response: -3}"

if [ "$http_code" -eq 401 ]; then
    print_status 0 "Invalid login validation passed (HTTP $http_code)"
    echo "Response: $(cat /tmp/invalid_login_response.json)"
else
    print_status 1 "Invalid login validation failed - expected HTTP 401, got HTTP $http_code"
    echo "Response: $(cat /tmp/invalid_login_response.json 2>/dev/null || echo 'No response')"
fi

# Test 6: Verify JWT token
echo ""
print_info "Test 6: Verify JWT token"
if [ -n "$JWT_TOKEN" ]; then
    response=$(curl -s -w "%{http_code}" -o /tmp/verify_token_response.json \
        "$BASE_URL/api/v1/auth/verify/$JWT_TOKEN")
    http_code="${response: -3}"

    if [ "$http_code" -eq 200 ]; then
        print_status 0 "Token verification passed (HTTP $http_code)"
        echo "Response: $(cat /tmp/verify_token_response.json)"
    else
        print_status 1 "Token verification failed (HTTP $http_code)"
        echo "Response: $(cat /tmp/verify_token_response.json 2>/dev/null || echo 'No response')"
    fi
else
    print_status 1 "Token verification skipped - no token available"
fi

# Test 7: Try to register user with same email (should fail)
echo ""
print_info "Test 7: Register user with duplicate email (should fail)"
response=$(curl -s -w "%{http_code}" -o /tmp/duplicate_response.json \
    -X POST "$BASE_URL/api/v1/users/register" \
    -H "Content-Type: application/json" \
    -d "$user_data")
http_code="${response: -3}"

if [ "$http_code" -eq 400 ]; then
    print_status 0 "Duplicate email validation passed (HTTP $http_code)"
    echo "Response: $(cat /tmp/duplicate_response.json)"
else
    print_status 1 "Duplicate email validation failed - expected HTTP 400, got HTTP $http_code"
    echo "Response: $(cat /tmp/duplicate_response.json 2>/dev/null || echo 'No response')"
fi

# Test 8: Register another user
echo ""
print_info "Test 8: Register another user"
user_data2='{
    "nome": "Maria Santos",
    "email": "maria.santos@exemplo.com",
    "senha": "outrasenha456"
}'

response=$(curl -s -w "%{http_code}" -o /tmp/register2_response.json \
    -X POST "$BASE_URL/api/v1/users/register" \
    -H "Content-Type: application/json" \
    -d "$user_data2")
http_code="${response: -3}"

if [ "$http_code" -eq 201 ]; then
    print_status 0 "Second user registration passed (HTTP $http_code)"
    echo "Response: $(cat /tmp/register2_response.json)"
    # Extract second user ID for later tests
    USER_ID2=$(cat /tmp/register2_response.json | python3 -c "import sys, json; print(json.load(sys.stdin)['user']['id'])" 2>/dev/null || \
               cat /tmp/register2_response.json | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null || echo "")
    if [ -n "$USER_ID2" ]; then
        echo "User ID2: $USER_ID2"
    else
        echo "⚠️ Failed to extract User ID2 - some tests may be skipped"
    fi
else
    print_status 1 "Second user registration failed (HTTP $http_code)"
    echo "Response: $(cat /tmp/register2_response.json 2>/dev/null || echo 'No response')"
fi

# Test 9: List all users
echo ""
print_info "Test 9: List all users"
response=$(curl -s -w "%{http_code}" -o /tmp/list_users_response.json \
    "$BASE_URL/api/v1/users")
http_code="${response: -3}"

if [ "$http_code" -eq 200 ]; then
    print_status 0 "List users passed (HTTP $http_code)"
    echo "Response: $(cat /tmp/list_users_response.json)"
else
    print_status 1 "List users failed (HTTP $http_code)"
    echo "Response: $(cat /tmp/list_users_response.json 2>/dev/null || echo 'No response')"
fi

# Test 10: List users with pagination
echo ""
print_info "Test 10: List users with pagination"
response=$(curl -s -w "%{http_code}" -o /tmp/list_paginated_response.json \
    "$BASE_URL/api/v1/users?page=1&per_page=1")
http_code="${response: -3}"

if [ "$http_code" -eq 200 ]; then
    print_status 0 "List users with pagination passed (HTTP $http_code)"
    echo "Response: $(cat /tmp/list_paginated_response.json)"
else
    print_status 1 "List users with pagination failed (HTTP $http_code)"
    echo "Response: $(cat /tmp/list_paginated_response.json 2>/dev/null || echo 'No response')"
fi

# Test 11: Get current user data with JWT token
echo ""
print_info "Test 11: Get current user data with JWT token"
if [ -n "$JWT_TOKEN" ]; then
    response=$(curl -s -w "%{http_code}" -o /tmp/get_current_user_response.json \
        -H "Authorization: Bearer $JWT_TOKEN" \
        "$BASE_URL/api/v1/users/me")
    http_code="${response: -3}"

    if [ "$http_code" -eq 200 ]; then
        print_status 0 "Get current user data passed (HTTP $http_code)"
        echo "Response: $(cat /tmp/get_current_user_response.json)"
    else
        print_status 1 "Get current user data failed (HTTP $http_code)"
        echo "Response: $(cat /tmp/get_current_user_response.json 2>/dev/null || echo 'No response')"
    fi
else
    print_status 1 "Get current user data skipped - no JWT token available"
fi

# Test 12: Get specific user by ID with JWT token
echo ""
print_info "Test 12: Get user by ID with JWT token"
if [ -n "$USER_ID" ] && [ -n "$JWT_TOKEN" ]; then
    response=$(curl -s -w "%{http_code}" -o /tmp/get_user_response.json \
        -H "Authorization: Bearer $JWT_TOKEN" \
        "$BASE_URL/api/v1/users/$USER_ID")
    http_code="${response: -3}"

    if [ "$http_code" -eq 200 ]; then
        print_status 0 "Get user by ID with JWT passed (HTTP $http_code)"
        echo "Response: $(cat /tmp/get_user_response.json)"
    else
        print_status 1 "Get user by ID with JWT failed (HTTP $http_code)"
        echo "Response: $(cat /tmp/get_user_response.json 2>/dev/null || echo 'No response')"
    fi
else
    print_status 1 "Get user by ID with JWT skipped - no user ID or JWT token available"
fi

# Test 13: Try to get user without JWT token (should fail)
echo ""
print_info "Test 13: Try to get user without JWT token (should fail)"
if [ -n "$USER_ID" ]; then
    response=$(curl -s -w "%{http_code}" -o /tmp/get_user_no_auth_response.json \
        "$BASE_URL/api/v1/users/$USER_ID")
    http_code="${response: -3}"

    if [ "$http_code" -eq 401 ]; then
        print_status 0 "Unauthorized access validation passed (HTTP $http_code)"
        echo "Response: $(cat /tmp/get_user_no_auth_response.json)"
    else
        print_status 1 "Unauthorized access validation failed - expected HTTP 401, got HTTP $http_code"
        echo "Response: $(cat /tmp/get_user_no_auth_response.json 2>/dev/null || echo 'No response')"
    fi
else
    print_status 1 "Unauthorized access test skipped - no user ID available"
fi

# Test 14: Update user with JWT token
echo ""
print_info "Test 14: Update user with JWT token"
if [ -n "$USER_ID" ] && [ -n "$JWT_TOKEN" ]; then
    update_data='{
        "nome": "João Silva Santos",
        "email": "joao.santos@exemplo.com"
    }'

    response=$(curl -s -w "%{http_code}" -o /tmp/update_user_response.json \
        -X PUT "$BASE_URL/api/v1/users/$USER_ID" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -d "$update_data")
    http_code="${response: -3}"

    if [ "$http_code" -eq 200 ]; then
        print_status 0 "Update user with JWT passed (HTTP $http_code)"
        echo "Response: $(cat /tmp/update_user_response.json)"
    else
        print_status 1 "Update user with JWT failed (HTTP $http_code)"
        echo "Response: $(cat /tmp/update_user_response.json 2>/dev/null || echo 'No response')"
    fi
else
    print_status 1 "Update user with JWT skipped - no user ID or JWT token available"
fi

# Test 15: Try to update user without JWT token (should fail)
echo ""
print_info "Test 15: Try to update user without JWT token (should fail)"
if [ -n "$USER_ID" ]; then
    update_data='{
        "nome": "Tentativa Sem Auth"
    }'

    response=$(curl -s -w "%{http_code}" -o /tmp/update_user_no_auth_response.json \
        -X PUT "$BASE_URL/api/v1/users/$USER_ID" \
        -H "Content-Type: application/json" \
        -d "$update_data")
    http_code="${response: -3}"

    if [ "$http_code" -eq 401 ]; then
        print_status 0 "Update user without auth validation passed (HTTP $http_code)"
        echo "Response: $(cat /tmp/update_user_no_auth_response.json)"
    else
        print_status 1 "Update user without auth validation failed - expected HTTP 401, got HTTP $http_code"
        echo "Response: $(cat /tmp/update_user_no_auth_response.json 2>/dev/null || echo 'No response')"
    fi
else
    print_status 1 "Update user without auth test skipped - no user ID available"
fi

# Test 16: Change password with JWT token
echo ""
print_info "Test 16: Change password with JWT token"
if [ -n "$USER_ID" ] && [ -n "$JWT_TOKEN" ]; then
    password_data='{
        "senha_atual": "minhasenha123",
        "senha_nova": "novasenha456"
    }'

    response=$(curl -s -w "%{http_code}" -o /tmp/change_password_response.json \
        -X PATCH "$BASE_URL/api/v1/users/$USER_ID/change-password" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $JWT_TOKEN" \
        -d "$password_data")
    http_code="${response: -3}"

    if [ "$http_code" -eq 200 ]; then
        print_status 0 "Change password with JWT passed (HTTP $http_code)"
        echo "Response: $(cat /tmp/change_password_response.json)"
    else
        print_status 1 "Change password with JWT failed (HTTP $http_code)"
        echo "Response: $(cat /tmp/change_password_response.json 2>/dev/null || echo 'No response')"
    fi
else
    print_status 1 "Change password with JWT skipped - no user ID or JWT token available"
fi

# Test 17: Try to access user data with invalid token (should fail)
echo ""
print_info "Test 17: Try to access user data with invalid token (should fail)"
if [ -n "$USER_ID" ]; then
    invalid_token="invalid.jwt.token"

    response=$(curl -s -w "%{http_code}" -o /tmp/invalid_token_response.json \
        -H "Authorization: Bearer $invalid_token" \
        "$BASE_URL/api/v1/users/me")
    http_code="${response: -3}"

    if [ "$http_code" -eq 401 ]; then
        print_status 0 "Invalid token validation passed (HTTP $http_code)"
        echo "Response: $(cat /tmp/invalid_token_response.json)"
    else
        print_status 1 "Invalid token validation failed - expected HTTP 401, got HTTP $http_code"
        echo "Response: $(cat /tmp/invalid_token_response.json 2>/dev/null || echo 'No response')"
    fi
else
    print_status 1 "Invalid token test skipped - no user ID available"
fi

# Test 18: Search users
echo ""
print_info "Test 18: Search users"
response=$(curl -s -w "%{http_code}" -o /tmp/search_users_response.json \
    "$BASE_URL/api/v1/users?search=João")
http_code="${response: -3}"

if [ "$http_code" -eq 200 ]; then
    print_status 0 "Search users passed (HTTP $http_code)"
    echo "Response: $(cat /tmp/search_users_response.json)"
else
    print_status 1 "Search users failed (HTTP $http_code)"
    echo "Response: $(cat /tmp/search_users_response.json 2>/dev/null || echo 'No response')"
fi

# Test 19: Get non-existent user (should fail)
echo ""
print_info "Test 19: Get non-existent user (should fail)"
fake_id="550e8400-e29b-41d4-a716-446655440000"
response=$(curl -s -w "%{http_code}" -o /tmp/get_fake_user_response.json \
    -H "Authorization: Bearer $JWT_TOKEN" \
    "$BASE_URL/api/v1/users/$fake_id")
http_code="${response: -3}"

if [ "$http_code" -eq 404 ]; then
    print_status 0 "Get non-existent user validation passed (HTTP $http_code)"
    echo "Response: $(cat /tmp/get_fake_user_response.json)"
else
    print_status 1 "Get non-existent user validation failed - expected HTTP 404, got HTTP $http_code"
    echo "Response: $(cat /tmp/get_fake_user_response.json 2>/dev/null || echo 'No response')"
fi

# Test 20: Delete user with admin token
echo ""
print_info "Test 20: Delete user with admin token"
if [ -n "$USER_ID2" ] && [ -n "$ADMIN_TOKEN" ]; then
    response=$(curl -s -w "%{http_code}" -o /tmp/delete_user_response.json \
        -X DELETE "$BASE_URL/api/v1/users/$USER_ID2" \
        -H "Authorization: Bearer $ADMIN_TOKEN")
    http_code="${response: -3}"

    if [ "$http_code" -eq 200 ]; then
        print_status 0 "Delete user with admin token passed (HTTP $http_code)"
        echo "Response: $(cat /tmp/delete_user_response.json)"
    else
        print_status 1 "Delete user with admin token failed (HTTP $http_code)"
        echo "Response: $(cat /tmp/delete_user_response.json 2>/dev/null || echo 'No response')"
    fi
else
    print_status 1 "Delete user with admin token skipped - no user ID or admin token available"
fi

# Test 21: Try to delete user with regular user token (should fail)
echo ""
print_info "Test 21: Try to delete user with regular user token (should fail)"
if [ -n "$USER_ID" ] && [ -n "$JWT_TOKEN" ]; then
    response=$(curl -s -w "%{http_code}" -o /tmp/delete_user_forbidden_response.json \
        -X DELETE "$BASE_URL/api/v1/users/$USER_ID" \
        -H "Authorization: Bearer $JWT_TOKEN")
    http_code="${response: -3}"

    if [ "$http_code" -eq 403 ]; then
        print_status 0 "Delete user forbidden validation passed (HTTP $http_code)"
        echo "Response: $(cat /tmp/delete_user_forbidden_response.json)"
    else
        print_status 1 "Delete user forbidden validation failed - expected HTTP 403, got HTTP $http_code"
        echo "Response: $(cat /tmp/delete_user_forbidden_response.json 2>/dev/null || echo 'No response')"
    fi
else
    print_status 1 "Delete user forbidden test skipped - no user ID or JWT token available"
fi

# Test 22: Try to delete already deleted user (should fail)
echo ""
print_info "Test 22: Try to delete already deleted user (should fail)"
if [ -n "$USER_ID2" ] && [ -n "$ADMIN_TOKEN" ]; then
    response=$(curl -s -w "%{http_code}" -o /tmp/delete_deleted_user_response.json \
        -X DELETE "$BASE_URL/api/v1/users/$USER_ID2" \
        -H "Authorization: Bearer $ADMIN_TOKEN")
    http_code="${response: -3}"

    if [ "$http_code" -eq 404 ]; then
        print_status 0 "Delete non-existent user validation passed (HTTP $http_code)"
        echo "Response: $(cat /tmp/delete_deleted_user_response.json)"
    else
        print_status 1 "Delete non-existent user validation failed - expected HTTP 404, got HTTP $http_code"
        echo "Response: $(cat /tmp/delete_deleted_user_response.json 2>/dev/null || echo 'No response')"
    fi
else
    print_status 1 "Delete non-existent user skipped - no user ID or admin token available"
fi

# Test 23: Invalid JSON (should fail)
echo ""
print_info "Test 23: Send invalid JSON (should fail)"
invalid_data='{"nome": "Test", "email": "invalid"'

response=$(curl -s -w "%{http_code}" -o /tmp/invalid_response.json \
    -X POST "$BASE_URL/api/v1/users/register" \
    -H "Content-Type: application/json" \
    -d "$invalid_data")
http_code="${response: -3}"

if [ "$http_code" -eq 400 ] || [ "$http_code" -eq 422 ]; then
    print_status 0 "Invalid JSON validation passed (HTTP $http_code)"
    echo "Response: $(cat /tmp/invalid_response.json)"
else
    print_status 1 "Invalid JSON validation failed - expected HTTP 400/422, got HTTP $http_code"
    echo "Response: $(cat /tmp/invalid_response.json 2>/dev/null || echo 'No response')"
fi

# Test 24: Missing fields (should fail)
echo ""
print_info "Test 24: Send incomplete data (should fail)"
incomplete_data='{
    "nome": "Test User"
}'

response=$(curl -s -w "%{http_code}" -o /tmp/incomplete_response.json \
    -X POST "$BASE_URL/api/v1/users/register" \
    -H "Content-Type: application/json" \
    -d "$incomplete_data")
http_code="${response: -3}"

if [ "$http_code" -eq 400 ] || [ "$http_code" -eq 422 ]; then
    print_status 0 "Incomplete data validation passed (HTTP $http_code)"
    echo "Response: $(cat /tmp/incomplete_response.json)"
else
    print_status 1 "Incomplete data validation failed - expected HTTP 400/422, got HTTP $http_code"
    echo "Response: $(cat /tmp/incomplete_response.json 2>/dev/null || echo 'No response')"
fi

# Test 25: Try to access user data with expired/malformed token (should fail)
echo ""
print_info "Test 25: Try to access user data with malformed Bearer token (should fail)"
malformed_token="Bearer invalid.jwt.token.here"

response=$(curl -s -w "%{http_code}" -o /tmp/malformed_token_response.json \
    -H "Authorization: $malformed_token" \
    "$BASE_URL/api/v1/users/me")
http_code="${response: -3}"

if [ "$http_code" -eq 401 ]; then
    print_status 0 "Malformed Bearer token validation passed (HTTP $http_code)"
    echo "Response: $(cat /tmp/malformed_token_response.json)"
else
    print_status 1 "Malformed Bearer token validation failed - expected HTTP 401, got HTTP $http_code"
    echo "Response: $(cat /tmp/malformed_token_response.json 2>/dev/null || echo 'No response')"
fi

# Test 26: Try to access admin-only route with regular user token (should fail)
echo ""
print_info "Test 26: Try to delete user with regular user token (should fail)"
if [ -n "$JWT_TOKEN" ] && [ -n "$USER_ID2" ]; then
    response=$(curl -s -w "%{http_code}" -o /tmp/regular_user_delete_response.json \
        -X DELETE "$BASE_URL/api/v1/users/$USER_ID2" \
        -H "Authorization: Bearer $JWT_TOKEN")
    http_code="${response: -3}"

    if [ "$http_code" -eq 403 ]; then
        print_status 0 "Regular user admin access denied validation passed (HTTP $http_code)"
        echo "Response: $(cat /tmp/regular_user_delete_response.json)"
    else
        print_status 1 "Regular user admin access denied validation failed - expected HTTP 403, got HTTP $http_code"
        echo "Response: $(cat /tmp/regular_user_delete_response.json 2>/dev/null || echo 'No response')"
    fi
else
    print_status 1 "Regular user admin access test skipped - no JWT token or user ID available"
fi

echo ""
echo "=========================="
print_info "Test completed!"
print_warning "Remember to check your database to verify users were created correctly"
echo ""
print_info "To run the server: make run"
print_info "To check database: Connect to your PostgreSQL and run: SELECT id, nome, email, role FROM users;"
print_info "Default admin login: admin@sistema.com / admin123"
echo ""
print_info "📊 Summary of test results:"
if [ -n "$ADMIN_TOKEN" ]; then
    print_status 0 "Admin authentication: Working"
else
    print_status 1 "Admin authentication: Failed or token extraction failed"
fi
if [ -n "$JWT_TOKEN" ]; then
    print_status 0 "User authentication: Working"
else
    print_status 1 "User authentication: Failed or token extraction failed"
fi
if [ -n "$USER_ID" ]; then
    print_status 0 "User registration: Working"
else
    print_status 1 "User registration: Failed or ID extraction failed"
fi

echo ""
print_info "🔧 Need Help? Try these options:"
echo ""
echo "  🔍 Quick Diagnostics:"
echo "    ./test_api.sh --diagnose    # Run automated diagnostics"
echo ""
echo "  📊 Common Issues & Solutions:"
echo "    Token extraction fails → Install: apt install python3 jq"
echo "    Server not responding → Run: make run (in another terminal)"
echo "    Admin login fails → Run: make migrate"
echo "    Database issues → Run: make docker-up && make migrate"
echo ""
echo "  🧪 Manual Testing:"
echo "    # Test admin login"
echo "    curl -X POST http://localhost:8080/api/v1/auth/login \\"
echo "      -H 'Content-Type: application/json' \\"
echo "      -d '{\"email\":\"admin@sistema.com\",\"senha\":\"admin123\"}'"
echo ""
echo "    # Test authenticated endpoint (replace YOUR_TOKEN)"
echo "    curl -H 'Authorization: Bearer YOUR_TOKEN' \\"
echo "      http://localhost:8080/api/v1/users/me"
echo ""
echo "  📚 Documentation:"
echo "    README.md, AUTH.md, ROUTES.md, API_EXAMPLES.md"
echo ""
echo "  🐛 Debug Server:"
echo "    RUST_LOG=debug make run"

# Clean up temporary files
rm -f /tmp/health_response.json /tmp/register_response.json /tmp/duplicate_response.json
rm -f /tmp/register2_response.json /tmp/invalid_response.json /tmp/incomplete_response.json
rm -f /tmp/list_users_response.json /tmp/list_paginated_response.json /tmp/get_user_response.json
rm -f /tmp/update_user_response.json /tmp/change_password_response.json /tmp/search_users_response.json
rm -f /tmp/get_fake_user_response.json /tmp/delete_user_response.json /tmp/delete_deleted_user_response.json
rm -f /tmp/admin_login_response.json /tmp/user_login_response.json /tmp/invalid_login_response.json
rm -f /tmp/verify_token_response.json /tmp/get_current_user_response.json /tmp/get_user_no_auth_response.json
rm -f /tmp/update_user_no_auth_response.json /tmp/invalid_token_response.json /tmp/delete_user_forbidden_response.json
rm -f /tmp/malformed_token_response.json /tmp/regular_user_delete_response.json

echo ""
print_info "Temporary test files cleaned up"
