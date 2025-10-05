#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Default values
DOMAIN=${DOMAIN:-localhost}
EMAIL=${EMAIL:-admin@localhost}
STAGING=${STAGING:-0}
FORCE_RENEWAL=${FORCE_RENEWAL:-0}

log "Starting Gladys Blog with SSL support"
log "Domain: $DOMAIN"
log "Email: $EMAIL"
log "Staging: $STAGING"

# Function to generate self-signed certificate for localhost/development
generate_self_signed_cert() {
    log "Generating self-signed certificate for development"
    
    mkdir -p /etc/letsencrypt/live/$DOMAIN
    
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/letsencrypt/live/$DOMAIN/privkey.pem \
        -out /etc/letsencrypt/live/$DOMAIN/fullchain.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=$DOMAIN"
    
    # Create chain.pem (same as fullchain for self-signed)
    cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/letsencrypt/live/$DOMAIN/chain.pem
    
    chmod 600 /etc/letsencrypt/live/$DOMAIN/privkey.pem
    chmod 644 /etc/letsencrypt/live/$DOMAIN/fullchain.pem
    chmod 644 /etc/letsencrypt/live/$DOMAIN/chain.pem
    
    log "Self-signed certificate generated successfully"
}

# Function to obtain Let's Encrypt certificate
obtain_letsencrypt_cert() {
    log "Obtaining Let's Encrypt certificate for $DOMAIN"
    
    # Determine if we should use staging
    local staging_flag=""
    if [ "$STAGING" = "1" ]; then
        staging_flag="--staging"
        warn "Using Let's Encrypt staging environment"
    fi
    
    # Stop nginx if running
    if pgrep nginx > /dev/null; then
        log "Stopping nginx for certificate generation"
        nginx -s stop || true
        sleep 2
    fi
    
    # Start nginx with a minimal HTTP-only configuration for ACME challenge
    log "Starting temporary nginx for ACME challenge"
    cat > /tmp/nginx-acme.conf << EOF
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name $DOMAIN;
        
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
            try_files \$uri =404;
        }
        
        location / {
            return 404;
        }
    }
}
EOF
    
    nginx -c /tmp/nginx-acme.conf -g "daemon off;" &
    local nginx_pid=$!
    sleep 3
    
    # Run certbot
    local certbot_cmd="certbot certonly --webroot -w /var/www/certbot -d $DOMAIN --email $EMAIL --agree-tos --non-interactive $staging_flag"
    
    if [ "$FORCE_RENEWAL" = "1" ]; then
        certbot_cmd="$certbot_cmd --force-renewal"
        log "Forcing certificate renewal"
    fi
    
    if eval $certbot_cmd; then
        log "Certificate obtained successfully"
        kill $nginx_pid 2>/dev/null || true
        sleep 2
        return 0
    else
        error "Failed to obtain certificate"
        kill $nginx_pid 2>/dev/null || true
        sleep 2
        return 1
    fi
}

# Function to check if certificate exists and is valid
check_certificate() {
    local cert_path="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
    local key_path="/etc/letsencrypt/live/$DOMAIN/privkey.pem"
    
    if [ ! -f "$cert_path" ] || [ ! -f "$key_path" ]; then
        return 1
    fi
    
    # Check if certificate is expiring in the next 30 days
    if openssl x509 -checkend 2592000 -noout -in "$cert_path" >/dev/null 2>&1; then
        return 0
    else
        warn "Certificate is expiring soon, renewal needed"
        return 1
    fi
}

# Function to update nginx configuration with correct domain
update_nginx_config() {
    log "Updating nginx configuration for domain: $DOMAIN"
    
    # Replace YOUR_DOMAIN placeholder with actual domain
    sed -i "s/YOUR_DOMAIN/$DOMAIN/g" /etc/nginx/nginx.conf
    
    # Test nginx configuration
    if nginx -t; then
        log "Nginx configuration is valid"
    else
        error "Nginx configuration test failed"
        exit 1
    fi
}

# Function to setup certificate renewal cron job
setup_renewal_cron() {
    log "Setting up certificate renewal cron job"
    
    # Create renewal script
    cat > /usr/local/bin/renew-certs.sh << 'EOF'
#!/bin/bash
/usr/bin/certbot renew --quiet --webroot -w /var/www/certbot
if [ $? -eq 0 ]; then
    /usr/sbin/nginx -s reload
fi
EOF
    
    chmod +x /usr/local/bin/renew-certs.sh
    
    # Add to crontab (run twice daily)
    echo "0 12 * * * /usr/local/bin/renew-certs.sh" >> /var/spool/cron/crontabs/root
    echo "0 0 * * * /usr/local/bin/renew-certs.sh" >> /var/spool/cron/crontabs/root
    
    # Start crond
    crond -l 2
    log "Certificate renewal cron job configured"
}

# Function to fallback to HTTP-only configuration
fallback_to_http() {
    warn "Falling back to HTTP-only configuration"
    
    # Copy the original HTTP-only config
    cp /etc/nginx/nginx.conf.orig /etc/nginx/nginx.conf 2>/dev/null || {
        # If original doesn't exist, create a simple HTTP config
        cat > /etc/nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    server {
        listen 80;
        server_name _;
        root /usr/share/nginx/html;
        index index.html index.htm;
        
        location / {
            try_files $uri $uri/ $uri.html /index.html;
        }
        
        location /health {
            access_log off;
            default_type text/plain;
            return 200 "healthy (HTTP mode)\n";
        }
    }
}
EOF
    }
    
    log "HTTP-only configuration applied"
}

# Main execution
main() {
    log "Initializing SSL setup"
    
    # Create necessary directories
    mkdir -p /var/www/certbot
    mkdir -p /etc/letsencrypt/live
    
    # Backup original nginx config
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
    
    # Handle localhost/development case
    if [ "$DOMAIN" = "localhost" ] || [ "$DOMAIN" = "127.0.0.1" ]; then
        log "Development mode detected (localhost)"
        generate_self_signed_cert
        update_nginx_config
    else
        # Check if certificate exists and is valid
        if check_certificate; then
            log "Valid certificate found for $DOMAIN"
            update_nginx_config
        else
            log "Certificate not found or invalid, attempting to obtain new certificate"
            
            # Try to obtain Let's Encrypt certificate
            if obtain_letsencrypt_cert; then
                update_nginx_config
                setup_renewal_cron
            else
                error "Failed to obtain Let's Encrypt certificate"
                
                # Ask if user wants to continue with self-signed
                if [ "${FALLBACK_SELFSIGNED:-1}" = "1" ]; then
                    warn "Falling back to self-signed certificate"
                    generate_self_signed_cert
                    update_nginx_config
                else
                    error "SSL setup failed, falling back to HTTP-only mode"
                    fallback_to_http
                fi
            fi
        fi
    fi
    
    # Final nginx configuration test
    if ! nginx -t; then
        error "Final nginx configuration test failed, falling back to HTTP"
        fallback_to_http
    fi
    
    log "SSL setup completed successfully"
    
    # Start nginx
    log "Starting nginx"
    exec nginx -g "daemon off;"
}

# Handle signals
trap 'log "Received SIGTERM, shutting down gracefully"; nginx -s quit; exit 0' SIGTERM
trap 'log "Received SIGINT, shutting down gracefully"; nginx -s quit; exit 0' SIGINT

# Run main function
main "$@"