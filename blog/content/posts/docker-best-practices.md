---
title: "Docker Best Practices: Dockerfile и docker-compose для веб-сервисов"
description: "Лучшие практики написания Dockerfile и docker-compose.yaml для современного веб-стека: Nginx, Redis, JavaScript, MySQL, PHP, Go"
date: 2025-01-13
tldr: "Комплексное руководство по лучшим практикам Docker для веб-разработки с реальными примерами"
draft: false
tags: ["docker", "dockerfile", "docker-compose", "веб-разработка", "nginx", "mysql", "php", "javascript", "go", "redis"]
toc: true
---

# Docker Best Practices: Dockerfile и docker-compose для веб-сервисов

Правильная контейнеризация веб-сервисов — это искусство, требующее понимания не только Docker, но и специфики каждой технологии в стеке. В этой статье мы рассмотрим лучшие практики создания Dockerfile и docker-compose.yaml для современного веб-стека.

## Общие принципы лучших практик Docker

### 1. Принцип единственной ответственности
Каждый контейнер должен решать одну задачу и делать её хорошо.

### 2. Минимизация размера образов
Используйте alpine образы, многостадийную сборку и .dockerignore.

### 3. Безопасность превыше всего
Не запускайте процессы от root, сканируйте на уязвимости, используйте секреты.

### 4. Оптимизация кэширования слоев
Структурируйте Dockerfile для максимального переиспользования слоев.

{{< note >}}
Правильный порядок инструкций в Dockerfile может сократить время сборки в разы за счет кэширования Docker слоев.
{{< /note >}}

## Базовые практики Dockerfile

### Оптимизация порядка инструкций

```dockerfile
# ❌ Плохо - зависимости пересобираются при каждом изменении кода
FROM node:18-alpine
COPY . /app
WORKDIR /app
RUN npm install
CMD ["npm", "start"]

# ✅ Хорошо - зависимости кэшируются
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
CMD ["npm", "start"]
```

### Использование .dockerignore

```dockerfile
# .dockerignore
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
.env.local
coverage
.coverage
.nyc_output
.cache
.next
.nuxt
dist
.DS_Store
Thumbs.db
*.log
.vscode
.idea
docker-compose*.yml
Dockerfile*
```

### Многостадийная сборка

```dockerfile
# Dockerfile.multistage
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM node:18-alpine AS production
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001
WORKDIR /app
COPY --from=builder --chown=nextjs:nodejs /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
USER nextjs
EXPOSE 3000
CMD ["npm", "start"]
```

## Лучшие практики по технологиям

### JavaScript/Node.js Service

```dockerfile
# Dockerfile.nodejs
FROM node:18-alpine AS base

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create app directory
WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Development stage
FROM base AS development
ENV NODE_ENV=development
COPY package*.json ./
RUN npm install
COPY . .
RUN chown -R nodejs:nodejs /app
USER nodejs
EXPOSE 3000
CMD ["dumb-init", "npm", "run", "dev"]

# Build stage
FROM base AS builder
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force
COPY . .
RUN npm run build && \
    npm run test -- --coverage --watchAll=false

# Production stage
FROM base AS production
ENV NODE_ENV=production
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/public ./public
RUN chown -R nodejs:nodejs /app
USER nodejs
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1
CMD ["dumb-init", "node", "dist/server.js"]
```

### JavaScript с линтерами и тестами

```dockerfile
# Dockerfile.js-full
FROM node:18-alpine AS base
RUN apk add --no-cache dumb-init git
WORKDIR /app

# Dependencies stage
FROM base AS dependencies
COPY package*.json ./
RUN npm ci && npm cache clean --force

# Linting stage
FROM dependencies AS linting
COPY . .
RUN npm run lint && \
    npm run type-check

# Testing stage
FROM dependencies AS testing
COPY . .
RUN npm run test -- --coverage --watchAll=false --ci
RUN npm run test:e2e -- --ci

# Build stage
FROM dependencies AS builder
COPY . .
RUN npm run build

# Production stage
FROM base AS production
ENV NODE_ENV=production
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001
COPY package*.json ./
RUN npm ci --only=production
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
USER nodejs
EXPOSE 3000
HEALTHCHECK CMD curl -f http://localhost:3000/health || exit 1
CMD ["dumb-init", "node", "dist/index.js"]
```

