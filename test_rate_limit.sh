#!/bin/bash

# =============================================================================
# Rate Limiting Test Script for API REST Rust
# =============================================================================
#
# This script tests the rate limiting functionality of the API.
# It sends multiple requests rapidly to trigger rate limiting.
#
# REQUIREMENTS:
# - Server must be running (make run)
# - curl command available
# - seq command available (for generating request sequences)
#
# USAGE:
#   ./test_rate_limit.sh
#
# =============================================================================

BASE_URL="http://localhost:8080"
CONCURRENT_REQUESTS=20
RATE_LIMIT_ENDPOINT="/health"

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

print_header() {
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}$(echo "$1" | sed 's/./=/g')${NC}"
}

# Check if server is running
check_server() {
    if ! curl -s "$BASE_URL/health" >/dev/null 2>&1; then
        echo "❌ Server is not running at $BASE_URL"
        echo "Please start the server with 'make run' and try again."
        exit 1
    fi
}

# Test function to send multiple requests
send_requests() {
    local endpoint=$1
    local num_requests=$2
    local description=$3

    print_info "Sending $num_requests requests to $endpoint"

    local success_count=0
    local rate_limited_count=0
    local error_count=0

    for i in $(seq 1 $num_requests); do
        response=$(curl -s -w "%{http_code}" -o /tmp/rate_limit_response_$i.json "$BASE_URL$endpoint" 2>/dev/null)
        http_code="${response: -3}"

        case $http_code in
            200|201)
                success_count=$((success_count + 1))
                printf "${GREEN}.${NC}"
                ;;
            429)
                rate_limited_count=$((rate_limited_count + 1))
                printf "${RED}R${NC}"
                ;;
            *)
                error_count=$((error_count + 1))
                printf "${YELLOW}E${NC}"
                ;;
        esac

        # Small delay to avoid overwhelming the system
        sleep 0.05
    done

    echo "" # New line after progress indicators
    echo "Results for $description:"
    echo "  ✅ Successful requests: $success_count"
    echo "  🚫 Rate limited (429): $rate_limited_count"
    echo "  ❌ Other errors: $error_count"
    echo ""

    # Check if rate limiting is working
    if [ $rate_limited_count -gt 0 ]; then
        print_status 0 "Rate limiting is working - received $rate_limited_count rate limit responses"

        # Show a sample rate limit response
        if [ -f "/tmp/rate_limit_response_1.json" ]; then
            echo "Sample rate limit response:"
            local sample_file=""
            for i in $(seq 1 $num_requests); do
                if [ -f "/tmp/rate_limit_response_$i.json" ]; then
                    response=$(curl -s -w "%{http_code}" -o /tmp/check_$i.json "$BASE_URL$endpoint" 2>/dev/null)
                    code="${response: -3}"
                    if [ "$code" = "429" ]; then
                        sample_file="/tmp/check_$i.json"
                        break
                    fi
                fi
            done

            if [ -n "$sample_file" ] && [ -f "$sample_file" ]; then
                echo "$(cat $sample_file 2>/dev/null || echo '{}')"
                rm -f "$sample_file"
            fi
        fi
    else
        print_status 1 "Rate limiting may not be working - no rate limit responses received"
        print_warning "This could mean the rate limit is set too high or not configured"
    fi

    # Cleanup
    for i in $(seq 1 $num_requests); do
        rm -f "/tmp/rate_limit_response_$i.json"
    done
}

# Test rate limiting on different endpoints
test_endpoint_rate_limiting() {
    local endpoint=$1
    local description=$2

    print_header "Testing Rate Limiting on $description"

    # Send a burst of requests
    send_requests "$endpoint" $CONCURRENT_REQUESTS "$description"

    # Wait for rate limit to reset
    print_info "Waiting 5 seconds for rate limit to potentially reset..."
    sleep 5

    # Test again to see if rate limit resets
    print_info "Testing rate limit reset"
    response=$(curl -s -w "%{http_code}" -o /tmp/reset_test.json "$BASE_URL$endpoint" 2>/dev/null)
    http_code="${response: -3}"

    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        print_status 0 "Rate limit appears to reset correctly"
    else
        print_status 1 "Rate limit may not be resetting - got HTTP $http_code"
    fi

    rm -f "/tmp/reset_test.json"
    echo ""
}

