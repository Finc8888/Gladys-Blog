#!/bin/bash

# GladysAI-Blog SSL Deployment Script
# This script helps deploy the GladysAI-BlogGladysAI-Blog with SSL/HTTPS support

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
# Will be set dynamically based on Docker Compose version
COMPOSE_FILE=""
ENV_FILE="$PROJECT_ROOT/.env"
ENV_EXAMPLE="$PROJECT_ROOT/.env.ssl.example"

# Default values
DEFAULT_DOMAIN="localhost"
DEFAULT_EMAIL="admin@localhost"
DEFAULT_STAGING=0
DEFAULT_MODE="production"

# Functions for colored output
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1${NC}"
}

highlight() {
    echo -e "${PURPLE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Function to display usage
show_usage() {
    echo -e "${CYAN}Gladys Blog SSL Deployment Script${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS] [COMMAND]"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  setup           Interactive setup for SSL configuration"
    echo "  deploy          Deploy the SSL-enabled blog"
    echo "  dev             Start in development mode (HTTP only)"
    echo "  prod            Start in production mode with SSL"
    echo "  stop            Stop all services"
    echo "  restart         Restart all services"
    echo "  logs            Show logs from all services"
    echo "  status          Show status of all services"
    echo "  cert-renew      Manually renew SSL certificates"
    echo "  cert-info       Show SSL certificate information"
    echo "  backup          Backup SSL certificates and configuration"
    echo "  restore         Restore SSL certificates from backup"
    echo "  clean           Clean up containers and volumes"
    echo "  health          Check health of all services"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  -d, --domain DOMAIN     Set domain name"
    echo "  -e, --email EMAIL       Set email for Let's Encrypt"
    echo "  -s, --staging           Use Let's Encrypt staging environment"
    echo "  -f, --force             Force certificate renewal"
    echo "  -h, --help             Show this help message"
    echo "  -v, --verbose          Enable verbose output"
    echo "  --dev                   Use development configuration"
    echo "  --no-ssl               Disable SSL (HTTP only)"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 setup                           # Interactive setup"
    echo "  $0 deploy -d example.com -e admin@example.com"
    echo "  $0 prod --staging                  # Production with staging certs"
    echo "  $0 dev                             # Development mode"
    echo "  $0 cert-renew                      # Renew certificates"
    echo "  $0 logs                            # View logs"
    echo ""
}

# Function to check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check if docker-compose is installed
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check Docker Compose version compatibility
    local compose_version=$(docker-compose --version | grep -oE '[0-9]+\.[0-9]+' | head -1)
    local major_version=$(echo $compose_version | cut -d. -f1)
    local minor_version=$(echo $compose_version | cut -d. -f2)
    
    if [ "$major_version" -lt 2 ]; then
        warn "Docker Compose version $compose_version detected. Some features may not work."
        warn "For full compatibility, please upgrade to Docker Compose 2.0+"
        warn "Install command: sudo curl -L \"https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose"
        info "Continuing with compatibility mode..."
    else
        info "Docker Compose version $compose_version - Compatible"
    fi
    
    # Set the appropriate compose file
    set_compose_file

    # Check if we're in the right directory
    if [ ! -f "$COMPOSE_FILE" ]; then
        error "docker-compose.ssl.yaml not found. Please run this script from the project root."
        exit 1
    fi

    # Check if Hugo blog directory exists
    if [ ! -d "$PROJECT_ROOT/blog" ]; then
        error "Blog directory not found. Please ensure the Hugo blog is in the 'blog' directory."
        exit 1
    fi

    success "All prerequisites met"
}

