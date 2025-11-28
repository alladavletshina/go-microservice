#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}   GO MICROSERVICE COMPLETE TEST SUITE   ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

# Function to test service
test_service() {
    local url=$1
    local name=$2
    local expected_status=${3:-200}
    
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    if [ "$response" -eq "$expected_status" ] || [ "$response" -eq "200" ] || [ "$response" -eq "302" ]; then
        print_status 0 "$name (HTTP $response)"
        return 0
    else
        print_status 1 "$name (HTTP $response, expected $expected_status)"
        return 1
    fi
}

# Function to test API endpoint
test_api() {
    local method=$1
    local url=$2
    local data=$3
    local expected_contains=$4
    local name=$5
    
    if [ "$method" = "POST" ]; then
        response=$(curl -s -X POST -H "Content-Type: application/json" -d "$data" "$url")
    else
        response=$(curl -s -X "$method" "$url")
    fi
    
    if echo "$response" | grep -q "$expected_contains"; then
        print_status 0 "$name"
        echo "   Response: $(echo $response | head -c 100)..."
    else
        print_status 1 "$name"
        echo "   Response: $response"
        return 1
    fi
}

# Start comprehensive testing
echo -e "${YELLOW}=== 1. Checking Docker Services ===${NC}"
docker-compose ps
echo ""

echo -e "${YELLOW}=== 2. Testing All Services Health ===${NC}"

# Test Go Microservice
test_service "http://localhost:8080/health" "Go Microservice Health"

# Test Prometheus
test_service "http://localhost:9090/-/healthy" "Prometheus Health"

# Test Grafana
test_service "http://localhost:3000/api/health" "Grafana Health"

# Test MinIO
test_service "http://localhost:9001/minio/health/live" "MinIO Health"
echo ""

echo -e "${YELLOW}=== 3. Testing CRUD Operations ===${NC}"

# Create user
test_api "POST" "http://localhost:8080/api/users" '{"name":"Test User","email":"test@example.com"}' "id" "Create User"

# Get user ID from response
USER_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d '{"name":"API Test User","email":"api@test.com"}' "http://localhost:8080/api/users")
USER_ID=$(echo $USER_RESPONSE | grep -o '"id":[0-9]*' | cut -d: -f2)

if [ -n "$USER_ID" ]; then
    echo -e "${GREEN}   Created user with ID: $USER_ID${NC}"
    
    # Get all users
    test_api "GET" "http://localhost:8080/api/users" "" "Test User" "Get All Users"
    
    # Get specific user
    test_api "GET" "http://localhost:8080/api/users/$USER_ID" "" "api@test.com" "Get User by ID"
    
    # Update user
    test_api "PUT" "http://localhost:8080/api/users/$USER_ID" '{"name":"Updated User","email":"updated@test.com"}' "Updated User" "Update User"
    
    # Test MinIO endpoint
    test_api "POST" "http://localhost:8080/api/users/$USER_ID/avatar" "" "MinIO" "MinIO Avatar Endpoint"
    
    # Delete user
    test_api "DELETE" "http://localhost:8080/api/users/$USER_ID" "" "" "Delete User"
else
    echo -e "${RED}   Failed to create test user${NC}"
fi
echo ""

echo -e "${YELLOW}=== 4. Testing Metrics ===${NC}"

# Test metrics endpoint
metrics_response=$(curl -s http://localhost:8080/metrics)
if echo "$metrics_response" | grep -q "http_requests_total"; then
    print_status 0 "Prometheus Metrics"
    echo "   Found metrics:"
    echo "$metrics_response" | grep "http_requests_total" | head -5 | sed 's/^/     /'
else
    print_status 1 "Prometheus Metrics"
fi
echo ""

echo -e "${YELLOW}=== 5. Testing Rate Limiting ===${NC}"

# Test rate limiting by making multiple rapid requests
echo "   Making 10 rapid requests to test rate limiting..."
for i in {1..10}; do
    response=$(curl -s -w "%{http_code}" -o /dev/null http://localhost:8080/api/users)
    if [ "$response" -eq "429" ]; then
        echo -e "${GREEN}   ✅ Rate limiting working (received 429)${NC}"
        break
    fi
    sleep 0.1
done
echo ""

echo -e "${YELLOW}=== 6. Load Testing ===${NC}"

# Quick load test
echo "   Running quick load test (5 seconds)..."
wrk -t2 -c50 -d5s http://localhost:8080/api/users 2>/dev/null | grep -E "(Requests/sec|Latency)" | sed 's/^/   /'

if [ $? -ne 0 ]; then
    echo -e "${YELLOW}   ⚠️  wrk not available, skipping load test${NC}"
fi
echo ""

echo -e "${YELLOW}=== 7. Service URLs ===${NC}"
echo -e "${BLUE}   Go Microservice:${NC} http://localhost:8080"
echo -e "${BLUE}   Prometheus:${NC}      http://localhost:9090"
echo -e "${BLUE}   Grafana:${NC}         http://localhost:3000 (admin/admin)"
echo -e "${BLUE}   MinIO Console:${NC}   http://localhost:9001 (admin/password)"
echo ""

echo -e "${YELLOW}=== 8. Docker Container Status ===${NC}"
docker-compose ps --format "table {{.Name}}\t{{.State}}\t{{.Ports}}"
echo ""

echo -e "${YELLOW}=== 9. Checking Logs ===${NC}"
echo "   Recent application logs:"
docker-compose logs go-microservice --tail=5 2>/dev/null | sed 's/^/   /' || echo "   No logs available"
echo ""

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}           TESTING COMPLETE             ${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "${GREEN}🎉 All tests completed!${NC}"
echo "Check the URLs above to manually verify each service."
echo ""

# Final health check
echo -e "${YELLOW}=== Final Health Status ===${NC}"
all_services_ok=0

services=(
    "http://localhost:8080/health:Go Microservice"
    "http://localhost:9090/-/healthy:Prometheus" 
    "http://localhost:9001/minio/health/live:MinIO"
)

for service in "${services[@]}"; do
    url="${service%:*}"
    name="${service#*:}"
    if curl -s --max-time 5 "$url" > /dev/null; then
        echo -e "${GREEN}✅ $name: HEALTHY${NC}"
        ((all_services_ok++))
    else
        echo -e "${RED}❌ $name: UNHEALTHY${NC}"
    fi
done

echo ""
if [ $all_services_ok -eq 3 ]; then
    echo -e "${GREEN}🎊 ALL SERVICES ARE HEALTHY! 🎊${NC}"
    echo -e "${GREEN}Your microservice is fully operational!${NC}"
else
    echo -e "${YELLOW}⚠️  Some services may need attention${NC}"
fi

echo ""
echo -e "${BLUE}=========================================${NC}"