### PHP Service с тестами

```dockerfile
# Dockerfile.php
FROM php:8.2-fpm-alpine AS base

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    oniguruma-dev \
    icu-dev \
    freetype-dev \
    libjpeg-turbo-dev

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    intl \
    opcache

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create non-root user
RUN addgroup -g 1000 www && \
    adduser -u 1000 -G www -s /bin/sh -D www

WORKDIR /var/www

# Development stage
FROM base AS development
# Install Xdebug for development
RUN pecl install xdebug && \
    docker-php-ext-enable xdebug

COPY php.ini-development /usr/local/etc/php/php.ini
COPY xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

COPY --chown=www:www . .
RUN composer install --dev --no-scripts
USER www
CMD ["php-fpm"]

# Testing stage
FROM base AS testing
COPY --chown=www:www . .
RUN composer install --dev --no-scripts --no-autoloader && \
    composer dump-autoload --optimize

# Run tests
RUN ./vendor/bin/phpunit --configuration phpunit.xml --coverage-text && \
    ./vendor/bin/phpstan analyse --level=8 src/ && \
    ./vendor/bin/php-cs-fixer fix --dry-run --diff

# Production stage
FROM base AS production
# Production PHP configuration
COPY php.ini-production /usr/local/etc/php/php.ini
COPY opcache.ini /usr/local/etc/php/conf.d/opcache.ini

COPY --chown=www:www composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-scripts

COPY --chown=www:www . .
RUN composer dump-autoload --optimize --no-dev

USER www
EXPOSE 9000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD php-fpm-healthcheck || exit 1

CMD ["php-fpm"]
```

### Go Service

```dockerfile
# Dockerfile.go
FROM golang:1.21-alpine AS base
RUN apk add --no-cache git ca-certificates tzdata
WORKDIR /app

# Dependencies stage
FROM base AS dependencies
COPY go.mod go.sum ./
RUN go mod download && go mod verify

# Development stage
FROM dependencies AS development
RUN go install github.com/cosmtrek/air@latest
COPY . .
EXPOSE 8080
CMD ["air", "-c", ".air.toml"]

# Testing stage
FROM dependencies AS testing
COPY . .
# Run linting
RUN go install golang.org/x/tools/cmd/goimports@latest && \
    go install honnef.co/go/tools/cmd/staticcheck@latest && \
    gofmt -l . && \
    goimports -l . && \
    staticcheck ./...

# Run tests with race detection
RUN CGO_ENABLED=1 go test -race -coverprofile=coverage.out ./... && \
    go tool cover -html=coverage.out -o coverage.html

# Build stage
FROM dependencies AS builder
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a -installsuffix cgo \
    -o main ./cmd/server

# Production stage
FROM scratch AS production
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /app/main /main

USER 1000:1000
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/main", "healthcheck"]

CMD ["/main"]
```

### Nginx Service

```dockerfile
# Dockerfile.nginx
FROM nginx:1.25-alpine AS base

# Install additional tools
RUN apk add --no-cache \
    curl \
    tzdata

# Remove default nginx website
RUN rm /etc/nginx/conf.d/default.conf

# Development stage
FROM base AS development
COPY nginx/dev.conf /etc/nginx/conf.d/
COPY nginx/nginx.conf /etc/nginx/
EXPOSE 80 443
CMD ["nginx", "-g", "daemon off;"]

# Production stage
FROM base AS production
# Security headers and optimizations
COPY nginx/prod.conf /etc/nginx/conf.d/
COPY nginx/nginx.conf /etc/nginx/
COPY nginx/ssl-params.conf /etc/nginx/

# Create non-root user
RUN addgroup -g 101 -S nginx && \
    adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx nginx

# Copy static files
COPY --chown=nginx:nginx dist/ /usr/share/nginx/html/

EXPOSE 80 443

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
```

## Конфигурация docker-compose

### Базовый docker-compose.yml