# Function to determine which docker-compose file to use
set_compose_file() {
    if [ -n "$COMPOSE_FILE" ]; then
        return 0  # Already set
    fi
    
    local compose_version=$(docker-compose --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
    local major_version=$(echo $compose_version | cut -d. -f1)
    
    if [ "$major_version" -lt 2 ]; then
        COMPOSE_FILE="$PROJECT_ROOT/docker-compose.ssl.legacy.yaml"
        info "Using legacy Docker Compose file for version $compose_version"
    else
        COMPOSE_FILE="$PROJECT_ROOT/docker-compose.ssl.yaml"
        info "Using modern Docker Compose file for version $compose_version"
    fi
    
    # Verify the compose file exists
    if [ ! -f "$COMPOSE_FILE" ]; then
        error "Docker Compose file not found: $COMPOSE_FILE"
        exit 1
    fi
}

# Function to create .env file
create_env_file() {
    local domain="${1:-$DEFAULT_DOMAIN}"
    local email="${2:-$DEFAULT_EMAIL}"
    local staging="${3:-$DEFAULT_STAGING}"

    log "Creating environment configuration..."

    if [ ! -f "$ENV_FILE" ] || [ "$FORCE_CONFIG" = "1" ]; then
        cp "$ENV_EXAMPLE" "$ENV_FILE"

        # Update values in .env file
        sed -i "s/DOMAIN=localhost/DOMAIN=$domain/" "$ENV_FILE"
        sed -i "s/EMAIL=admin@localhost/EMAIL=$email/" "$ENV_FILE"
        sed -i "s/STAGING=0/STAGING=$staging/" "$ENV_FILE"

        success "Environment file created: $ENV_FILE"
    else
        info "Environment file already exists: $ENV_FILE"
    fi
}

# Function for interactive setup
interactive_setup() {
    highlight "=== Gladys Blog SSL Setup ==="
    echo ""

    # Domain configuration
    echo -e "${CYAN}Domain Configuration:${NC}"
    read -p "Enter your domain name (default: localhost): " input_domain
    DOMAIN="${input_domain:-$DEFAULT_DOMAIN}"

    # Email configuration
    echo -e "${CYAN}Email Configuration:${NC}"
    read -p "Enter your email for Let's Encrypt (default: admin@localhost): " input_email
    EMAIL="${input_email:-$DEFAULT_EMAIL}"

    # Staging configuration
    echo -e "${CYAN}Certificate Configuration:${NC}"
    echo "Use Let's Encrypt staging environment for testing?"
    echo "(Recommended for first-time setup)"
    read -p "Use staging? (y/N): " staging_choice
    if [[ $staging_choice =~ ^[Yy]$ ]]; then
        STAGING=1
    else
        STAGING=0
    fi

    # Mode selection
    echo -e "${CYAN}Deployment Mode:${NC}"
    echo "1) Development (HTTP only, hot reload)"
    echo "2) Production (HTTPS with SSL)"
    read -p "Select mode (1/2, default: 2): " mode_choice
    if [ "$mode_choice" = "1" ]; then
        MODE="development"
    else
        MODE="production"
    fi

    # Summary
    echo ""
    # Determine which compose file to use
    set_compose_file
    
    highlight "=== Configuration Summary ==="
    echo "Domain: $DOMAIN"
    echo "Email: $EMAIL"
    echo "Staging: $([ "$STAGING" = "1" ] && echo "Yes" || echo "No")"
    echo "Mode: $MODE"
    echo ""

    read -p "Proceed with this configuration? (Y/n): " confirm
    if [[ $confirm =~ ^[Nn]$ ]]; then
        warn "Setup cancelled by user"
        exit 0
    fi

    # Create configuration
    create_env_file "$DOMAIN" "$EMAIL" "$STAGING"

    success "Setup completed successfully!"
    echo ""
    info "Next steps:"
    echo "1. Run: $0 deploy"
    echo "2. Or run: $0 $MODE"
}

# Function to deploy the application
deploy() {
    log "Starting deployment..."

    check_prerequisites

    # Load environment variables
    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
        info "Loaded configuration from $ENV_FILE"
    else
        warn "No .env file found. Using defaults."
        create_env_file
        source "$ENV_FILE"
    fi

    # Build and start services
    log "Building and starting SSL-enabled services..."

    if [ "$MODE" = "development" ]; then
        docker-compose -f "$COMPOSE_FILE" up --build blog-dev
    else
        docker-compose -f "$COMPOSE_FILE" up --build -d blog-prod-ssl

        # Wait for service to be ready
        log "Waiting for service to be ready..."
        sleep 10

        # Check health
        check_health
    fi

    success "Deployment completed!"
}

# Function to start production mode
start_production() {
    log "Starting production mode with SSL..."

    check_prerequisites

    # Ensure .env exists
    if [ ! -f "$ENV_FILE" ]; then
        warn "No configuration found. Running setup..."
        interactive_setup
    fi

    # Load environment
    source "$ENV_FILE"

    # Check Docker Compose version and use appropriate method
    local compose_version=$(docker-compose --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
    local major_version=$(echo $compose_version | cut -d. -f1)
    
    if [ "$major_version" -lt 2 ]; then
        # Legacy version - start services individually
        log "Starting production services (legacy mode)"
        docker-compose -f "$COMPOSE_FILE" up --build -d blog-prod-ssl
        docker-compose -f "$COMPOSE_FILE" up -d certbot-renew
    else
        # Modern version with profiles
        docker-compose -f "$COMPOSE_FILE" --profile auto-renew up --build -d
    fi

    success "Production services started with SSL and auto-renewal"
    info "Services will automatically renew certificates"

    # Show status
    show_status
}

# Function to start development mode
start_development() {
    log "Starting development mode..."

    check_prerequisites

    docker-compose -f "$COMPOSE_FILE" up --build blog-dev
}

# Function to stop services
stop_services() {
    log "Stopping all services..."

    docker-compose -f "$COMPOSE_FILE" --profile "*" down

    success "All services stopped"
}

# Function to restart services
restart_services() {
    log "Restarting services..."

    stop_services
    sleep 2
    deploy
}

# Function to show logs
show_logs() {
    local service="${1:-}"

    if [ -n "$service" ]; then
        docker-compose -f "$COMPOSE_FILE" logs -f "$service"
    else
        docker-compose -f "$COMPOSE_FILE" logs -f
    fi
}

# Function to show status
show_status() {
    log "Checking service status..."

    docker-compose -f "$COMPOSE_FILE" ps

    echo ""
    highlight "=== Health Check Results ==="

    # Check if blog service is running
    if docker-compose -f "$COMPOSE_FILE" ps | grep -q "blog-prod-ssl.*Up"; then
        success "Blog service is running"

        # Test HTTP redirect
        if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "301\|200"; then
            success "HTTP endpoint responding"
        else
            warn "HTTP endpoint not responding"
        fi

        # Test HTTPS
        if curl -s -k -o /dev/null -w "%{http_code}" https://localhost | grep -q "200"; then
            success "HTTPS endpoint responding"
        else
            warn "HTTPS endpoint not responding"
        fi

    elif docker-compose -f "$COMPOSE_FILE" ps | grep -q "blog-dev.*Up"; then
        success "Development service is running"

        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 | grep -q "200"; then
            success "Development endpoint responding"
        else
            warn "Development endpoint not responding"
        fi
    else
        warn "No blog services are running"
    fi
}

# Function to check health
check_health() {
    log "Performing health checks..."

    local max_attempts=30
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if curl -s -f -k https://localhost/health >/dev/null 2>&1; then
            success "HTTPS health check passed"
            return 0
        elif curl -s -f http://localhost/health >/dev/null 2>&1; then
            success "HTTP health check passed"
            return 0
        fi

        attempt=$((attempt + 1))
        info "Health check attempt $attempt/$max_attempts..."
        sleep 2
    done

    error "Health check failed after $max_attempts attempts"
    return 1
}

# Function to renew certificates
renew_certificates() {
    log "Manually renewing SSL certificates..."

    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
    fi

    # Run certbot renewal
    if docker-compose -f "$COMPOSE_FILE" ps | grep -q certbot; then
        docker-compose -f "$COMPOSE_FILE" exec certbot certbot renew
    else
        docker-compose -f "$COMPOSE_FILE" run --rm certbot certbot renew
    fi

    # Restart nginx to reload certificates
    docker-compose -f "$COMPOSE_FILE" restart blog-prod-ssl

    success "Certificate renewal completed"
}

# Function to show certificate information
show_cert_info() {
    log "Retrieving SSL certificate information..."

    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
        local domain="${DOMAIN:-localhost}"
    else
        local domain="localhost"
    fi

    # Check if certificate exists
    if docker-compose -f "$COMPOSE_FILE" exec blog-prod-ssl test -f "/etc/letsencrypt/live/$domain/fullchain.pem" 2>/dev/null; then
        echo ""
        highlight "=== Certificate Information ==="
        docker-compose -f "$COMPOSE_FILE" exec blog-prod-ssl openssl x509 -in "/etc/letsencrypt/live/$domain/fullchain.pem" -noout -text | grep -E "(Subject:|Not Before|Not After|DNS:)"
        echo ""

        # Check expiry
        local days_until_expiry=$(docker-compose -f "$COMPOSE_FILE" exec blog-prod-ssl openssl x509 -in "/etc/letsencrypt/live/$domain/fullchain.pem" -noout -checkend 0 && echo "Valid" || echo "Expired")
        if [ "$days_until_expiry" = "Valid" ]; then
            success "Certificate is valid"
        else
            error "Certificate has expired"
        fi
    else
        warn "No SSL certificate found for domain: $domain"
    fi
}

# Function to backup certificates
backup_certificates() {
    local backup_dir="$PROJECT_ROOT/ssl-backup-$(date +%Y%m%d-%H%M%S)"

    log "Creating SSL certificate backup..."

    mkdir -p "$backup_dir"

    # Backup certificates
    docker-compose -f "$COMPOSE_FILE" exec blog-prod-ssl tar czf - /etc/letsencrypt | tar xzf - -C "$backup_dir"

    # Backup configuration
    cp "$ENV_FILE" "$backup_dir/.env.backup" 2>/dev/null || true
    cp "$COMPOSE_FILE" "$backup_dir/docker-compose.ssl.yaml.backup"

    success "Backup created: $backup_dir"
}

# Function to clean up
cleanup() {
    log "Cleaning up containers and volumes..."

    read -p "This will remove all containers, images, and volumes. Continue? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        warn "Cleanup cancelled"
        return 0
    fi

    # Stop and remove containers (compatible with all versions)
    docker-compose -f "$COMPOSE_FILE" down -v --remove-orphans
    
    # Remove images
    docker-compose -f "$COMPOSE_FILE" down --rmi all

    success "Cleanup completed"
}

# Main script logic
main() {
    local command="${1:-}"
    shift || true

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--domain)
                DOMAIN="$2"
                shift 2
                ;;
            -e|--email)
                EMAIL="$2"
                shift 2
                ;;
            -s|--staging)
                STAGING=1
                shift
                ;;
            -f|--force)
                FORCE_CONFIG=1
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                set -x
                shift
                ;;
            --dev)
                MODE="development"
                shift
                ;;
            --no-ssl)
                NO_SSL=1
                shift
                ;;
            *)
                warn "Unknown option: $1"
                shift
                ;;
        esac
    done

    # Execute command
    case $command in
        setup)
            interactive_setup
            ;;
        deploy)
            deploy
            ;;
        dev|development)
            start_development
            ;;
        prod|production)
            start_production
            ;;
        stop)
            stop_services
            ;;
        restart)
            restart_services
            ;;
        logs)
            show_logs "$1"
            ;;
        status)
            show_status
            ;;
        cert-renew)
            renew_certificates
            ;;
        cert-info)
            show_cert_info
            ;;
        backup)
            backup_certificates
            ;;
        health)
            check_health
            ;;
        clean|cleanup)
            cleanup
            ;;
        *)
            if [ -z "$command" ]; then
                show_usage
            else
                error "Unknown command: $command"
                echo ""
                show_usage
                exit 1
            fi
            ;;
    esac
}

# Run main function with all arguments
main "$@"
