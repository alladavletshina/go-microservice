#!/bin/bash

# Скрипт для сбора всего проекта Go в один текстовый файл
# Использование: ./collect_project.sh

OUTPUT_FILE="go-microservice-full-project.txt"
PROJECT_ROOT="."

# Функция для добавления разделителя с именем файла
add_file() {
    local file_path="$1"
    echo "==================================================" >> "$OUTPUT_FILE"
    echo "FILE: $file_path" >> "$OUTPUT_FILE"
    echo "==================================================" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    if [ -f "$file_path" ]; then
        cat "$file_path" >> "$OUTPUT_FILE"
    else
        echo "FILE NOT FOUND: $file_path" >> "$OUTPUT_FILE"
    fi
    
    echo "" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
}

# Очищаем выходной файл
> "$OUTPUT_FILE"

# Добавляем заголовок
echo "GO MICROSERVICE PROJECT - FULL SOURCE CODE" >> "$OUTPUT_FILE"
echo "Generated on: $(date)" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Добавляем структуру проекта
echo "PROJECT STRUCTURE:" >> "$OUTPUT_FILE"
echo "==================" >> "$OUTPUT_FILE"
find "$PROJECT_ROOT" -type f -name "*.go" -o -name "go.mod" -o -name "go.sum" -o -name "Dockerfile" -o -name "docker-compose.yml" -o -name "*.yaml" -o -name "*.yml" | sort >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Добавляем go.mod первым (важно для зависимостей)
add_file "go.mod"

# Добавляем go.sum
add_file "go.sum"

# Добавляем модели
add_file "models/user.go"

# Добавляем утилиты
add_file "utils/logger.go"
add_file "utils/rate_limiter.go"

# Добавляем метрики
add_file "metrics/prometheus.go"

# Добавляем сервисы
add_file "services/user_service.go"

# Добавляем обработчики
add_file "handlers/user_handler.go"

# Добавляем главный файл
add_file "main.go"

# Добавляем Docker файлы
add_file "Dockerfile"
add_file "docker-compose.yml"

# Добавляем конфигурацию Prometheus
add_file "prometheus.yml"

# Добавляем команды для тестирования
echo "==================================================" >> "$OUTPUT_FILE"
echo "TESTING COMMANDS" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

cat >> "$OUTPUT_FILE" << 'EOF'
# Команды для запуска и тестирования:

# 1. Установка зависимостей
go mod tidy

# 2. Запуск в режиме разработки
go run main.go

# 3. Тестовые запросы к API
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe", "email": "john@example.com"}'

curl http://localhost:8080/api/users

curl http://localhost:8080/metrics

# 4. Сборка Docker образа
docker-compose build

# 5. Запуск в Docker
docker-compose up -d

# 6. Нагрузочное тестирование
wrk -t12 -c500 -d60s http://localhost:8080/api/users

# 7. Остановка Docker
docker-compose down
EOF

echo "" >> "$OUTPUT_FILE"
echo "==================================================" >> "$OUTPUT_FILE"
echo "PROJECT COLLECTION COMPLETED" >> "$OUTPUT_FILE"
echo "Output file: $OUTPUT_FILE" >> "$OUTPUT_FILE"

# Показываем информацию о созданном файле
echo ""
echo "✅ Project collected successfully!"
echo "📁 Output file: $OUTPUT_FILE"
echo "📊 File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
echo "📝 Total lines: $(wc -l < "$OUTPUT_FILE")"