```yaml
# docker-compose.yml
version: '3.8'

x-common-variables: &common-variables
  NODE_ENV: ${NODE_ENV:-production}
  DATABASE_URL: mysql://user:password@mysql:3306/app
  REDIS_URL: redis://redis:6379
  JWT_SECRET: ${JWT_SECRET}

services:
  nginx:
    build:
      context: ./nginx
      dockerfile: Dockerfile
      target: ${BUILD_TARGET:-production}
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./ssl:/etc/nginx/ssl
      - static_files:/usr/share/nginx/html
    depends_on:
      - frontend
      - api
    restart: unless-stopped
    networks:
      - web
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      target: ${BUILD_TARGET:-production}
      args:
        - NODE_ENV=${NODE_ENV:-production}
        - API_URL=${API_URL:-http://api:3000}
    environment:
      <<: *common-variables
    volumes:
      - static_files:/app/dist
    depends_on:
      - api
    restart: unless-stopped
    networks:
      - web
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  api:
    build:
      context: ./api
      dockerfile: Dockerfile
      target: ${BUILD_TARGET:-production}
    environment:
      <<: *common-variables
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy
    restart: unless-stopped
    networks:
      - web
      - internal
    volumes:
      - ./api/storage:/app/storage
    secrets:
      - db_password
      - jwt_secret

  php-app:
    build:
      context: ./php
      dockerfile: Dockerfile
      target: ${BUILD_TARGET:-production}
    environment:
      - DB_HOST=mysql
      - DB_DATABASE=app
      - DB_USERNAME=user
      - DB_PASSWORD_FILE=/run/secrets/db_password
      - REDIS_HOST=redis
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - ./php/storage:/var/www/storage
      - ./php/bootstrap/cache:/var/www/bootstrap/cache
    restart: unless-stopped
    networks:
      - internal
    secrets:
      - db_password

  go-service:
    build:
      context: ./go-service
      dockerfile: Dockerfile
      target: ${BUILD_TARGET:-production}
    environment:
      - DATABASE_URL=mysql://user:password@mysql:3306/app
      - REDIS_URL=redis://redis:6379
      - PORT=8080
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy
    restart: unless-stopped
    networks:
      - internal
    secrets:
      - db_password

  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD_FILE: /run/secrets/db_root_password
      MYSQL_DATABASE: app
      MYSQL_USER: user
      MYSQL_PASSWORD_FILE: /run/secrets/db_password
    volumes:
      - mysql_data:/var/lib/mysql
      - ./mysql/init:/docker-entrypoint-initdb.d
      - ./mysql/conf.d:/etc/mysql/conf.d
    restart: unless-stopped
    networks:
      - internal
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p$$(cat /run/secrets/db_root_password)"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 30s
    secrets:
      - db_password
      - db_root_password
    command: --default-authentication-plugin=mysql_native_password

  redis:
    image: redis:7.2-alpine
    command: redis-server --appendonly yes --requirepass $${REDIS_PASSWORD}
    environment:
      - REDIS_PASSWORD_FILE=/run/secrets/redis_password
    volumes:
      - redis_data:/data
      - ./redis/redis.conf:/usr/local/etc/redis/redis.conf
    restart: unless-stopped
    networks:
      - internal
    healthcheck:
      test: ["CMD", "redis-cli", "--no-auth-warning", "-a", "$$(cat /run/secrets/redis_password)", "ping"]
      interval: 10s
      timeout: 5s
      retries: 3
    secrets:
      - redis_password

volumes:
  mysql_data:
    driver: local
  redis_data:
    driver: local
  static_files:
    driver: local

networks:
  web:
    driver: bridge
  internal:
    driver: bridge
    internal: true

secrets:
  db_password:
    file: ./secrets/db_password.txt
  db_root_password:
    file: ./secrets/db_root_password.txt
  redis_password:
    file: ./secrets/redis_password.txt
  jwt_secret:
    file: ./secrets/jwt_secret.txt
```

### Разработческий docker-compose.dev.yml

