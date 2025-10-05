---
title: "ARG в Dockerfile и args в Docker Compose: Полное руководство"
description: "Изучаем ключевое слово ARG в Dockerfile и args в docker-compose: различия, практические примеры и сценарии использования"
date: 2025-01-13
tldr: "ARG и args - мощные инструменты для параметризации Docker образов и сервисов"
draft: false
tags: ["docker", "dockerfile", "docker-compose", "контейнеризация", "devops"]
toc: true
---

# ARG в Dockerfile и args в Docker Compose: Полное руководство

Параметризация Docker образов и сервисов — это ключевой навык для создания гибких и переиспользуемых решений. В этой статье мы подробно разберем использование `ARG` в Dockerfile и `args` в docker-compose, их различия и практические сценарии применения.

## Что такое ARG в Dockerfile?

**ARG** — это директива Dockerfile, которая определяет переменную времени сборки (build-time variable). Эти переменные доступны только во время создания образа и не сохраняются в финальном образе.

{{< note >}}
ARG переменные доступны только во время сборки образа (`docker build`) и не влияют на время выполнения контейнера (`docker run`).
{{< /note >}}

### Синтаксис ARG

```dockerfile
# Определение ARG без значения по умолчанию
ARG VARIABLE_NAME

# Определение ARG со значением по умолчанию
ARG VARIABLE_NAME=default_value

# Использование ARG
RUN echo "Value: $VARIABLE_NAME"
```

### Базовый пример ARG

```dockerfile
# Dockerfile
FROM ubuntu:20.04

# Определяем аргументы
ARG NODE_VERSION=16
ARG APP_USER=appuser

# Используем аргументы при установке
RUN apt-get update && \
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y nodejs

# Создаем пользователя
RUN useradd -m ${APP_USER}
USER ${APP_USER}

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

EXPOSE 3000
CMD ["npm", "start"]
```

### Сборка с передачей аргументов

```bash
# Сборка с аргументами по умолчанию
docker build -t myapp:latest .

# Сборка с кастомными аргументами
docker build -t myapp:node18 --build-arg NODE_VERSION=18 --build-arg APP_USER=webapp .

# Просмотр истории образа с аргументами
docker history myapp:node18
```

## Что такое args в docker-compose?

**args** в docker-compose — это способ передачи build-time аргументов в Dockerfile при сборке образа через docker-compose. Это аналог `--build-arg` в команде `docker build`.

### Синтаксис args в docker-compose

```yaml
version: '3.8'
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        - NODE_VERSION=18
        - APP_USER=webapp
    # или в виде карты
    build:
      context: .
      args:
        NODE_VERSION: 18
        APP_USER: webapp
```

## Основные различия ARG и args

| Аспект | ARG в Dockerfile | args в docker-compose |
|--------|------------------|----------------------|
| **Область действия** | Только время сборки | Передача в ARG при сборке |
| **Видимость** | Внутри Dockerfile | В секции build сервиса |
| **Наследование** | Не наследуются между стадиями | Передаются в Dockerfile |
| **Безопасность** | Видны в истории образа | Видны в docker-compose.yml |
| **Переопределение** | `--build-arg` при сборке | Переменные окружения |

## Жизненный цикл ARG переменных

### Область видимости ARG

```dockerfile
# ARG до FROM - глобальная переменная
ARG GLOBAL_VERSION=latest

FROM ubuntu:${GLOBAL_VERSION}

# ARG после FROM - локальная для данной стадии
ARG LOCAL_VAR=value

# Переиспользование глобальной переменной
ARG GLOBAL_VERSION
RUN echo "Using version: ${GLOBAL_VERSION}"

# Многостадийная сборка
FROM node:16 AS builder
ARG BUILD_ENV=production
RUN echo "Building for: ${BUILD_ENV}"

FROM ubuntu:20.04 AS runtime
# BUILD_ENV здесь недоступна!
ARG BUILD_ENV  # Нужно переопределить
RUN echo "Runtime env: ${BUILD_ENV}"
```

### Предопределенные ARG

Docker предоставляет несколько предопределенных ARG переменных:

