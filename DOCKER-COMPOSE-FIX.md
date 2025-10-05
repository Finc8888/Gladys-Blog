# 🔧 Docker Compose Compatibility Fix

This guide helps resolve Docker Compose compatibility issues, specifically the "Additional property develop is not allowed" error.

## 🚨 Common Error

```bash
validating /home/vps/Gladys-Blog/docker-compose.ssl.yaml: services.blog-dev Additional property develop is not allowed
```

This error occurs when your Docker Compose version doesn't support the `develop` directive (requires Docker Compose 2.15+).

## 🔍 Check Your Docker Compose Version

Run this command on your server:

```bash
docker-compose --version
```

**Expected outputs:**
- ✅ `Docker Compose version v2.21.0` (Compatible)
- ❌ `docker-compose version 1.29.2` (Incompatible)
- ❌ `Docker Compose version 2.12.0` (Partially compatible)

## ⚡ Quick Fix Solutions

### Option 1: Use Legacy Compose File (Immediate Fix)

```bash
# On your server, use the legacy compose file
cd Gladys-Blog
./deploy/ssl-deploy.sh prod

# The script will automatically detect your version and use the compatible file
```

### Option 2: Update Docker Compose (Recommended)

```bash
# On your server, update Docker Compose to latest version
cd Gladys-Blog
./deploy/update-docker-compose.sh

# Then retry deployment
./deploy/ssl-deploy.sh prod
```

### Option 3: Manual Docker Compose Update

```bash
# Remove old version
sudo rm /usr/local/bin/docker-compose

# Download latest version (replace with current version number)
sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

## 🛠️ Step-by-Step Troubleshooting

### Step 1: Identify Your Version

```bash
# Check current version
docker-compose --version

# Check if using legacy version
if docker-compose --version | grep -E "^docker-compose version 1\."; then
    echo "❌ Legacy version detected - needs update"
elif docker-compose --version | grep -E "Docker Compose version 2\.([0-9]|1[0-4])\."; then
    echo "⚠️ Older v2 version - may need update"
else
    echo "✅ Compatible version"
fi
```

### Step 2: Choose Your Fix Method

#### Method A: Use Compatible Deployment (No Update Needed)

```bash
cd Gladys-Blog

# The SSL deploy script automatically detects your version
./deploy/ssl-deploy.sh prod

# Or manually use legacy compose file
docker-compose -f docker-compose.ssl.legacy.yaml up -d blog-prod-ssl
```

#### Method B: Update Docker Compose

```bash
# Automatic update
./deploy/update-docker-compose.sh

# Check new version
docker-compose --version

# Deploy with modern features
./deploy/ssl-deploy.sh prod
```

### Step 3: Verify Fix

```bash
# Test docker-compose validation
docker-compose -f docker-compose.ssl.yaml config

# If no errors, you're good to go!
./deploy/ssl-deploy.sh prod
```

## 🐳 Understanding Docker Compose Versions

### Version Compatibility Matrix

| Docker Compose Version | Gladys Blog Support | Features Available |
|------------------------|--------------------|--------------------|
| 1.x (Legacy) | ✅ Legacy mode | Basic deployment only |
| 2.0 - 2.14 | ✅ Partial | SSL, basic profiles |
| 2.15+ | ✅ Full | All features, watch mode |

### Feature Support by Version

```yaml
# Features requiring Docker Compose 2.15+
develop:           # ❌ Not supported in older versions
  watch:
    - action: sync

profiles:          # ✅ Supported in 2.0+
  - auto-renew

volumes:           # ✅ Supported in all versions
  ssl-certs:
    driver: local
```

## 🚀 Different Deployment Methods

### For Legacy Docker Compose (1.x)

```bash
# Use legacy compose file
docker-compose -f docker-compose.ssl.legacy.yaml up -d blog-prod-ssl

# Manual certificate renewal setup
docker-compose -f docker-compose.ssl.legacy.yaml up -d certbot-renew

# Manual monitoring setup
docker-compose -f docker-compose.ssl.legacy.yaml up -d ssl-monitor
```

### For Modern Docker Compose (2.15+)

```bash
# Use modern compose file with all features
docker-compose -f docker-compose.ssl.yaml --profile auto-renew up -d