```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  nginx:
    build:
      target: development
    volumes:
      - ./nginx/dev.conf:/etc/nginx/conf.d/default.conf
    ports:
      - "8080:80"

  frontend:
    build:
      target: development
    environment:
      - NODE_ENV=development
      - CHOKIDAR_USEPOLLING=true
    volumes:
      - ./frontend:/app
      - /app/node_modules
    ports:
      - "3000:3000"
    command: npm run dev

  api:
    build:
      target: development
    environment:
      - NODE_ENV=development
      - DEBUG=app:*
    volumes:
      - ./api:/app
      - /app/node_modules
    ports:
      - "3001:3000"
      - "9229:9229"  # Node.js debugger
    command: npm run dev:debug

  php-app:
    build:
      target: development
    environment:
      - APP_ENV=local
      - APP_DEBUG=true
      - XDEBUG_MODE=debug
      - XDEBUG_CONFIG=client_host=host.docker.internal client_port=9003
    volumes:
      - ./php:/var/www
      - ./php/docker/php/local.ini:/usr/local/etc/php/conf.d/local.ini
    ports:
      - "9003:9003"  # Xdebug port

  go-service:
    build:
      target: development
    environment:
      - GO_ENV=development
      - CGO_ENABLED=1
    volumes:
      - ./go-service:/app
    ports:
      - "8080:8080"
      - "2345:2345"  # Delve debugger
    command: air -c .air.toml

  mysql:
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=rootpass
      - MYSQL_PASSWORD=password
    volumes:
      - mysql_dev_data:/var/lib/mysql

  redis:
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes
    volumes:
      - redis_dev_data:/data

  # Development tools
  mailhog:
    image: mailhog/mailhog
    ports:
      - "1025:1025"  # SMTP
      - "8025:8025"  # Web UI
    networks:
      - internal

  phpmyadmin:
    image: phpmyadmin:latest
    environment:
      PMA_HOST: mysql
      PMA_USER: root
      PMA_PASSWORD: rootpass
    ports:
      - "8081:80"
    depends_on:
      - mysql
    networks:
      - internal

  redis-commander:
    image: rediscommander/redis-commander:latest
    environment:
      - REDIS_HOSTS=local:redis:6379
    ports:
      - "8082:8081"
    depends_on:
      - redis
    networks:
      - internal

volumes:
  mysql_dev_data:
  redis_dev_data:
```

### Тестовый docker-compose.test.yml

```yaml
# docker-compose.test.yml
version: '3.8'

services:
  frontend-test:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      target: testing
    environment:
      - NODE_ENV=test
      - CI=true
    volumes:
      - ./frontend/coverage:/app/coverage
    command: npm run test:ci

  api-test:
    build:
      context: ./api
      dockerfile: Dockerfile
      target: testing
    environment:
      - NODE_ENV=test
      - DATABASE_URL=mysql://test:test@mysql-test:3306/test_db
      - REDIS_URL=redis://redis-test:6379
    depends_on:
      - mysql-test
      - redis-test
    volumes:
      - ./api/coverage:/app/coverage
    command: npm run test:integration

  php-test:
    build:
      context: ./php
      dockerfile: Dockerfile
      target: testing
    environment:
      - APP_ENV=testing
      - DB_HOST=mysql-test
      - DB_DATABASE=test_db
      - DB_USERNAME=test
      - DB_PASSWORD=test
    depends_on:
      - mysql-test
    volumes:
      - ./php/coverage:/var/www/coverage

  go-test:
    build:
      context: ./go-service
      dockerfile: Dockerfile
      target: testing
    environment:
      - GO_ENV=test
      - DATABASE_URL=mysql://test:test@mysql-test:3306/test_db
    depends_on:
      - mysql-test
    volumes:
      - ./go-service/coverage:/app/coverage

  mysql-test:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: roottest
      MYSQL_DATABASE: test_db
      MYSQL_USER: test
      MYSQL_PASSWORD: test
    tmpfs:
      - /var/lib/mysql
    command: --default-authentication-plugin=mysql_native_password

  redis-test:
    image: redis:7.2-alpine
    command: redis-server --appendonly no
    tmpfs:
      - /data

  # E2E tests
  e2e:
    build:
      context: ./e2e
      dockerfile: Dockerfile
    environment:
      - BASE_URL=http://nginx
    depends_on:
      - nginx
      - frontend
      - api
    volumes:
      - ./e2e/screenshots:/app/screenshots
      - ./e2e/videos:/app/videos
    profiles:
      - e2e
```

