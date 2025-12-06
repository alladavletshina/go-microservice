#!/bin/bash

echo "=== БЕЗОПАСНЫЙ ПЕРЕЗАПУСК МИКРОСЕРВИСА ==="

cd ~/go-microservice-main

echo "1. Проверка Docker..."
if ! systemctl is-active --quiet docker; then
    echo "Запускаем Docker..."
    sudo systemctl start docker
    sleep 5
fi

echo "2. Проверка существующих контейнеров..."
if sudo docker ps -q --filter "name=go-microservice" | grep -q .; then
    echo "Найдены запущенные контейнеры. Пытаемся остановить..."
    
    # Пробуем graceful stop
    sudo docker-compose stop 2>/dev/null || true
    sleep 3
    
    # Если не сработало, force stop
    for container in $(sudo docker ps -q --filter "name=go-microservice"); do
        echo "Принудительная остановка контейнера $container"
        sudo docker stop -t 2 $container 2>/dev/null || true
    done
    
    sleep 2
else
    echo "Нет запущенных контейнеров."
fi

echo "3. Очистка..."
sudo docker-compose down --remove-orphans 2>/dev/null || true
sleep 2

echo "4. Удаление старых контейнеров проекта..."
sudo docker rm -f $(sudo docker ps -aq -f "name=go-microservice") 2>/dev/null || true

echo "5. Сборка образов..."
sudo docker-compose build --no-cache

echo "6. Запуск сервисов..."
sudo docker-compose up -d

echo "7. Ожидание запуска..."
for i in {1..15}; do
    if curl -s -f http://localhost:8080/health >/dev/null 2>&1; then
        echo "✅ Микросервис запущен и отвечает!"
        break
    fi
    echo -n "."
    sleep 2
done

echo "8. Финальная проверка..."
echo "Статус контейнеров:"
sudo docker-compose ps

echo -e "\nПроверка здоровья:"
curl -s http://localhost:8080/health || echo "⚠️  Сервис не отвечает"

echo "=== ГОТОВО ==="
