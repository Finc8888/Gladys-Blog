#!/bin/bash

# Gladys Blog Docker Entrypoint Script
# This script initializes and starts the Nginx server for the Hugo blog

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
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

# Configuration
NGINX_CONF="/etc/nginx/nginx.conf"
SITE_ROOT="/usr/share/nginx/html"
NGINX_PID="/var/run/nginx.pid"

# Banner
echo "========================================"
echo "🚀 GladysAI-BlogGladysAI-Blog Container Starting"
echo "========================================"

log "Initializing Gladys Blog container..."

# Check if running as root (security warning)
if [ "$(id -u)" = "0" ]; then
    warning "Running as root user - not recommended for production"
fi

# Environment information
log "Environment information:"
log "- User: $(whoami) (UID: $(id -u))"
log "- Working directory: $(pwd)"
log "- Nginx version: $(nginx -v 2>&1)"
log "- System: $(uname -s) $(uname -r)"

# Validate Nginx configuration
log "Validating Nginx configuration..."
if ! nginx -t -c "$NGINX_CONF" 2>/dev/null; then
    error "Nginx configuration test failed!"
fi
success "Nginx configuration is valid"

# Check if site files exist
log "Checking site files..."
if [ ! -d "$SITE_ROOT" ]; then
    error "Site root directory not found: $SITE_ROOT"
fi

if [ ! -f "$SITE_ROOT/index.html" ]; then
    error "Main index.html file not found!"
fi

# Count and report site files
FILE_COUNT=$(find "$SITE_ROOT" -type f | wc -l)
TOTAL_SIZE=$(du -sh "$SITE_ROOT" 2>/dev/null | cut -f1 || echo "unknown")
success "Site files are ready"
log "- Files count: $FILE_COUNT"
log "- Total size: $TOTAL_SIZE"

# Check specific important files
IMPORTANT_FILES=("index.html" "robots.txt")
for file in "${IMPORTANT_FILES[@]}"; do
    if [ -f "$SITE_ROOT/$file" ]; then
        log "- ✓ $file found"
    else
        warning "$file not found (optional)"
    fi
done

# Create necessary directories if they don't exist
log "Setting up runtime directories..."
mkdir -p /var/cache/nginx/client_temp \
         /var/cache/nginx/proxy_temp \
         /var/cache/nginx/fastcgi_temp \
         /var/cache/nginx/uwsgi_temp \
         /var/cache/nginx/scgi_temp \
         /var/log/nginx \
         /var/run

# Set proper permissions (if running as root)
if [ "$(id -u)" = "0" ]; then
    log "Setting up permissions..."
    chown -R nginx:nginx /var/cache/nginx /var/log/nginx
fi

# Environment variables setup
export NGINX_WORKER_PROCESSES=${NGINX_WORKER_PROCESSES:-auto}
export NGINX_WORKER_CONNECTIONS=${NGINX_WORKER_CONNECTIONS:-1024}
export NGINX_KEEPALIVE_TIMEOUT=${NGINX_KEEPALIVE_TIMEOUT:-65}

log "Nginx runtime configuration:"
log "- Worker processes: $NGINX_WORKER_PROCESSES"
log "- Worker connections: $NGINX_WORKER_CONNECTIONS"
log "- Keepalive timeout: $NGINX_KEEPALIVE_TIMEOUT"

# Test basic functionality
log "Performing pre-start tests..."

# Test if we can bind to port 80
if command -v nc >/dev/null 2>&1; then
    if nc -z localhost 80 2>/dev/null; then
        warning "Port 80 is already in use"
    fi
fi

# Clean up any existing PID file
if [ -f "$NGINX_PID" ]; then
    log "Cleaning up existing PID file..."
    rm -f "$NGINX_PID"
fi

# Signal handlers for graceful shutdown
trap 'log "Received SIGTERM, shutting down gracefully..."; nginx -s quit; exit 0' TERM
trap 'log "Received SIGINT, shutting down gracefully..."; nginx -s quit; exit 0' INT

# Health check function (for internal use)
health_check() {
    local max_attempts=10
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost/health >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
        attempt=$((attempt + 1))
    done
    return 1
}

# Pre-compress static files if gzip is available and files aren't already compressed
if command -v gzip >/dev/null 2>&1; then
    log "Pre-compressing static files..."
    find "$SITE_ROOT" -type f \( -name "*.html" -o -name "*.css" -o -name "*.js" -o -name "*.xml" -o -name "*.json" \) \
        ! -name "*.gz" -exec bash -c 'gzip -9 -c "$1" > "$1.gz" 2>/dev/null || true' _ {} \;
    success "Static files pre-compressed"
fi

# Final pre-flight check
log "Running final pre-flight check..."
if [ ! -r "$NGINX_CONF" ]; then
    error "Cannot read Nginx configuration file: $NGINX_CONF"
fi

# Display startup summary
echo "========================================"
success "All checks passed! Starting Nginx..."
echo "========================================"
log "Site URL: http://localhost/"
log "Health check: http://localhost/health"
log "Status endpoint: http://localhost/status"
echo "========================================"

# Start Nginx
log "Starting Nginx server..."
exec nginx -g "daemon off;"

# This line should never be reached
error "Nginx process exited unexpectedly!"
