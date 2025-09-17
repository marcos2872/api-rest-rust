#!/bin/bash

# Test script for API REST Rust
# Make sure the server is running before executing this script

BASE_URL="http://localhost:8080"

echo "🧪 Testing API REST Rust"
echo "=========================="

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

# Test 2: Register new user
echo ""
print_info "Test 2: Register new user"
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
else
    print_status 1 "User registration failed (HTTP $http_code)"
    echo "Response: $(cat /tmp/register_response.json 2>/dev/null || echo 'No response')"
fi

# Test 3: Try to register user with same email (should fail)
echo ""
print_info "Test 3: Register user with duplicate email (should fail)"
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

# Test 4: Register another user
echo ""
print_info "Test 4: Register another user"
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
else
    print_status 1 "Second user registration failed (HTTP $http_code)"
    echo "Response: $(cat /tmp/register2_response.json 2>/dev/null || echo 'No response')"
fi

# Test 5: Invalid JSON (should fail)
echo ""
print_info "Test 5: Send invalid JSON (should fail)"
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

# Test 6: Missing fields (should fail)
echo ""
print_info "Test 6: Send incomplete data (should fail)"
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

echo ""
echo "=========================="
print_info "Test completed!"
print_warning "Remember to check your database to verify users were created correctly"
echo ""
print_info "To run the server: cargo run"
print_info "To check database: Connect to your PostgreSQL and run: SELECT * FROM users;"

# Clean up temporary files
rm -f /tmp/health_response.json /tmp/register_response.json /tmp/duplicate_response.json
rm -f /tmp/register2_response.json /tmp/invalid_response.json /tmp/incomplete_response.json

echo ""
print_info "Temporary test files cleaned up"
