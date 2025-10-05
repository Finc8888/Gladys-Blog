#!/bin/bash

# Local deployment script for GladysAI-Blog
# Usage: ./local-deploy.sh [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="gladys-blog"
CONTAINER_NAME="gladys-blog-local-dev"
PORT="80"
BUILD_CONTEXT="."
DOCKERFILE="deploy/Dockerfile.prod"

# Functions
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

show_help() {
    cat << EOF
🚀 Gladys Blog - Local Deployment

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help
    -p, --port PORT     Port to run on (default: 80)
    -d, --dev          Development mode (port 8080, hot reload)
    -b, --build-only   Only build image, don't run
    -c, --clean        Clean all containers and images
    -l, --logs         Show container logs
    -s, --status       Show container status
    --no-cache         Build without using Docker cache
    --debug            Enable debug mode

EXAMPLES:
    $0                 # Standard deployment on port 80
    $0 -p 8080         # Deploy on port 8080
    $0 -d              # Development mode
    $0 -c              # Clean all resources
    $0 -l              # Show logs
EOF
}

check_requirements() {
    log "Checking requirements..."

    if ! command -v docker &> /dev/null; then
        error "Docker is not installed"
    fi

    if ! docker info &> /dev/null; then
        error "Docker is not running"
    fi

    if [ ! -f "$DOCKERFILE" ]; then
        error "Dockerfile not found: $DOCKERFILE"
    fi

    if [ ! -d "blog" ]; then
        error "Blog directory not found"
    fi

    success "All requirements met"
}

cleanup_containers() {
    log "Cleaning up old containers and images..."

    # Stop container
    if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
        log "Stopping container $CONTAINER_NAME..."
        docker stop "$CONTAINER_NAME" || true
    fi

    # Remove container
    if docker ps -aq -f name="$CONTAINER_NAME" | grep -q .; then
        log "Removing container $CONTAINER_NAME..."
        docker rm "$CONTAINER_NAME" || true
    fi

    # Remove old images (if clean flag is set)
    if [ "$CLEAN_ALL" = true ]; then
        log "Removing old images..."
        docker images "$IMAGE_NAME" -q | xargs -r docker rmi || true
        docker system prune -f || true
        success "Cleanup completed"
        exit 0
    fi
}

build_image() {
    log "Building Docker image..."

    local build_args=""
    if [ "$NO_CACHE" = true ]; then
        build_args="--no-cache"
    fi

    # Create temporary Dockerfile if development mode
    if [ "$DEV_MODE" = true ]; then
        log "Creating Dockerfile for development..."
        cat > Dockerfile.dev << 'EOF'
FROM alpine:latest
WORKDIR /blog
RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community hugo
COPY blog/ ./
EXPOSE 1313
CMD ["hugo", "server", "--bind", "0.0.0.0", "--port", "1313", "--disableFastRender"]
EOF
        DOCKERFILE="Dockerfile.dev"
        PORT="8080"
        CONTAINER_PORT="1313"
    else
        CONTAINER_PORT="80"
    fi

    # Build image
    if ! docker build $build_args -t "$IMAGE_NAME:latest" -f "$DOCKERFILE" "$BUILD_CONTEXT"; then
        error "Error building image"
    fi

    # Clean up temporary file
    if [ "$DEV_MODE" = true ]; then
        rm -f Dockerfile.dev
    fi

    success "Image built: $IMAGE_NAME:latest"

    # Show image size
    local image_size=$(docker images "$IMAGE_NAME:latest" --format "{{.Size}}")
    log "Image size: $image_size"
}

run_container() {
    log "Starting container..."

    local docker_args=""
    local volume_args=""

    if [ "$DEV_MODE" = true ]; then
        # In development mode mount directory for hot reload
        volume_args="-v $(pwd)/blog:/blog"
        docker_args="--name $CONTAINER_NAME-dev"
        CONTAINER_NAME="$CONTAINER_NAME-dev"
    else
        docker_args="--name $CONTAINER_NAME --restart unless-stopped"
    fi

    # Check if port is free
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        warning "Port $PORT is already in use"
        local pid=$(lsof -Pi :$PORT -sTCP:LISTEN -t)
        log "Process using port: $(ps -p $pid -o comm=)"

        read -p "Do you want to forcefully stop the process? (y/N): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            kill -9 $pid || true
            sleep 2
        else
            error "Cannot start on occupied port"
        fi
    fi

    # Start container
    if ! docker run -d \
        $docker_args \
        -p "$PORT:$CONTAINER_PORT" \
        --memory="512m" \
        --cpus="1.0" \
        --log-driver json-file \
        --log-opt max-size=10m \
        --log-opt max-file=3 \
        $volume_args \
        "$IMAGE_NAME:latest"; then
        error "Error starting container"
    fi

    success "Container started: $CONTAINER_NAME"
    log "Port: $PORT"
    log "URL: http://localhost:$PORT"
}

