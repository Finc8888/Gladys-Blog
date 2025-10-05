# SSL/HTTPS Setup for Gladys Blog

This guide explains how to deploy Gladys Blog with SSL/HTTPS support using Let's Encrypt certificates and Docker.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Deployment Options](#deployment-options)
- [SSL Certificate Management](#ssl-certificate-management)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Maintenance](#maintenance)
- [Advanced Configuration](#advanced-configuration)

## 🔍 Overview

The SSL-enabled version of Gladys Blog provides:

- **HTTPS encryption** for secure communication
- **Automatic HTTP to HTTPS redirection**
- **Let's Encrypt integration** for free SSL certificates
- **Automatic certificate renewal**
- **Self-signed certificate fallback** for development
- **Enhanced security headers** and configurations
- **Docker-based deployment** with SSL support

### Architecture

```
Internet → [Port 80/443] → Nginx (SSL Termination) → Hugo Static Site
```

- **Port 80**: HTTP traffic (redirected to HTTPS)
- **Port 443**: HTTPS traffic with SSL certificates
- **Let's Encrypt**: Automatic certificate provisioning
- **Nginx**: SSL termination and reverse proxy

## ✅ Prerequisites

### System Requirements

- **Docker** (version 20.0+)
- **Docker Compose** (version 2.0+)
- **Domain name** pointed to your server (for production)
- **Open ports** 80 and 443 on your server
- **Root/sudo access** for initial setup

### Domain Configuration

For production deployment, ensure your domain DNS points to your server:

```bash
# Check DNS resolution
nslookup yourdomain.com

# Should return your server's IP address
```

### Firewall Configuration

Ensure ports 80 and 443 are open:

```bash
# Ubuntu/Debian with ufw
sudo ufw allow 80
sudo ufw allow 443

# CentOS/RHEL with firewalld
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
```

## 🚀 Quick Start

### 1. Interactive Setup

The easiest way to get started:

```bash
./deploy/ssl-deploy.sh setup
```

This will guide you through:
- Domain configuration
- Email setup for Let's Encrypt
- Staging vs. production certificates
- Deployment mode selection

### 2. Manual Configuration

Create your environment file:

```bash
cp .env.ssl.example .env
```

Edit `.env` with your settings:

```bash
# Required settings
DOMAIN=yourdomain.com
EMAIL=your-email@example.com
STAGING=0  # Set to 1 for testing
```

### 3. Deploy

```bash
# For production with SSL
./deploy/ssl-deploy.sh prod

# For development (HTTP only)
./deploy/ssl-deploy.sh dev
```

### 4. Verify Deployment

```bash
# Check service status
./deploy/ssl-deploy.sh status

# Test HTTPS
curl -I https://yourdomain.com
```

## ⚙️ Configuration

### Environment Variables

Edit `.env` file to customize your deployment:

#### Essential Configuration

```bash
# Domain and SSL
DOMAIN=yourdomain.com          # Your domain name
EMAIL=admin@yourdomain.com     # Email for Let's Encrypt notifications
STAGING=0                      # 0=production, 1=staging certificates

# Certificate Management
FORCE_RENEWAL=0                # Force renewal of existing certificates
FALLBACK_SELFSIGNED=1          # Generate self-signed if Let's Encrypt fails
```

#### Advanced Configuration

```bash
# Nginx Settings
NGINX_WORKER_PROCESSES=auto
NGINX_WORKER_CONNECTIONS=1024

# Security
SECURITY_HEADERS=1             # Enable additional security headers

# Logging
LOG_DRIVER=json-file
LOG_MAX_SIZE=10m
LOG_MAX_FILE=3

# Resources
MEMORY_LIMIT=512M
CPU_LIMIT=1.0
```

### Docker Compose Profiles

Use profiles to enable additional services:

```bash
# Auto-renewal (recommended for production)
export COMPOSE_PROFILES=auto-renew
./deploy/ssl-deploy.sh prod

# With monitoring
export COMPOSE_PROFILES=auto-renew,monitoring

# Manual certificate management
export COMPOSE_PROFILES=manual-cert
```

## 🚢 Deployment Options

### Development Mode

For local development with HTTP only:

```bash
./deploy/ssl-deploy.sh dev
```

- Uses HTTP on port 8080
- Hot reload enabled
- No SSL certificates required

### Production Mode

#### Standard Production

```bash
./deploy/ssl-deploy.sh prod
```

- HTTPS on port 443
- HTTP redirect (port 80)
- Let's Encrypt certificates
- No auto-renewal

#### Production with Auto-Renewal

```bash
export COMPOSE_PROFILES=auto-renew
./deploy/ssl-deploy.sh prod
```

- All standard features
- Automatic certificate renewal
- Background renewal service

#### Staging Environment

For testing with Let's Encrypt staging:

```bash
# Set staging in .env
STAGING=1

./deploy/ssl-deploy.sh prod
```

- Uses Let's Encrypt staging API
- Test certificates (not trusted)
- Higher rate limits for testing

### Custom Docker Compose

For advanced users, use Docker Compose directly:

```bash
# Standard deployment
docker-compose -f docker-compose.ssl.yaml up -d blog-prod-ssl

# With auto-renewal
docker-compose -f docker-compose.ssl.yaml --profile auto-renew up -d

# Development
docker-compose -f docker-compose.ssl.yaml up blog-dev
```

## 🔐 SSL Certificate Management

### Certificate Generation

#### Let's Encrypt (Production)

Certificates are automatically generated on first startup for valid domains:

```bash
# Check certificate status
./deploy/ssl-deploy.sh cert-info

# Manual renewal
./deploy/ssl-deploy.sh cert-renew
```

#### Self-Signed (Development)

For localhost or when Let's Encrypt fails:

```bash
# Enable self-signed fallback
FALLBACK_SELFSIGNED=1

# Deploy with localhost
DOMAIN=localhost ./deploy/ssl-deploy.sh prod
```

### Certificate Renewal

#### Automatic Renewal

Enable automatic renewal for production:

```bash
export COMPOSE_PROFILES=auto-renew
./deploy/ssl-deploy.sh prod
```

Certificates are checked and renewed every 12 hours automatically.

#### Manual Renewal

```bash
# Renew certificates manually
./deploy/ssl-deploy.sh cert-renew

# Force renewal
FORCE_RENEWAL=1 ./deploy/ssl-deploy.sh prod
```

### Certificate Backup

```bash
# Create certificate backup
./deploy/ssl-deploy.sh backup

# Backup is created in ssl-backup-YYYYMMDD-HHMMSS/
```

### Certificate Information

```bash
# View certificate details
./deploy/ssl-deploy.sh cert-info

# Check expiry date
openssl x509 -in /path/to/cert -noout -dates
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Certificate Generation Fails

**Problem**: Let's Encrypt certificate generation fails

**Solutions**:
```bash
# Check DNS resolution
nslookup yourdomain.com

# Verify domain points to your server
curl -I http://yourdomain.com

# Check firewall
sudo ufw status
sudo netstat -tlnp | grep :80

# Use staging environment for testing
STAGING=1 ./deploy/ssl-deploy.sh prod

# Check logs
./deploy/ssl-deploy.sh logs
```

#### 2. HTTPS Not Working

**Problem**: HTTPS endpoint not accessible

**Solutions**:
```bash
# Check service status
./deploy/ssl-deploy.sh status

# Verify certificate paths
docker-compose -f docker-compose.ssl.yaml exec blog-prod-ssl ls -la /etc/letsencrypt/live/

# Test nginx configuration
docker-compose -f docker-compose.ssl.yaml exec blog-prod-ssl nginx -t

# Check logs
./deploy/ssl-deploy.sh logs blog-prod-ssl
```

#### 3. HTTP to HTTPS Redirect Not Working

**Problem**: HTTP requests not redirecting to HTTPS

**Solutions**:
```bash
# Check nginx configuration
docker-compose -f docker-compose.ssl.yaml exec blog-prod-ssl cat /etc/nginx/nginx.conf | grep "return 301"

# Test redirect manually
curl -I http://yourdomain.com

# Restart service
./deploy/ssl-deploy.sh restart
```

#### 4. Certificate Expiry Warnings

**Problem**: Certificate expiring soon

**Solutions**:
```bash
# Check certificate expiry
./deploy/ssl-deploy.sh cert-info

# Manual renewal
./deploy/ssl-deploy.sh cert-renew

# Enable auto-renewal
export COMPOSE_PROFILES=auto-renew
./deploy/ssl-deploy.sh prod
```

### Debug Commands

```bash
# Check container logs
docker-compose -f docker-compose.ssl.yaml logs -f blog-prod-ssl

# Execute commands in container
docker-compose -f docker-compose.ssl.yaml exec blog-prod-ssl bash

# Test nginx configuration
docker-compose -f docker-compose.ssl.yaml exec blog-prod-ssl nginx -t

# Check certificate files
docker-compose -f docker-compose.ssl.yaml exec blog-prod-ssl find /etc/letsencrypt -name "*.pem"

# Test SSL handshake
openssl s_client -connect yourdomain.com:443 -servername yourdomain.com
```

### Log Analysis

```bash
# View all logs
./deploy/ssl-deploy.sh logs

# View specific service logs
./deploy/ssl-deploy.sh logs blog-prod-ssl

# Follow logs in real-time
docker-compose -f docker-compose.ssl.yaml logs -f --tail=100

# Check nginx access logs
docker-compose -f docker-compose.ssl.yaml exec blog-prod-ssl tail -f /var/log/nginx/access.log

# Check nginx error logs
docker-compose -f docker-compose.ssl.yaml exec blog-prod-ssl tail -f /var/log/nginx/error.log
```

## 🛡️ Security Considerations

### SSL Configuration

The deployment includes secure SSL settings:

- **TLS 1.2 and 1.3** only
- **Strong cipher suites**
- **HSTS headers** (HTTP Strict Transport Security)
- **Perfect Forward Secrecy**
- **OCSP stapling**

### Security Headers

Enabled by default:

```nginx
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
Content-Security-Policy: (configured for static sites)
```

### Rate Limiting

Built-in rate limiting:

- **General requests**: 10 requests/second
- **API endpoints**: 5 requests/second
- **Burst capacity**: 20 requests

### Container Security

- **Non-root user** for nginx process
- **Read-only filesystem** where possible
- **Minimal base images** (Alpine Linux)
- **Regular security updates**

### Best Practices

1. **Use strong passwords** for any admin interfaces
2. **Keep Docker images updated**
3. **Monitor certificate expiry**
4. **Regular security audits**
5. **Backup certificates and configurations**

## 🔄 Maintenance

### Regular Tasks

#### Daily
- Monitor service health
- Check logs for errors

#### Weekly
- Review certificate expiry dates
- Check for Docker image updates

#### Monthly
- Backup SSL certificates
- Review security logs
- Update Docker images

### Health Monitoring

```bash
# Check service health
./deploy/ssl-deploy.sh health

# Monitor certificate expiry
./deploy/ssl-deploy.sh cert-info

# Service status
./deploy/ssl-deploy.sh status
```

### Updates and Upgrades

```bash
# Update Docker images
docker-compose -f docker-compose.ssl.yaml pull

# Rebuild with updates
./deploy/ssl-deploy.sh restart

# Update SSL configuration
git pull  # Get latest configurations
./deploy/ssl-deploy.sh restart
```

### Backup Strategy

```bash
# Regular backup
./deploy/ssl-deploy.sh backup

# Backup to external location
rsync -av ssl-backup-*/ user@backup-server:/backups/gladys-blog/

# Automated backup (add to crontab)
0 2 * * 0 /path/to/gladys-blog/deploy/ssl-deploy.sh backup
```

## 🔧 Advanced Configuration

### Custom Nginx Configuration

Modify `deploy/nginx-ssl.conf` for custom settings:

```nginx
# Add custom locations
location /api/ {
    proxy_pass http://backend:3000;
    proxy_set_header Host $host;
}

# Custom security headers
add_header X-Custom-Header "value" always;
```

### Multiple Domains

For multiple domains, modify the certificate generation:

```bash
# In .env file
DOMAIN=example.com,www.example.com,blog.example.com

# Or use DNS challenge
certbot certonly --dns-route53 -d example.com -d *.example.com
```

### External Load Balancer

When using external load balancers (AWS ALB, CloudFlare, etc.):

```bash
# Disable SSL in container (terminate at load balancer)
NO_SSL=1 ./deploy/ssl-deploy.sh prod

# Use HTTP-only configuration
docker-compose -f docker-compose.yaml up -d blog-prod
```

### Custom SSL Certificates

To use your own SSL certificates:

1. Place certificates in `ssl/custom/`:
   - `fullchain.pem`
   - `privkey.pem`
   - `chain.pem`

2. Modify docker-compose.ssl.yaml:
   ```yaml
   volumes:
     - ./ssl/custom:/etc/letsencrypt/live/${DOMAIN}:ro
   ```

### Performance Tuning

For high-traffic sites, adjust nginx settings:

```bash
# In .env file
NGINX_WORKER_PROCESSES=4
NGINX_WORKER_CONNECTIONS=2048

# Enable additional optimizations
GZIP_COMPRESSION=1
BROWSER_CACHING=1
```

## 📚 Additional Resources

- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [Nginx SSL Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [SSL Testing Tools](https://www.ssllabs.com/ssltest/)

## 🆘 Support

If you encounter issues:

1. Check the [troubleshooting section](#troubleshooting)
2. Review the logs: `./deploy/ssl-deploy.sh logs`
3. Verify configuration: `./deploy/ssl-deploy.sh status`
4. Test manually with curl and openssl commands

For additional help, please check the project documentation or create an issue in the repository.

---

**Security Note**: Always test SSL configurations with staging certificates first, then switch to production. Keep your certificates and private keys secure and backed up regularly.