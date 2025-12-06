#!/bin/bash

# API Test Script for Go Microservice
# Comprehensive CRUD operations testing

API_BASE="http://localhost:8080/api"
HEALTH_URL="http://localhost:8080/health"
METRICS_URL="http://localhost:8080/metrics"
TEST_USER_NAME="Test User $(date +%s)"
TEST_USER_EMAIL="testuser_$(date +%s)@example.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if server is running
check_server() {
    print_status "Checking if server is running..."
    print_status "Health URL: $HEALTH_URL"
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" 2>/dev/null)
    
    if [ "$response" -eq 200 ]; then
        print_success "Server is running and healthy (HTTP $response)"
        return 0
    else
        print_error "Server is not responding. HTTP Code: $response"
        print_status "Checking if containers are running..."
        
        # Check Docker containers
        if docker-compose ps | grep -q "Up"; then
            print_status "Docker containers are running. Checking individual services..."
            
            # Check if we can connect to the service
            if nc -z localhost 8080 2>/dev/null; then
                print_status "Port 8080 is open, but service might be starting up..."
            else
                print_error "Port 8080 is not open"
            fi
        else
            print_error "Docker containers are not running"
        fi
        
        print_status "You can start it with: docker-compose up -d"
        print_status "Or check logs with: docker-compose logs go-microservice"
        exit 1
    fi
}

# Wait for server to be ready
wait_for_server() {
    print_status "Waiting for server to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$HEALTH_URL" > /dev/null 2>&1; then
            print_success "Server is ready after $attempt seconds"
            return 0
        fi
        print_status "Attempt $attempt/$max_attempts: Server not ready yet..."
        sleep 1
        ((attempt++))
    done
    
    print_error "Server did not become ready after $max_attempts seconds"
    return 1
}

# Test 1: Health Check
test_health() {
    print_status "Testing health endpoint..."
    response=$(curl -s "$HEALTH_URL")
    echo "Response: $response"
    echo
}

# Test 2: Get all users (empty)
test_get_empty_users() {
    print_status "Testing GET /users (empty)..."
    response=$(curl -s "$API_BASE/users")
    echo "Response: $response"
    echo
}

# Test 3: Create user
test_create_user() {
    print_status "Testing POST /users..."
    
    user_data=$(cat <<EOF
{
    "name": "$TEST_USER_NAME",
    "email": "$TEST_USER_EMAIL"
}
EOF
)
    
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$user_data" \
        "$API_BASE/users")
    
    echo "Response: $response"
    
    # Extract user ID from response
    USER_ID=$(echo "$response" | grep -o '"id":[0-9]*' | cut -d: -f2)
    
    if [ -n "$USER_ID" ]; then
        print_success "User created with ID: $USER_ID"
        export USER_ID
    else
        print_error "Failed to create user"
        exit 1
    fi
    echo
}

# Test 4: Get user by ID
test_get_user() {
    if [ -z "$USER_ID" ]; then
        print_error "No user ID available for testing"
        return 1
    fi
    
    print_status "Testing GET /users/$USER_ID..."
    response=$(curl -s "$API_BASE/users/$USER_ID")
    echo "Response: $response"
    
    # Verify the user data
    if echo "$response" | grep -q "$TEST_USER_NAME"; then
        print_success "User retrieved successfully"
    else
        print_error "User data mismatch"
    fi
    echo
}

# Test 5: Get all users (with data)
test_get_all_users() {
    print_status "Testing GET /users (with data)..."
    response=$(curl -s "$API_BASE/users")
    echo "Response: $response"
    
    user_count=$(echo "$response" | grep -o '"id"' | wc -l)
    print_success "Found $user_count user(s) in the system"
    echo
}

# Test 6: Update user
test_update_user() {
    if [ -z "$USER_ID" ]; then
        print_error "No user ID available for testing"
        return 1
    fi
    
    print_status "Testing PUT /users/$USER_ID..."
    
    updated_data=$(cat <<EOF
{
    "name": "Updated $TEST_USER_NAME",
    "email": "updated_$TEST_USER_EMAIL"
}
EOF
)
    
    response=$(curl -s -X PUT \
        -H "Content-Type: application/json" \
        -d "$updated_data" \
        "$API_BASE/users/$USER_ID")
    
    echo "Response: $response"
    
    # Verify the update
    if echo "$response" | grep -q "Updated $TEST_USER_NAME"; then
        print_success "User updated successfully"
    else
        print_error "Failed to update user"
    fi
    echo
}

# Test 7: Verify update
test_verify_update() {
    if [ -z "$USER_ID" ]; then
        print_error "No user ID available for testing"
        return 1
    fi
    
    print_status "Verifying user update..."
    response=$(curl -s "$API_BASE/users/$USER_ID")
    echo "Response: $response"
    
    if echo "$response" | grep -q "Updated $TEST_USER_NAME"; then
        print_success "Update verified successfully"
    else
        print_error "Update verification failed"
    fi
    echo
}

