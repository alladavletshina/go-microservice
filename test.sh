# Проверяем здоровье
echo "=== Проверка здоровья ==="
curl http://localhost:8080/health

# Тестируем API
echo ""
echo "=== Тестируем создание пользователя ==="
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Test User", "email": "test@example.com"}'

echo ""
echo "=== Получаем всех пользователей ==="
curl http://localhost:8080/api/users

echo ""
echo "=== Проверяем метрики ==="
curl http://localhost:8080/metrics | grep http_requests_total

# Если все работает, делаем нагрузочное тестирование:

echo "=== Нагрузочное тестирование ==="
wrk -t4 -c100 -d30s http://localhost:8080/api/users

# Проверяем все сервисы:

echo "=== Проверка всех сервисов ==="
echo "Приложение: http://localhost:8080"
echo "Prometheus: http://localhost:9090" 
echo "Grafana: http://localhost:3000 (admin/admin)"
echo "MinIO: http://localhost:9001 (admin/password)"