## Безопасность и производство

### Конфигурационные файлы

```bash
# secrets/db_password.txt
super_secure_db_password_here

# secrets/db_root_password.txt  
ultra_secure_root_password_here

# secrets/redis_password.txt
redis_password_here

# secrets/jwt_secret.txt
jwt_secret_key_here
```

### Nginx конфигурация для production

```nginx
# nginx/prod.conf
upstream frontend {
    server frontend:3000 max_fails=3 fail_timeout=30s;
}

upstream api {
    server api:3000 max_fails=3 fail_timeout=30s;
}

upstream php_backend {
    server php-app:9000 max_fails=3 fail_timeout=30s;
}

# Rate limiting
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;

server {
    listen 80;
    server_name example.com www.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com www.example.com;

    # SSL configuration
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    include /etc/nginx/ssl-params.conf;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # API routes
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeout settings
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # PHP application
    location /app/ {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass php_backend;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # Static files with caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        try_files $uri @frontend;
    }

    # Frontend application
    location / {
        proxy_pass http://frontend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
```

### MySQL конфигурация

```ini
# mysql/conf.d/my.cnf
[mysqld]
# Performance
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT

# Security
local-infile = 0
skip-show-database
bind-address = 0.0.0.0

# Logging
general_log = 0
slow_query_log = 1
slow_query_log_file = /var/lib/mysql/slow.log
long_query_time = 2

# Character set
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4

[client]
default-character-set = utf8mb4
```

## Мониторинг и логирование

### docker-compose.monitoring.yml

```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    ports:
      - "9090:9090"
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=grafana
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/provisioning:/etc/grafana/provisioning
    ports:
      - "3001:3000"
    networks:
      - monitoring

  loki:
    image: grafana/loki:latest
    container_name: loki
    restart: unless-stopped
    volumes:
      - ./monitoring/loki.yml:/etc/loki/local-config.yaml
      - loki_data:/loki
    ports:
      - "3100:3100"
    networks:
      - monitoring

  promtail:
    image: grafana/promtail:latest
    container_name: promtail
    restart: unless-stopped
    volumes:
      - /var/log:/var/log:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - ./monitoring/promtail.yml:/etc/promtail/config.yml
    networks:
      - monitoring

  node_exporter:
    image: prom/node-exporter:latest
    container_name: node_exporter
    restart: unless-stopped
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    ports:
      - "9100:9100"
    networks:
      - monitoring

volumes:
  prometheus_data:
  grafana_data:
  loki_data:

networks:
  monitoring:
    driver: bridge
```

## Автоматизация и CI/CD

### Makefile для управления проектом

