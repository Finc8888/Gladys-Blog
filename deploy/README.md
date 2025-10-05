# 🚀 GladysAI-Blog Deployment

Complete guide for deploying Hugo blog using Docker and Jenkins.

## 📋 Table of Contents

- [Overview](#-overview)
- [Requirements](#-requirements)
- [Quick Start](#-quick-start)
- [Local Deployment](#-local-deployment)
- [Jenkins Deployment](#-jenkins-deployment)
- [Server Setup](#-server-setup)
- [Monitoring](#-monitoring)
- [Troubleshooting](#-troubleshooting)

## 🎯 Overview

GladysAI-Blog is a static site created with Hugo and deployed in Docker containers with Nginx. The project supports:

- ✅ **Local deployment** for development and testing
- ✅ **Automatic deployment** via Jenkins CI/CD
- ✅ **Production-ready** configuration with Nginx
- ✅ **Monitoring** and health checks
- ✅ **SSL/TLS** support (with reverse proxy)

### Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Git Repo      │───▶│    Jenkins       │───▶│   Target Server │
│                 │    │                  │    │                 │
│ - Hugo Content  │    │ - Build Pipeline │    │ - Docker        │
│ - Dockerfile    │    │ - Tests          │    │ - Nginx         │
│ - Nginx Config  │    │ - Deploy Script  │    │ - Monitoring    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## ⚡ Requirements

### Minimum Requirements

- **Docker** 20.10+
- **Docker Compose** 2.0+ (optional)
- **Git** 2.0+
- **Bash** 4.0+

### For Jenkins Deployment

- **Jenkins** 2.400+
- **SSH keys** for server access
- **Docker Registry** (optional)

### For Server

- **Linux** (Ubuntu 20.04+ / CentOS 8+ / Debian 11+)
- **RAM**: minimum 512MB, recommended 1GB
- **Disk**: minimum 2GB free space
- **Ports**: 80 (HTTP), 443 (HTTPS - optional)

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone <repository-url> gladys-blog
cd gladys-blog
```

### 2. Local Run (Development)

```bash
# Run in development mode on port 8080
./deploy/local-deploy.sh -d

# Or standard production mode on port 80
sudo ./deploy/local-deploy.sh
```

### 3. Verification

Open browser: http://localhost:8080 (development) or http://localhost:80 (production)

## 🔐 SSL/HTTPS Deployment

For production deployment with SSL/HTTPS support using Let's Encrypt certificates.

### Quick SSL Setup

```bash
# Interactive SSL setup
./deploy/ssl-deploy.sh setup

# Production with SSL
./deploy/ssl-deploy.sh prod

# Development (HTTP only)
./deploy/ssl-deploy.sh dev
```

### SSL Configuration

Create environment file:

```bash
cp .env.ssl.example .env
```

Edit `.env` with your domain settings:

```bash
DOMAIN=yourdomain.com
EMAIL=your-email@example.com
STAGING=0  # Set to 1 for testing certificates
```

### SSL Deployment Options

| Command | Description | Ports | SSL |
|---------|-------------|-------|-----|
| `./deploy/ssl-deploy.sh dev` | Development mode | 8080 | No |
| `./deploy/ssl-deploy.sh prod` | Production with SSL | 80, 443 | Yes |
| `./deploy/ssl-deploy.sh prod --staging` | SSL with test certificates | 80, 443 | Staging |

### SSL Management

```bash
# Check SSL certificate info
./deploy/ssl-deploy.sh cert-info

# Renew certificates manually
./deploy/ssl-deploy.sh cert-renew

# View SSL deployment status
./deploy/ssl-deploy.sh status

# Backup SSL certificates
./deploy/ssl-deploy.sh backup
```

### Docker Compose SSL Profiles

```bash
# Basic SSL deployment
docker-compose -f docker-compose.ssl.yaml up -d blog-prod-ssl

# With automatic certificate renewal
export COMPOSE_PROFILES=auto-renew
docker-compose -f docker-compose.ssl.yaml up -d

# With monitoring
export COMPOSE_PROFILES=auto-renew,monitoring
docker-compose -f docker-compose.ssl.yaml up -d
```

### SSL Requirements

- **Domain name** pointing to your server
- **Open ports** 80 and 443
- **Valid email** for Let's Encrypt notifications
- **Docker** and **Docker Compose**

For detailed SSL setup instructions, see [SSL-README.md](SSL-README.md).

## 🛠️ Local Deployment

### Using Deployment Script

```bash
cd gladys-blog

# Show help
./deploy/local-deploy.sh --help

# Development with hot reload
./deploy/local-deploy.sh --dev

# Production on custom port
./deploy/local-deploy.sh --port 8080

# Build only, don't run
./deploy/local-deploy.sh --build-only

# Show status
./deploy/local-deploy.sh --status

# Show logs
./deploy/local-deploy.sh --logs

# Full cleanup
./deploy/local-deploy.sh --clean
```

### Manual Docker Deployment

```bash
# 1. Build image
docker build -f deploy/Dockerfile.prod -t gladys-blog:latest .

# 2. Run container
docker run -d \
  --name gladys-blog \
  --restart unless-stopped \
  -p 80:80 \
  --memory="512m" \
  --cpus="1.0" \
  gladys-blog:latest

# 3. Verification
curl http://localhost/health
```

### Docker Compose (Alternative Method)

```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# Rebuild and start
docker-compose up --build -d
```

## 🤖 Jenkins Deployment

### Jenkins Job Setup

1. **Create new Pipeline Job**
2. **Configure Git SCM** with your repository
3. **Add parameters**:
   - `SERVER_HOST`: your server (e.g.: `blog.example.com`)
   - `SERVER_USER`: SSH user (e.g.: `deploy`)
   - `ENVIRONMENT`: `production` or `staging`

### SSH Keys Setup

```bash
# On Jenkins server
ssh-keygen -t rsa -b 4096 -C "jenkins@yourdomain.com"

# Add public key to target server
ssh-copy-id deploy@your-server.com

# In Jenkins add private key as Credential
# ID: ssh-deploy-key
```

### Launch Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `SERVER_HOST` | Target server host | `your-server.com` |
| `SERVER_USER` | SSH user | `deploy` |
| `ENVIRONMENT` | Environment | `production` |
| `SKIP_TESTS` | Skip tests | `false` |
| `FORCE_DEPLOY` | Force deployment | `false` |

### Launch Example

```bash
# Via Jenkins API
curl -X POST "http://jenkins.example.com/job/gladys-blog/buildWithParameters" \
  --user "user:token" \
  --data "SERVER_HOST=blog.example.com&SERVER_USER=deploy&ENVIRONMENT=production"
```

## 🖥️ Server Setup

### Ubuntu/Debian Server Preparation

```bash
# System update
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Create deploy user
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy
sudo mkdir -p /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh

# Setup SSH keys (copy Jenkins public key)
sudo tee /home/deploy/.ssh/authorized_keys << 'EOF'
ssh-rsa AAAAB3NzaC1yc2E... jenkins@yourdomain.com
EOF

sudo chmod 600 /home/deploy/.ssh/authorized_keys
sudo chown -R deploy:deploy /home/deploy/.ssh

# Configure firewall
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
```

### Reverse Proxy Setup (Optional)

If you have other services or need SSL:

```bash
# Install Nginx as reverse proxy
sudo apt install nginx certbot python3-certbot-nginx

# Create configuration
sudo tee /etc/nginx/sites-available/gladys-blog << 'EOF'
server {
    listen 80;
    server_name blog.example.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Activate configuration
sudo ln -s /etc/nginx/sites-available/gladys-blog /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Get SSL certificate
sudo certbot --nginx -d blog.example.com
```

In this case run container on port 8080:

```bash
docker run -d --name gladys-blog -p 8080:80 gladys-blog:latest
```

## 📊 Monitoring

### Health Checks

```bash
# Basic check
curl http://your-server.com/health

# Detailed check
curl http://your-server.com/status

# Nginx statistics (local server only)
curl http://localhost/nginx-status
```

### Logs

```bash
# Container logs
docker logs gladys-blog-container

# Follow logs in real time
docker logs -f gladys-blog-container

# System logs
sudo journalctl -u docker -f
```

### Resource Monitoring

```bash
# Resource usage
docker stats gladys-blog-container

# Container information
docker inspect gladys-blog-container

# Disk space
docker system df
```

### Automated Monitoring

Create monitoring script:

```bash
#!/bin/bash
# /home/deploy/monitor.sh

CONTAINER_NAME="gladys-blog-container"
WEBHOOK_URL="https://discord.com/api/webhooks/..." # Your webhook

check_health() {
    if ! curl -f http://localhost/health >/dev/null 2>&1; then
        echo "Service is down! Sending alert..."
        curl -X POST "$WEBHOOK_URL" \
             -H "Content-Type: application/json" \
             -d '{"content":"🚨 Gladys Blog is down!"}'

        # Restart container
        docker restart "$CONTAINER_NAME"
    fi
}

check_health
```

Add to crontab:

```bash
# Check every 5 minutes
*/5 * * * * /home/deploy/monitor.sh
```

## 🔧 Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs gladys-blog-container

# Check Nginx configuration
docker run --rm -v $(pwd)/deploy/nginx.conf:/etc/nginx/nginx.conf nginx:alpine nginx -t

# Run in interactive mode
docker run -it --rm gladys-blog:latest /bin/sh
```

### Port Is Occupied

```bash
# Find process
sudo lsof -i :80

# Stop process
sudo kill -9 <PID>

# Or run on different port
docker run -p 8080:80 gladys-blog:latest
```

### Memory Issues

```bash
# Check memory usage
docker stats

# Increase memory limit
docker run --memory="1g" gladys-blog:latest

# Clean unused images
docker system prune -a -f
```

### SSH Issues in Jenkins

```bash
# Check SSH connection
ssh -o StrictHostKeyChecking=no deploy@your-server.com whoami

# Check keys
ssh-add -l

# Debug SSH
ssh -vvv deploy@your-server.com
```

### Files Not Updating

```bash
# Clear Docker cache
docker system prune -a

# Force rebuild
docker build --no-cache -f deploy/Dockerfile.prod -t gladys-blog:latest .

# Check file timestamps
ls -la blog/content/posts/
```

## 📚 Additional Resources

### Useful Commands

```bash
# Export image
docker save gladys-blog:latest | gzip > gladys-blog.tar.gz

# Import image
gunzip -c gladys-blog.tar.gz | docker load

# Container backup
docker commit gladys-blog-container gladys-blog:backup

# Rollback to previous version
docker stop gladys-blog-container
docker rm gladys-blog-container
docker run -d --name gladys-blog-container -p 80:80 gladys-blog:backup
```

### Project Structure

```
gladys-blog/
├── blog/                 # Hugo site
│   ├── content/          # Blog content
│   ├── themes/           # Hugo themes
│   └── hugo.toml         # Hugo configuration
├── deploy/               # Deployment files
│   ├── Dockerfile        # Development Dockerfile
│   ├── Dockerfile.prod   # Production Dockerfile
│   ├── nginx.conf        # Nginx configuration
│   ├── local-deploy.sh   # Local deployment script
│   └── README.md         # This documentation
├── Jenkinsfile          # Jenkins pipeline
└── docker-compose.yaml  # Docker Compose configuration
```

### Contacts and Support

- **Hugo Documentation**: https://gohugo.io/documentation/
- **Docker Documentation**: https://docs.docker.com/
- **Jenkins Documentation**: https://www.jenkins.io/doc/

---

📝 **Note**: Update this documentation when making changes to the deployment process!
