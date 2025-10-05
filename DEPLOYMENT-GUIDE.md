# 🚀 Production Deployment Guide

Quick and secure deployment guide for GladysAI-Blog with SSL/HTTPS support.

## 📋 Prerequisites

### Server Requirements
- **Linux server** (Ubuntu 20.04+, Debian 11+, or CentOS 8+)
- **Docker** 20.10+ and **Docker Compose** 2.0+
- **Domain name** pointing to your server
- **Ports 80 and 443** open in firewall
- **Root/sudo access** for initial setup

### Before You Start
```bash
# Verify DNS is pointing to your server
nslookup yourdomain.com

# Check ports are open
sudo ufw status
sudo netstat -tlnp | grep -E ':80|:443'

# Verify Docker installation
docker --version
docker-compose --version
```

## 🔧 Quick Deployment (Recommended)

### 1. Clone and Setup
```bash
# Clone repository
git clone https://github.com/your-username/Gladys-Blog.git
cd Gladys-Blog

# Make deployment script executable
chmod +x deploy/ssl-deploy.sh

# Interactive setup (recommended for first-time users)
./deploy/ssl-deploy.sh setup
```

### 2. Configure Environment
During interactive setup, you'll be asked for:
- **Domain name**: `yourdomain.com`
- **Email**: `your-email@example.com` (for Let's Encrypt)
- **Certificate type**: Production or Staging (use Staging for testing)
- **Deployment mode**: Production (with SSL)

### 3. Deploy
```bash
# Deploy to production with SSL
./deploy/ssl-deploy.sh prod

# Wait for deployment to complete (2-3 minutes)
# Check status
./deploy/ssl-deploy.sh status
```

### 4. Verify Deployment
```bash
# Test HTTP redirect
curl -I http://yourdomain.com

# Test HTTPS
curl -I https://yourdomain.com

# Check SSL certificate
./deploy/ssl-deploy.sh cert-info
```

## 🔧 Manual Deployment

### 1. Environment Configuration
```bash
# Copy environment template
cp .env.ssl.example .env

# Edit configuration
nano .env
```

Required settings in `.env`:
```bash
DOMAIN=yourdomain.com
EMAIL=your-email@example.com
STAGING=0  # 0 for production, 1 for testing
```

### 2. Deploy Services
```bash
# Build and start SSL-enabled production service
docker-compose -f docker-compose.ssl.yaml up --build -d blog-prod-ssl

# Optional: Enable automatic certificate renewal
export COMPOSE_PROFILES=auto-renew
docker-compose -f docker-compose.ssl.yaml up -d
```

### 3. Verify and Monitor
```bash
# Check container status
docker-compose -f docker-compose.ssl.yaml ps

# View logs
docker-compose -f docker-compose.ssl.yaml logs -f

# Test endpoints
curl https://yourdomain.com/health
```

## 🔐 SSL Certificate Management

### Automatic (Let's Encrypt)
```bash
# Certificates are automatically obtained on first deployment
# Check certificate status
./deploy/ssl-deploy.sh cert-info

# Manual renewal (if needed)
./deploy/ssl-deploy.sh cert-renew
```

### Testing with Staging Certificates
```bash
# Use Let's Encrypt staging for testing (recommended first)
echo "STAGING=1" >> .env
./deploy/ssl-deploy.sh prod

# Switch to production certificates
echo "STAGING=0" > .env
./deploy/ssl-deploy.sh cert-renew
```

## 📊 Production Monitoring

### Health Checks
```bash
# Quick health check
./deploy/ssl-deploy.sh health

# Detailed status
./deploy/ssl-deploy.sh status

# View logs
./deploy/ssl-deploy.sh logs
```

### Service Management
```bash
# Restart services
./deploy/ssl-deploy.sh restart

# Stop services
./deploy/ssl-deploy.sh stop

# Update and redeploy
git pull
./deploy/ssl-deploy.sh restart
```

### SSL Monitoring
```bash
# Certificate information
./deploy/ssl-deploy.sh cert-info

# Backup certificates
./deploy/ssl-deploy.sh backup

# Test SSL configuration
curl -I https://www.ssllabs.com/ssltest/analyze.html?d=yourdomain.com
```

## 🔧 CI/CD Deployment (Jenkins)

### Server Setup
```bash
# Create deploy user
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy

# Setup SSH key access
sudo mkdir -p /home/deploy/.ssh
sudo chown deploy:deploy /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh

# Add Jenkins public key to authorized_keys
sudo nano /home/deploy/.ssh/authorized_keys
sudo chown deploy:deploy /home/deploy/.ssh/authorized_keys
sudo chmod 600 /home/deploy/.ssh/authorized_keys
```

### Jenkins Configuration
1. **Create Pipeline Job** in Jenkins
2. **Add Parameters**:
   - `SERVER_HOST`: Your server domain/IP
   - `SERVER_USER`: `deploy`
   - `ENVIRONMENT`: `production`
3. **Configure SCM** with your repository
4. **Add SSH credentials** in Jenkins

### Pipeline Deployment
The existing `Jenkinsfile` will:
1. Build the Docker image
2. Deploy to your server via SSH
3. Run health checks
4. Send notifications

Trigger deployment:
```bash
# Manual trigger via Jenkins UI or API
curl -X POST "http://jenkins.example.com/job/gladys-blog/buildWithParameters" \
  --user "user:token" \
  --data "SERVER_HOST=yourdomain.com&SERVER_USER=deploy&ENVIRONMENT=production"
```

## ⚠️ Troubleshooting

### Common Issues

#### 1. Certificate Generation Failed
```bash
# Check DNS resolution
nslookup yourdomain.com

# Verify domain points to server
ping yourdomain.com

# Check firewall
sudo ufw status

# Try staging certificates first
STAGING=1 ./deploy/ssl-deploy.sh prod
```

#### 2. Service Not Starting
```bash
# Check logs
./deploy/ssl-deploy.sh logs

# Verify Docker is running
sudo systemctl status docker

# Check port availability
sudo netstat -tlnp | grep :443
```

#### 3. SSL Not Working
```bash
# Test certificate
openssl s_client -connect yourdomain.com:443

# Check nginx config
docker-compose -f docker-compose.ssl.yaml exec blog-prod-ssl nginx -t

# Restart services
./deploy/ssl-deploy.sh restart
```

### Debug Commands
```bash
# Container shell access
docker-compose -f docker-compose.ssl.yaml exec blog-prod-ssl bash

# Check certificate files
docker-compose -f docker-compose.ssl.yaml exec blog-prod-ssl ls -la /etc/letsencrypt/live/

# View nginx error logs
docker-compose -f docker-compose.ssl.yaml exec blog-prod-ssl tail -f /var/log/nginx/error.log
```

## 🔄 Updates and Maintenance

### Regular Updates
```bash
# Update code
git pull

# Rebuild and restart
./deploy/ssl-deploy.sh restart

# Update Docker images
docker-compose -f docker-compose.ssl.yaml pull
docker-compose -f docker-compose.ssl.yaml up -d
```

### Certificate Renewal
Certificates automatically renew with auto-renew profile:
```bash
export COMPOSE_PROFILES=auto-renew
docker-compose -f docker-compose.ssl.yaml up -d
```

Manual renewal:
```bash
./deploy/ssl-deploy.sh cert-renew
```

### Backups
```bash
# Backup SSL certificates and config
./deploy/ssl-deploy.sh backup

# Backup to remote location
rsync -av ssl-backup-*/ user@backup-server:/backups/gladys-blog/
```

## 🛡️ Security Checklist

Before going live:
- [ ] Domain DNS properly configured
- [ ] Firewall configured (ports 22, 80, 443)
- [ ] SSH access secured (key-based, no root login)
- [ ] SSL certificates obtained and valid
- [ ] Security headers enabled
- [ ] Regular backups scheduled
- [ ] Monitoring and alerts configured
- [ ] `.env` file secured (not in git)

## 📞 Support

### Quick Commands Reference
```bash
# Setup and deploy
./deploy/ssl-deploy.sh setup && ./deploy/ssl-deploy.sh prod

# Status and health
./deploy/ssl-deploy.sh status && ./deploy/ssl-deploy.sh health

# Certificate management
./deploy/ssl-deploy.sh cert-info && ./deploy/ssl-deploy.sh cert-renew

# Troubleshooting
./deploy/ssl-deploy.sh logs && docker ps
```

### Getting Help
1. Check logs: `./deploy/ssl-deploy.sh logs`
2. Review [SECURITY.md](SECURITY.md) for security issues
3. Check [SSL-README.md](deploy/SSL-README.md) for detailed SSL info
4. Create issue in repository with logs and configuration

---

**⚡ Quick Start Summary:**
```bash
git clone <repo> && cd Gladys-Blog
./deploy/ssl-deploy.sh setup
./deploy/ssl-deploy.sh prod
```

**🔍 Verify deployment:**
```bash
curl https://yourdomain.com/health
./deploy/ssl-deploy.sh status
```

**📋 Emergency contact:** your-email@example.com