```makefile
# Makefile
.PHONY: help build up down logs test clean lint security-scan

# Variables
COMPOSE_DEV := docker-compose -f docker-compose.yml -f docker-compose.dev.yml
COMPOSE_TEST := docker-compose -f docker-compose.yml -f docker-compose.test.yml
COMPOSE_PROD := docker-compose -f docker-compose.yml -f docker-compose.prod.yml

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build all services
	$(COMPOSE_DEV) build

up: ## Start development environment
	$(COMPOSE_DEV) up -d
	@echo "Development environment started"
	@echo "Frontend: http://localhost:3000"
	@echo "API: http://localhost:3001"
	@echo "Nginx: http://localhost:8080"

down: ## Stop all services
	$(COMPOSE_DEV) down
	$(COMPOSE_TEST) down
	$(COMPOSE_PROD) down

logs: ## Show logs for all services
	$(COMPOSE_DEV) logs -f

test: ## Run all tests
	$(COMPOSE_TEST) up --build --abort-on-container-exit
	$(COMPOSE_TEST) down

test-unit: ## Run unit tests only
	$(COMPOSE_TEST) run --rm frontend-test npm run test:unit
	$(COMPOSE_TEST) run --rm api-test npm run test:unit
	$(COMPOSE_TEST) run --rm php-test ./vendor/bin/phpunit
	$(COMPOSE_TEST) run --rm go-test go test ./...

test-integration: ## Run integration tests
	$(COMPOSE_TEST) run --rm api-test npm run test:integration

lint: ## Run linting for all services
	$(COMPOSE_DEV) run --rm frontend npm run lint
	$(COMPOSE_DEV) run --rm api npm run lint
	$(COMPOSE_DEV) run --rm php-app ./vendor/bin/php-cs-fixer fix --dry-run
	$(COMPOSE_DEV) run --rm go-service golangci-lint run

security-scan: ## Run security scans
	docker run --rm -v $(PWD):/app securecodewarrior/docker-image-scanner /app
	$(COMPOSE_DEV) run --rm php-app ./vendor/bin/security-checker security:check
	$(COMPOSE_DEV) run --rm frontend npm audit
	$(COMPOSE_DEV) run --rm api npm audit

prod-deploy: ## Deploy to production
	$(COMPOSE_PROD) pull
	$(COMPOSE_PROD) up -d --no-deps --build
	$(COMPOSE_PROD) exec api npm run migrate:prod

backup: ## Backup databases
	docker exec mysql mysqldump -u root -p$$(cat secrets/db_root_password.txt) --all-databases > backup_$$(date +%Y%m%d_%H%M%S).sql
	docker exec redis redis-cli --rdb /data/dump_$$(date +%Y%m%d_%H%M%S).rdb

clean: ## Clean up containers, images, and volumes
	docker container prune -f
	docker image prune -f
	docker volume prune -f
	docker network prune -f

restart: down up ## Restart all services

shell-%: ## Open shell in service (e.g., make shell-api)
	$(COMPOSE_DEV) exec $* sh
```

### GitHub Actions Workflow

```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
          cache-dependency-path: |
            frontend/package-lock.json
            api/package-lock.json
      
      - name: Install dependencies
        run: |
          cd frontend && npm ci
          cd ../api && npm ci
      
      - name: Lint Frontend
        run: cd frontend && npm run lint
      
      - name: Lint API
        run: cd api && npm run lint
      
      - name: Type Check
        run: |
          cd frontend && npm run type-check
          cd ../api && npm run type-check

  test:
    runs-on: ubuntu-latest
    needs: lint
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: test
          MYSQL_DATABASE: test_db
        options: >-
          --health-cmd="mysqladmin ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=3
        ports:
          - 3306:3306
      
      redis:
        image: redis:7.2-alpine
        options: >-
          --health-cmd="redis-cli ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=3
        ports:
          - 6379:6379

    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Run tests
        run: |
          docker-compose -f docker-compose.yml -f docker-compose.test.yml up --build --abort-on-container-exit
          docker-compose -f docker-compose.yml -f docker-compose.test.yml down
      
      - name: Upload coverage reports
        uses: codecov/codecov-action@v3
        with:
          files: ./frontend/coverage/lcov.info,./api/coverage/lcov.info
          flags: unittests
          name: codecov-umbrella

  security:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'
      
      - name: Upload Trivy scan results to GitHub Security tab
        uses: github/codeql-action/upload-sarif@v2
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'

  build-and-push:
    runs-on: ubuntu-latest
    needs: [test, security]
    if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/develop'
    strategy:
      matrix:
        service: [frontend, api, php-app, go-service, nginx]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}-${{ matrix.service }}
          tags: |
            type=ref,event=branch
            type=ref,event=pr
            type=sha,prefix={{branch}}-
            type=raw,value=latest,enable={{is_default_branch}}
      
      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: ./${{ matrix.service }}
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          target: production
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    runs-on: ubuntu-latest
    needs: build-and-push
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy to production
        run: |
          echo "Deploying to production server..."
          # Add your deployment logic here
```

## Оптимизация производительности

### Многостадийная сборка с кэшированием

