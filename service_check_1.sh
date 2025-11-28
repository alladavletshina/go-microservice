#!/bin/bash

echo "=== SERVICE STATUS CHECK ==="
echo ""

# Docker services
echo "1. Docker Services:"
docker-compose ps

echo ""
echo "2. Service URLs:"
echo "   Go Microservice: http://localhost:8080"
echo "   Prometheus:      http://localhost:9090" 
echo "   Grafana:         http://localhost:3000"
echo "   MinIO Console:   http://localhost:9001"

echo ""
echo "3. Port Check:"
for port in 8080 9090 3000 9000 9001; do
    if nc -z localhost $port 2>/dev/null; then
        echo "   ✅ Port $port: OPEN"
    else
        echo "   ❌ Port $port: CLOSED"
    fi
done

echo ""
echo "4. Container Logs Status:"
for service in go-microservice prometheus grafana minio; do
    if docker-compose logs "$service" --tail=1 >/dev/null 2>&1; then
        echo "   ✅ $service: Logs available"
    else
        echo "   ❌ $service: No logs"
    fi
done