health_check() {
    log "Checking application health..."

    local max_attempts=30
    local attempt=1
    local health_endpoint="health"

    if [ "$DEV_MODE" = true ]; then
        # In development mode Hugo may take longer to start
        max_attempts=60
        health_endpoint=""
    fi

    while [ $attempt -le $max_attempts ]; do
        if curl -f "http://localhost:$PORT/$health_endpoint" >/dev/null 2>&1; then
            success "Application is ready!"
            log "Attempts required: $attempt"
            return 0
        fi

        printf "\r${YELLOW}⏳ Waiting for startup... ($attempt/$max_attempts)${NC}"
        sleep 2
        attempt=$((attempt + 1))
    done

    echo "" # New line after progress
    error "Application not responding after $max_attempts attempts"
}

show_status() {
    log "Container status:"

    if docker ps --filter name="$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "$CONTAINER_NAME"; then
        docker ps --filter name="$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        success "Container is running"

        # Show resource usage
        local stats=$(docker stats "$CONTAINER_NAME" --no-stream --format "CPU: {{.CPUPerc}}, Memory: {{.MemUsage}}")
        log "Resources: $stats"

        # Show last 10 lines of logs
        log "Recent logs:"
        docker logs --tail 10 "$CONTAINER_NAME"

    else
        warning "Container is not running"

        # Show all containers with this name
        if docker ps -a --filter name="$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}" | grep -q "$CONTAINER_NAME"; then
            log "Container history:"
            docker ps -a --filter name="$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}"
        fi
    fi
}

show_logs() {
    if docker ps --filter name="$CONTAINER_NAME" --format "{{.Names}}" | grep -q "$CONTAINER_NAME"; then
        log "Container logs for $CONTAINER_NAME:"
        docker logs -f "$CONTAINER_NAME"
    else
        error "Container $CONTAINER_NAME not found or not running"
    fi
}

run_tests() {
    log "Running basic tests..."

    # Test main page availability
    if curl -f "http://localhost:$PORT/" >/dev/null 2>&1; then
        success "Main page is available"
    else
        error "Main page is not available"
    fi

    # Test health endpoint (production only)
    if [ "$DEV_MODE" != true ]; then
        if curl -f "http://localhost:$PORT/health" >/dev/null 2>&1; then
            success "Health endpoint is working"
        else
            warning "Health endpoint is not available"
        fi
    fi

    # Test static resources
    local css_count=$(curl -s "http://localhost:$PORT/" | grep -o '\.css' | wc -l)
    local js_count=$(curl -s "http://localhost:$PORT/" | grep -o '\.js' | wc -l)

    log "CSS files found: $css_count"
    log "JS files found: $js_count"

    success "Basic tests passed"
}

show_info() {
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "📋 Information:"
    echo "   • URL: http://localhost:$PORT"
    echo "   • Container: $CONTAINER_NAME"
    echo "   • Image: $IMAGE_NAME:latest"
    echo "   • Mode: $([ "$DEV_MODE" = true ] && echo "Development" || echo "Production")"
    echo ""
    echo "🔧 Useful commands:"
    echo "   • Logs:     docker logs -f $CONTAINER_NAME"
    echo "   • Status:   docker ps --filter name=$CONTAINER_NAME"
    echo "   • Stop: docker stop $CONTAINER_NAME"
    echo "   • Restart: docker restart $CONTAINER_NAME"
    echo ""

    if [ "$DEV_MODE" = true ]; then
        echo "🛠️  Development mode:"
        echo "   • Files are synchronized automatically"
        echo "   • Changes will be visible immediately"
        echo ""
    fi

    echo "🌐 Open browser: http://localhost:$PORT"
    echo ""
}

# Parse arguments
DEV_MODE=false
BUILD_ONLY=false
CLEAN_ALL=false
SHOW_LOGS=false
SHOW_STATUS=false
NO_CACHE=false
DEBUG=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -d|--dev)
            DEV_MODE=true
            shift
            ;;
        -b|--build-only)
            BUILD_ONLY=true
            shift
            ;;
        -c|--clean)
            CLEAN_ALL=true
            shift
            ;;
        -l|--logs)
            SHOW_LOGS=true
            shift
            ;;
        -s|--status)
            SHOW_STATUS=true
            shift
            ;;
        --no-cache)
            NO_CACHE=true
            shift
            ;;
        --debug)
            DEBUG=true
            set -x
            shift
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Main logic
main() {
    echo "🚀 Gladys Blog - Local Deployment"
    echo "=================================="

    if [ "$SHOW_LOGS" = true ]; then
        show_logs
        exit 0
    fi

    if [ "$SHOW_STATUS" = true ]; then
        show_status
        exit 0
    fi

    check_requirements
    cleanup_containers
    build_image

    if [ "$BUILD_ONLY" = true ]; then
        success "Build completed. Image: $IMAGE_NAME:latest"
        exit 0
    fi

    run_container
    health_check
    run_tests
    show_info
}

# Error handling
trap 'error "Script interrupted. Cleaning up..."' ERR

# Run
main "$@"