```dockerfile
# Автоматически доступные ARG
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH
ARG BUILDPLATFORM
ARG BUILDOS
ARG BUILDARCH

FROM ubuntu:20.04
RUN echo "Building for: ${TARGETPLATFORM}"
RUN echo "Target OS: ${TARGETOS}"
RUN echo "Target Architecture: ${TARGETARCH}"
```

## Практические примеры

### 1. Параметризация версий зависимостей

```dockerfile
# Dockerfile.multi-version
FROM ubuntu:20.04

# Версии ПО как аргументы
ARG PYTHON_VERSION=3.9
ARG NODE_VERSION=16
ARG GO_VERSION=1.19

# Установка Python
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-pip

# Установка Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y nodejs

# Установка Go
RUN wget https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz

ENV PATH=$PATH:/usr/local/go/bin
```

```yaml
# docker-compose.dev.yml
version: '3.8'
services:
  development:
    build:
      context: .
      dockerfile: Dockerfile.multi-version
      args:
        PYTHON_VERSION: 3.10
        NODE_VERSION: 18
        GO_VERSION: 1.20
    volumes:
      - .:/workspace
    working_dir: /workspace
```

### 2. Условная установка пакетов

```dockerfile
# Dockerfile.conditional
FROM ubuntu:20.04

ARG INSTALL_DEV_TOOLS=false
ARG INSTALL_MONITORING=true
ARG ENVIRONMENT=production

# Условная установка инструментов разработки
RUN if [ "$INSTALL_DEV_TOOLS" = "true" ]; then \
        apt-get update && apt-get install -y \
        vim \
        git \
        curl \
        htop \
        tree; \
    fi

# Условная установка мониторинга
RUN if [ "$INSTALL_MONITORING" = "true" ]; then \
        apt-get update && apt-get install -y \
        prometheus-node-exporter \
        collectd; \
    fi

# Разные конфигурации для разных сред
COPY config/app.${ENVIRONMENT}.conf /etc/app/app.conf

RUN echo "Built for environment: ${ENVIRONMENT}"
```

```yaml
# docker-compose.development.yml
version: '3.8'
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.conditional
      args:
        INSTALL_DEV_TOOLS: "true"
        INSTALL_MONITORING: "false"
        ENVIRONMENT: "development"
    ports:
      - "3000:3000"

# docker-compose.production.yml
version: '3.8'
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.conditional
      args:
        INSTALL_DEV_TOOLS: "false"
        INSTALL_MONITORING: "true"
        ENVIRONMENT: "production"
    ports:
      - "80:3000"
```

### 3. Параметризация пользователя и прав

```dockerfile
# Dockerfile.user-config
FROM ubuntu:20.04

# Параметры пользователя
ARG USER_NAME=appuser
ARG USER_UID=1000
ARG USER_GID=1000
ARG USER_HOME=/home/${USER_NAME}

# Создание группы и пользователя
RUN groupadd -g ${USER_GID} ${USER_NAME} && \
    useradd -u ${USER_UID} -g ${USER_GID} -m -d ${USER_HOME} -s /bin/bash ${USER_NAME}

# Установка sudo для пользователя (опционально)
ARG GRANT_SUDO=false
RUN if [ "$GRANT_SUDO" = "true" ]; then \
        apt-get update && apt-get install -y sudo && \
        echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers; \
    fi

# Переключение на пользователя
USER ${USER_NAME}
WORKDIR ${USER_HOME}

# Установка приложения от имени пользователя
COPY --chown=${USER_UID}:${USER_GID} app/ ./app/
```

```bash
# Сборка для разных пользователей
docker build -t myapp:dev \
  --build-arg USER_NAME=developer \
  --build-arg USER_UID=$(id -u) \
  --build-arg USER_GID=$(id -g) \
  --build-arg GRANT_SUDO=true \
  .

docker build -t myapp:prod \
  --build-arg USER_NAME=appuser \
  --build-arg USER_UID=1001 \
  --build-arg USER_GID=1001 \
  .
```

## Продвинутые сценарии

### 1. Многостадийная сборка с аргументами