```dockerfile
# Dockerfile.optimized
# syntax=docker/dockerfile:1.4
FROM node:18-alpine AS base
WORKDIR /app
RUN apk add --no-cache dumb-init

# Dependencies stage with cache mount
FROM base AS deps
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --only=production && npm cache clean --force

# Development dependencies stage
FROM deps AS deps-dev
RUN --mount=type=cache,target=/root/.npm \
    npm install

# Build stage
FROM deps-dev AS builder
COPY . .
RUN --mount=type=cache,target=/root/.npm \
    --mount=type=cache,target=.next/cache \
    npm run build

# Production stage
FROM base AS production
ENV NODE_ENV=production
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/public ./public
COPY package*.json ./

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001
USER nextjs

EXPOSE 3000
CMD ["dumb-init", "node", "dist/server.js"]
```

### Оптимизация размера образов

```dockerfile
# Dockerfile.minimal
FROM alpine:3.18 AS base
RUN apk add --no-cache ca-certificates tzdata
WORKDIR /app

FROM golang:1.21-alpine AS builder
WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags='-w -s -extldflags "-static"' \
    -a -installsuffix cgo \
    -o app ./cmd/main.go

# Distroless final image
FROM gcr.io/distroless/static:nonroot
COPY --from=builder /build/app /
EXPOSE 8080
USER nonroot:nonroot
CMD ["/app"]
```

## Управление конфигурацией

### Использование переменных окружения

```yaml
# .env.example
# Database
DB_HOST=mysql
DB_PORT=3306
DB_NAME=app
DB_USER=user
DB_PASSWORD=

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=

# Application
APP_ENV=production
APP_DEBUG=false
APP_URL=https://example.com
API_URL=https://api.example.com

# Security
JWT_SECRET=
ENCRYPTION_KEY=
SESSION_SECRET=

# Services
MAIL_HOST=
MAIL_PORT=587
MAIL_USERNAME=
MAIL_PASSWORD=

# Monitoring
SENTRY_DSN=
NEW_RELIC_LICENSE_KEY=
```

### Конфигурация для разных сред

```yaml
# docker-compose.override.yml (automatically loaded)
version: '3.8'

services:
  frontend:
    environment:
      - NODE_ENV=development
      - REACT_APP_API_URL=http://localhost:3001
    volumes:
      - ./frontend:/app
      - /app/node_modules
    ports:
      - "3000:3000"

  api:
    environment:
      - NODE_ENV=development
      - DEBUG=api:*
    volumes:
      - ./api:/app
      - /app/node_modules
    ports:
      - "3001:3000"
      - "9229:9229"  # Debug port
```

## Заключение

Правильная контейнеризация веб-сервисов требует понимания множества аспектов:

### Ключевые принципы:

1. **Безопасность первична** - используйте non-root пользователей, сканируйте на уязвимости
2. **Оптимизация размера** - многостадийная сборка, alpine образы, .dockerignore
3. **Кэширование слоев** - правильный порядок инструкций в Dockerfile
4. **Мониторинг и логирование** - healthchecks, structured logging
5. **Автоматизация** - CI/CD пайплайны, автоматическое тестирование

### Лучшие практики по технологиям:

- **JavaScript/Node.js**: используйте dumb-init, кэшируйте node_modules, включайте линтинг в сборку
- **PHP**: настройте OPcache, используйте PHP-FPM, включайте Xdebug только для разработки  
- **Go**: используйте scratch/distroless образы, статическую компиляцию, race detector для тестов
- **Nginx**: настройте gzip, кэширование, security headers, rate limiting
- **MySQL**: оптимизируйте конфигурацию, используйте health checks
- **Redis**: настройте persistence, мониторинг памяти

### Инструменты разработчика:

- **docker-compose profiles** для условного запуска сервисов
- **Makefile** для автоматизации типичных задач
- **GitHub Actions** для CI/CD
- **Мониторинг** с Prometheus и Grafana
- **Логирование** с ELK/Loki стеком

Следование этим практикам поможет создать надежную, масштабируемую и безопасную инфраструктуру для ваших веб-сервисов.

---

*Интересуетесь другими аспектами DevOps? Читайте наши статьи о [Docker](/tags/docker) и [контейнеризации](/tags/контейнеризация).*