# Or use the deployment script
./deploy/ssl-deploy.sh prod
```

## 💡 Alternative Solutions

### Solution 1: Docker Compose V2 Plugin

If you're using Docker Desktop or newer Docker versions:

```bash
# Try using 'docker compose' (without hyphen) instead
docker compose version
docker compose -f docker-compose.ssl.yaml up -d blog-prod-ssl
```

### Solution 2: Remove Problematic Directives

Edit the compose file manually:

```bash
# Remove the develop section from docker-compose.ssl.yaml
sed -i '/develop:/,/path: \.\/deploy\/Dockerfile/d' docker-compose.ssl.yaml

# Then deploy normally
docker-compose -f docker-compose.ssl.yaml up -d blog-prod-ssl
```

### Solution 3: Use Docker Run Commands

Skip Docker Compose entirely:

```bash
# Build the image
docker build -f deploy/Dockerfile.prod.ssl -t gladys-blog-ssl .

# Run with environment variables
docker run -d \
  --name gladys-blog-ssl \
  -p 80:80 -p 443:443 \
  -e DOMAIN=yourdomain.com \
  -e EMAIL=your-email@example.com \
  -v ssl-certs:/etc/letsencrypt \
  -v certbot-webroot:/var/www/certbot \
  --restart unless-stopped \
  gladys-blog-ssl
```

## 📋 Verification Commands

After applying any fix:

```bash
# 1. Check Docker Compose works
docker-compose --version

# 2. Validate compose file
docker-compose -f docker-compose.ssl.yaml config

# 3. Test deployment
./deploy/ssl-deploy.sh status

# 4. Check running containers
docker ps

# 5. Test SSL endpoint
curl -I https://yourdomain.com/health
```

## 🔄 Rollback Instructions

If the update causes issues:

```bash
# Rollback Docker Compose
./deploy/update-docker-compose.sh --rollback

# Or restore from backup
sudo cp /usr/local/bin/docker-compose.backup.* /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Use legacy deployment
docker-compose -f docker-compose.ssl.legacy.yaml up -d blog-prod-ssl
```

## 🆘 Emergency Deployment

If nothing else works, deploy with basic Docker commands:

```bash
# Build image
docker build -f deploy/Dockerfile.prod.ssl -t gladys-blog .

# Create network
docker network create gladys-blog-network

# Create volumes
docker volume create ssl-certs
docker volume create certbot-webroot

# Run container
docker run -d \
  --name gladys-blog-prod \
  --network gladys-blog-network \
  -p 80:80 -p 443:443 \
  -v ssl-certs:/etc/letsencrypt \
  -v certbot-webroot:/var/www/certbot \
  -e DOMAIN=${DOMAIN:-localhost} \
  -e EMAIL=${EMAIL:-admin@localhost} \
  --restart unless-stopped \
  gladys-blog

# Check logs
docker logs gladys-blog-prod
```

## 📞 Quick Commands Reference

```bash
# Check version
docker-compose --version

# Update Docker Compose
./deploy/update-docker-compose.sh

# Deploy with legacy support
./deploy/ssl-deploy.sh prod

# Manual legacy deployment
docker-compose -f docker-compose.ssl.legacy.yaml up -d blog-prod-ssl

# Rollback update
./deploy/update-docker-compose.sh --rollback

# Emergency Docker deployment
docker build -f deploy/Dockerfile.prod.ssl -t gladys-blog . && \
docker run -d --name gladys-blog -p 80:80 -p 443:443 \
  -e DOMAIN=yourdomain.com -e EMAIL=your@email.com gladys-blog
```

## ✅ Success Indicators

Your deployment is working when you see:

```bash
$ ./deploy/ssl-deploy.sh status
[2024-XX-XX XX:XX:XX] Checking service status...
    Name                   Command                  State           Ports
-------------------------------------------------------------------------------
gladys-blog-prod-ssl   /docker-entrypoint.sh        Up      0.0.0.0:443->443/tcp,
                       nginx -g daemon off;                 0.0.0.0:80->80/tcp

=== Health Check Results ===
[2024-XX-XX XX:XX:XX] SUCCESS: Blog service is running
[2024-XX-XX XX:XX:XX] SUCCESS: HTTPS endpoint responding
```

## 🔗 Additional Resources

- [Docker Compose Installation Guide](https://docs.docker.com/compose/install/)
- [Docker Compose Release Notes](https://github.com/docker/compose/releases)
- [Gladys Blog SSL Documentation](deploy/SSL-README.md)
- [General Deployment Guide](DEPLOYMENT-GUIDE.md)

---

**Need more help?** Check the logs with `./deploy/ssl-deploy.sh logs` or create an issue with your Docker Compose version and error details.