```dockerfile
# Dockerfile.multistage
# Аргументы доступные глобально
ARG NODE_VERSION=16
ARG ALPINE_VERSION=3.16

# Стадия сборки
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION} AS builder

ARG BUILD_ENV=production
ARG API_URL=http://localhost:3001

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .

# Сборка приложения с параметрами
RUN REACT_APP_API_URL=${API_URL} \
    NODE_ENV=${BUILD_ENV} \
    npm run build

# Продакшн стадия
FROM nginx:alpine AS production

ARG NGINX_VERSION
ARG BUILD_ENV

# Копирование собранного приложения
COPY --from=builder /app/build /usr/share/nginx/html

# Условное копирование конфигурации nginx
COPY config/nginx.${BUILD_ENV}.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  frontend:
    build:
      context: .
      dockerfile: Dockerfile.multistage
      target: production  # Явное указание стадии
      args:
        NODE_VERSION: 18
        BUILD_ENV: ${BUILD_ENV:-production}
        API_URL: ${API_URL:-http://api:3001}
    environment:
      - BUILD_ENV=${BUILD_ENV:-production}
    ports:
      - "80:80"
    depends_on:
      - api
      
  api:
    build:
      context: ./api
      args:
        NODE_VERSION: 18
    ports:
      - "3001:3001"
```

### 2. Секреты и ARG (безопасность)

```dockerfile
# Dockerfile.secrets
FROM ubuntu:20.04

# ❌ Небезопасно - секреты видны в истории образа
ARG DATABASE_PASSWORD=secret123
RUN echo "DB_PASSWORD=${DATABASE_PASSWORD}" > /app/config

# ✅ Безопасно - используем Docker BuildKit секреты
RUN --mount=type=secret,id=db_password \
    DB_PASSWORD=$(cat /run/secrets/db_password) && \
    echo "DB_PASSWORD=${DB_PASSWORD}" > /app/config
```

```bash
# Использование секретов с BuildKit
echo "super_secret_password" | docker secret create db_password -

# Сборка с секретами
DOCKER_BUILDKIT=1 docker build --secret id=db_password,src=password.txt -t secure-app .
```

### 3. Условные Dockerfile на основе ARG

```dockerfile
# Dockerfile.platform
ARG TARGET_PLATFORM=linux/amd64

# Базовый образ в зависимости от платформы
FROM --platform=${TARGET_PLATFORM} ubuntu:20.04 AS base

ARG TARGETARCH
ARG PACKAGES_ARCH

# Установка пакетов в зависимости от архитектуры
RUN case ${TARGETARCH} in \
      "amd64")  PACKAGES_ARCH="x86_64" ;; \
      "arm64")  PACKAGES_ARCH="aarch64" ;; \
      "arm")    PACKAGES_ARCH="armhf" ;; \
      *)        PACKAGES_ARCH="x86_64" ;; \
    esac && \
    echo "Installing packages for: ${PACKAGES_ARCH}"

# Скачивание бинарников под конкретную архитектуру
ARG APP_VERSION=1.2.3
RUN curl -L "https://releases.example.com/v${APP_VERSION}/app-${PACKAGES_ARCH}.tar.gz" \
    -o /tmp/app.tar.gz && \
    tar -xzf /tmp/app.tar.gz -C /usr/local/bin/
```

## Использование переменных окружения с ARG

### Передача переменных окружения как ARG

```dockerfile
# Dockerfile.env-integration
FROM node:16

# ARG может принимать значения из переменных окружения
ARG NODE_ENV
ARG API_URL
ARG BUILD_VERSION

# Установка переменных окружения на основе ARG
ENV NODE_ENV=${NODE_ENV}
ENV REACT_APP_API_URL=${API_URL}
ENV BUILD_VERSION=${BUILD_VERSION}

WORKDIR /app
COPY package*.json ./

# Условная установка зависимостей
RUN if [ "$NODE_ENV" = "development" ]; then \
        npm install; \
    else \
        npm ci --only=production; \
    fi

COPY . .

# Сборка в зависимости от окружения
RUN npm run build:${NODE_ENV}
```

```yaml
# docker-compose.yml с переменными окружения
version: '3.8'
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.env-integration
      args:
        NODE_ENV: ${NODE_ENV:-production}
        API_URL: ${API_URL:-http://localhost:3001}
        BUILD_VERSION: ${BUILD_VERSION:-latest}
    environment:
      - NODE_ENV=${NODE_ENV:-production}
      - PORT=3000
```