# Test with authentication
test_authenticated_rate_limiting() {
    print_header "Testing Rate Limiting with Authentication"

    # Try to login to get a token
    print_info "Attempting to login to get JWT token..."
    login_response=$(curl -s -w "%{http_code}" -o /tmp/login_response.json \
        -X POST "$BASE_URL/api/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"email":"admin@sistema.com","senha":"admin123"}' 2>/dev/null)

    login_code="${login_response: -3}"

    if [ "$login_code" = "200" ]; then
        # Extract token (try different methods)
        TOKEN=$(cat /tmp/login_response.json | python3 -c "import sys, json; print(json.load(sys.stdin)['token'])" 2>/dev/null || \
                cat /tmp/login_response.json | grep -o '"token":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "")

        if [ -n "$TOKEN" ]; then
            print_status 0 "Successfully obtained JWT token"

            # Test rate limiting on authenticated endpoint
            print_info "Testing rate limiting on authenticated endpoint /api/v1/users/me"

            local success_count=0
            local rate_limited_count=0
            local auth_error_count=0
            local other_error_count=0

            for i in $(seq 1 $CONCURRENT_REQUESTS); do
                response=$(curl -s -w "%{http_code}" -o /tmp/auth_test_$i.json \
                    -H "Authorization: Bearer $TOKEN" \
                    "$BASE_URL/api/v1/users/me" 2>/dev/null)
                http_code="${response: -3}"

                case $http_code in
                    200)
                        success_count=$((success_count + 1))
                        printf "${GREEN}.${NC}"
                        ;;
                    429)
                        rate_limited_count=$((rate_limited_count + 1))
                        printf "${RED}R${NC}"
                        ;;
                    401|403)
                        auth_error_count=$((auth_error_count + 1))
                        printf "${YELLOW}A${NC}"
                        ;;
                    *)
                        other_error_count=$((other_error_count + 1))
                        printf "${YELLOW}E${NC}"
                        ;;
                esac

                sleep 0.05
            done

            echo "" # New line
            echo "Authenticated endpoint results:"
            echo "  ✅ Successful requests: $success_count"
            echo "  🚫 Rate limited (429): $rate_limited_count"
            echo "  🔒 Auth errors (401/403): $auth_error_count"
            echo "  ❌ Other errors: $other_error_count"

            if [ $rate_limited_count -gt 0 ]; then
                print_status 0 "Rate limiting works on authenticated endpoints"
            else
                print_status 1 "Rate limiting may not be working on authenticated endpoints"
            fi

            # Cleanup
            for i in $(seq 1 $CONCURRENT_REQUESTS); do
                rm -f "/tmp/auth_test_$i.json"
            done

        else
            print_status 1 "Failed to extract JWT token from login response"
        fi
    else
        print_status 1 "Failed to login (HTTP $login_code) - cannot test authenticated rate limiting"
    fi

    rm -f "/tmp/login_response.json"
    echo ""
}

# Test concurrent requests
test_concurrent_requests() {
    print_header "Testing Concurrent Rate Limiting"

    print_info "Sending $CONCURRENT_REQUESTS concurrent requests..."

    # Send requests in background and collect PIDs
    local pids=()
    for i in $(seq 1 $CONCURRENT_REQUESTS); do
        (
            response=$(curl -s -w "%{http_code}" -o /tmp/concurrent_$i.json "$BASE_URL/health" 2>/dev/null)
            echo "${response: -3}" > "/tmp/concurrent_code_$i.txt"
        ) &
        pids+=($!)
    done

    # Wait for all requests to complete
    for pid in "${pids[@]}"; do
        wait $pid
    done

    # Analyze results
    local success_count=0
    local rate_limited_count=0
    local error_count=0

    for i in $(seq 1 $CONCURRENT_REQUESTS); do
        if [ -f "/tmp/concurrent_code_$i.txt" ]; then
            code=$(cat "/tmp/concurrent_code_$i.txt")
            case $code in
                200|201)
                    success_count=$((success_count + 1))
                    ;;
                429)
                    rate_limited_count=$((rate_limited_count + 1))
                    ;;
                *)
                    error_count=$((error_count + 1))
                    ;;
            esac
        fi
    done

    echo "Concurrent requests results:"
    echo "  ✅ Successful requests: $success_count"
    echo "  🚫 Rate limited (429): $rate_limited_count"
    echo "  ❌ Other errors: $error_count"

    if [ $rate_limited_count -gt 0 ]; then
        print_status 0 "Rate limiting handles concurrent requests correctly"
    else
        print_status 1 "Rate limiting may not handle concurrent requests properly"
    fi

    # Cleanup
    for i in $(seq 1 $CONCURRENT_REQUESTS); do
        rm -f "/tmp/concurrent_$i.json" "/tmp/concurrent_code_$i.txt"
    done

    echo ""
}

# Main execution
main() {
    print_header "🚦 Rate Limiting Test Suite"
    echo ""

    # Check prerequisites
    check_server
    print_status 0 "Server is running and accessible"
    echo ""

    # Test different scenarios
    test_endpoint_rate_limiting "/health" "Health Check Endpoint"
    test_endpoint_rate_limiting "/api/v1/users" "Users List Endpoint"
    test_authenticated_rate_limiting
    test_concurrent_requests

    # Summary
    print_header "📊 Test Summary"
    echo ""
    print_info "Rate limiting tests completed!"
    echo ""
    print_info "📋 What was tested:"
    echo "  • Basic rate limiting on public endpoints"
    echo "  • Rate limiting on authenticated endpoints"
    echo "  • Concurrent request handling"
    echo "  • Rate limit reset behavior"
    echo ""
    print_info "🔧 Rate limit configuration (from server logs):"
    echo "  Check server startup logs for current rate limiting settings"
    echo "  Default: 60 requests/minute with burst of 10"
    echo ""
    print_info "💡 Troubleshooting tips:"
    echo "  • If no rate limiting occurs, check RATE_LIMIT_RPM and RATE_LIMIT_BURST in .env"
    echo "  • Rate limits are per IP address"
    echo "  • Headers include: X-RateLimit-Limit, X-RateLimit-Remaining, Retry-After"
    echo "  • HTTP 429 responses indicate rate limiting is working"
    echo ""
    print_info "🚀 To adjust rate limiting:"
    echo "  • Edit .env file: RATE_LIMIT_RPM=30 RATE_LIMIT_BURST=5"
    echo "  • Restart server: make run"
    echo "  • Lower values = stricter rate limiting"
}

# Execute main function
main "$@"