# Test 8: Upload avatar (placeholder)
test_upload_avatar() {
    if [ -z "$USER_ID" ]; then
        print_error "No user ID available for testing"
        return 1
    fi
    
    print_status "Testing POST /users/$USER_ID/avatar..."
    response=$(curl -s -X POST "$API_BASE/users/$USER_ID/avatar")
    echo "Response: $response"
    
    if echo "$response" | grep -q "MinIO integration"; then
        print_success "Avatar endpoint is available"
    else
        print_warning "Avatar endpoint returned unexpected response"
    fi
    echo
}

# Test 9: Delete user
test_delete_user() {
    if [ -z "$USER_ID" ]; then
        print_error "No user ID available for testing"
        return 1
    fi
    
    print_status "Testing DELETE /users/$USER_ID..."
    response_code=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$API_BASE/users/$USER_ID")
    
    if [ "$response_code" -eq 204 ]; then
        print_success "User deleted successfully (HTTP 204)"
    else
        print_error "Failed to delete user. HTTP Code: $response_code"
    fi
    echo
}

# Test 10: Verify deletion
test_verify_deletion() {
    if [ -z "$USER_ID" ]; then
        print_error "No user ID available for testing"
        return 1
    fi
    
    print_status "Verifying user deletion..."
    response_code=$(curl -s -o /dev/null -w "%{http_code}" "$API_BASE/users/$USER_ID")
    
    if [ "$response_code" -eq 404 ]; then
        print_success "User deletion verified (HTTP 404)"
    else
        print_error "User still exists or unexpected status: $response_code"
    fi
    echo
}

# Test 11: Error handling - Get non-existent user
test_get_nonexistent_user() {
    print_status "Testing GET /users/9999 (non-existent user)..."
    response_code=$(curl -s -o /dev/null -w "%{http_code}" "$API_BASE/users/9999")
    
    if [ "$response_code" -eq 404 ]; then
        print_success "Correctly handled non-existent user (HTTP 404)"
    else
        print_error "Unexpected response for non-existent user: $response_code"
    fi
    echo
}

# Test 12: Error handling - Invalid user data
test_invalid_data() {
    print_status "Testing POST /users with invalid data..."
    
    invalid_data=$(cat <<EOF
{
    "name": "",
    "email": ""
}
EOF
)
    
    response_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "$invalid_data" \
        "$API_BASE/users")
    
    if [ "$response_code" -eq 400 ]; then
        print_success "Correctly rejected invalid user data (HTTP 400)"
    else
        print_error "Unexpected response for invalid data: $response_code"
    fi
    echo
}

# Test 13: Error handling - Update non-existent user
test_update_nonexistent_user() {
    print_status "Testing PUT /users/9999 (non-existent user)..."
    
    update_data=$(cat <<EOF
{
    "name": "Non-existent User",
    "email": "nonexistent@example.com"
}
EOF
)
    
    response_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -X PUT \
        -H "Content-Type: application/json" \
        -d "$update_data" \
        "$API_BASE/users/9999")
    
    if [ "$response_code" -eq 404 ]; then
        print_success "Correctly handled update for non-existent user (HTTP 404)"
    else
        print_error "Unexpected response for non-existent user update: $response_code"
    fi
    echo
}

# Test 14: Metrics endpoint
test_metrics() {
    print_status "Testing /metrics endpoint..."
    response=$(curl -s "$METRICS_URL" | head -20)
    echo "First 20 lines of metrics:"
    echo "$response"
    echo
}

# Test 15: Rate limiting simulation
test_rate_limiting() {
    print_status "Testing rate limiting (making 10 rapid requests)..."
    
    for i in {1..10}; do
        response_code=$(curl -s -o /dev/null -w "%{http_code}" "$API_BASE/users")
        echo "Request $i: HTTP $response_code"
    done
    
    print_warning "Note: Rate limiting is configured for 1000 req/s with burst 5000"
    echo
}

# Test 16: Check MinIO connectivity
test_minio_connectivity() {
    print_status "Testing MinIO connectivity..."
    
    # Check if MinIO is accessible
    if curl -s http://localhost:9001/minio/health/live > /dev/null 2>&1; then
        print_success "MinIO is accessible on port 9001"
    else
        print_warning "MinIO is not accessible on port 9001"
    fi
    echo
}

# Main test execution
main() {
    echo "=========================================="
    echo "Go Microservice CRUD API Test Suite"
    echo "=========================================="
    echo
    
    # Check if server is running
    check_server
    
    # Wait for server to be fully ready
    wait_for_server
    
    # Run tests
    test_health
    test_minio_connectivity
    test_get_empty_users
    test_create_user
    test_get_user
    test_get_all_users
    test_update_user
    test_verify_update
    test_upload_avatar
    test_delete_user
    test_verify_deletion
    test_get_nonexistent_user
    test_invalid_data
    test_update_nonexistent_user
    test_metrics
    test_rate_limiting
    
    echo "=========================================="
    print_success "All tests completed!"
    echo "=========================================="
}

# Run main function
main