```bash
# .env файл
NODE_ENV=development
API_URL=http://dev-api.example.com
BUILD_VERSION=1.0.0-dev

# Запуск с переменными окружения
docker-compose up --build
```

## Отладка и инспекция ARG

### Просмотр аргументов в образе

```bash
# Просмотр истории образа
docker history myapp:latest

# Инспекция образа
docker inspect myapp:latest

# Просмотр labels (если ARG используется в LABEL)
docker inspect --format='{{.Config.Labels}}' myapp:latest
```

### Отладочные техники

```dockerfile
# Dockerfile.debug
FROM ubuntu:20.04

ARG DEBUG_MODE=false
ARG LOG_LEVEL=info
ARG APP_VERSION

# Вывод всех аргументов для отладки
RUN echo "=== Build Arguments ===" && \
    echo "DEBUG_MODE: ${DEBUG_MODE}" && \
    echo "LOG_LEVEL: ${LOG_LEVEL}" && \
    echo "APP_VERSION: ${APP_VERSION}" && \
    echo "TARGETPLATFORM: ${TARGETPLATFORM}" && \
    echo "======================="

# Условный вывод отладочной информации
RUN if [ "$DEBUG_MODE" = "true" ]; then \
        apt-get update && apt-get install -y \
        strace \
        gdb \
        valgrind; \
    fi
```

## Лучшие практики

### 1. Документирование аргументов

```dockerfile
# Dockerfile.documented
FROM ubuntu:20.04

# Версия Node.js для установки (поддерживаются: 14, 16, 18, 20)
ARG NODE_VERSION=16

# Среда выполнения (development, staging, production)
ARG ENVIRONMENT=production

# Включение инструментов разработки (true/false)
ARG ENABLE_DEV_TOOLS=false

# Пользователь приложения (по умолчанию: appuser)
ARG APP_USER=appuser

# Порт приложения (по умолчанию: 3000)
ARG APP_PORT=3000

LABEL description="Параметризованный образ приложения"
LABEL node.version="${NODE_VERSION}"
LABEL environment="${ENVIRONMENT}"
LABEL app.port="${APP_PORT}"
```

### 2. Валидация аргументов

```dockerfile
# Dockerfile.validated
FROM ubuntu:20.04

ARG NODE_VERSION=16
ARG ENVIRONMENT=production

# Валидация NODE_VERSION
RUN case "${NODE_VERSION}" in \
      "14"|"16"|"18"|"20") \
        echo "✓ Valid Node.js version: ${NODE_VERSION}" ;; \
      *) \
        echo "✗ Unsupported Node.js version: ${NODE_VERSION}" && \
        echo "Supported versions: 14, 16, 18, 20" && \
        exit 1 ;; \
    esac

# Валидация ENVIRONMENT
RUN case "${ENVIRONMENT}" in \
      "development"|"staging"|"production") \
        echo "✓ Valid environment: ${ENVIRONMENT}" ;; \
      *) \
        echo "✗ Invalid environment: ${ENVIRONMENT}" && \
        echo "Valid environments: development, staging, production" && \
        exit 1 ;; \
    esac
```

### 3. Безопасность ARG

```dockerfile
# Dockerfile.secure
FROM ubuntu:20.04

# ✅ Хорошо - несекретные данные
ARG APP_VERSION=1.0.0
ARG BUILD_DATE
ARG GIT_COMMIT

# ❌ Плохо - секретные данные (видны в docker history)
ARG DATABASE_PASSWORD

# ✅ Лучше - использовать Docker Secrets или ENV во время выполнения
# ARG используется только для несекретных build-time данных

LABEL version="${APP_VERSION}"
LABEL build-date="${BUILD_DATE}"
LABEL git-commit="${GIT_COMMIT}"
```

## Автоматизация с Makefile

```makefile
# Makefile
.PHONY: build-dev build-prod build-test

# Переменные по умолчанию
NODE_VERSION ?= 18
ENVIRONMENT ?= development
BUILD_VERSION ?= $(shell git describe --tags --always)
BUILD_DATE ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# Сборка для разработки
build-dev:
	docker build \
		--build-arg NODE_VERSION=$(NODE_VERSION) \
		--build-arg ENVIRONMENT=development \
		--build-arg BUILD_VERSION=$(BUILD_VERSION) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg ENABLE_DEV_TOOLS=true \
		-t myapp:dev .

# Сборка для продакшна
build-prod:
	docker build \
		--build-arg NODE_VERSION=$(NODE_VERSION) \
		--build-arg ENVIRONMENT=production \
		--build-arg BUILD_VERSION=$(BUILD_VERSION) \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg ENABLE_DEV_TOOLS=false \
		-t myapp:$(BUILD_VERSION) \
		-t myapp:latest .

# Сборка для тестов
build-test:
	docker-compose \
		-f docker-compose.yml \
		-f docker-compose.test.yml \
		build \
		--build-arg NODE_VERSION=16 \
		--build-arg ENVIRONMENT=test

# Информация о сборке
info:
	@echo "BUILD_VERSION: $(BUILD_VERSION)"
	@echo "BUILD_DATE: $(BUILD_DATE)"
	@echo "NODE_VERSION: $(NODE_VERSION)"
	@echo "ENVIRONMENT: $(ENVIRONMENT)"
```

## CI/CD интеграция

### GitHub Actions

```yaml
# .github/workflows/build.yml
name: Build Docker Images

on:
  push:
    branches: [main, develop]
    tags: ['v*']
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [development, staging, production]
        node-version: [16, 18, 20]
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Build image
      run: |
        docker build \
          --build-arg NODE_VERSION=${{ matrix.node-version }} \
          --build-arg ENVIRONMENT=${{ matrix.environment }} \
          --build-arg BUILD_VERSION=${GITHUB_SHA::8} \
          --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
          --build-arg GIT_COMMIT=${GITHUB_SHA} \
          -t myapp:${{ matrix.environment }}-node${{ matrix.node-version }} \
          .
    
    - name: Test image
      run: |
        docker run --rm \
          myapp:${{ matrix.environment }}-node${{ matrix.node-version }} \
          npm test
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - deploy

variables:
  NODE_VERSION: "18"
  DOCKER_DRIVER: overlay2

.build_template: &build_template
  stage: build
  image: docker:20.10.16
  services:
    - docker:20.10.16-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - |
      docker build \
        --build-arg NODE_VERSION=${NODE_VERSION} \
        --build-arg ENVIRONMENT=${ENVIRONMENT} \
        --build-arg BUILD_VERSION=${CI_COMMIT_SHA} \
        --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
        --build-arg GIT_COMMIT=${CI_COMMIT_SHA} \
        -t ${CI_REGISTRY_IMAGE}:${TAG} \
        .
    - docker push ${CI_REGISTRY_IMAGE}:${TAG}

build_development:
  <<: *build_template
  variables:
    ENVIRONMENT: development
    TAG: dev-${CI_COMMIT_SHORT_SHA}
  only:
    - develop

build_production:
  <<: *build_template
  variables:
    ENVIRONMENT: production
    TAG: ${CI_COMMIT_TAG}
  only:
    - tags
```

## Заключение

ARG в Dockerfile и args в docker-compose — это мощные инструменты для создания гибких и параметризованных Docker образов. Ключевые моменты:

### Основные принципы:

1. **ARG** используется только во время сборки образа
2. **args** в docker-compose передает аргументы в ARG
3. **Безопасность**: никогда не используйте ARG для секретов
4. **Документация**: всегда документируйте доступные аргументы
5. **Валидация**: проверяйте корректность переданных значений

### Лучшие практики:

- Используйте значения по умолчанию для ARG
- Группируйте связанные аргументы
- Валидируйте входные данные
- Документируйте назначение каждого аргумента
- Тестируйте разные комбинации аргументов

### Типичные сценарии использования:

- Параметризация версий зависимостей
- Условная установка пакетов
- Настройка под разные окружения
- Кроссплатформенная сборка
- Оптимизация для CI/CD пайплайнов

Правильное использование ARG и args делает ваши Docker образы более гибкими, переиспользуемыми и подходящими для различных сред развертывания.

---

*Интересуетесь другими аспектами Docker? Читайте наши статьи о [контейнеризации](/tags/контейнеризация) и [DevOps](/tags/devops).*