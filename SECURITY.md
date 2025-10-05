# 🔐 Security Guidelines for Gladys Blog

This document outlines security best practices for developing, deploying, and maintaining the Gladys Blog project.

## 📋 Table of Contents

- [General Security Principles](#general-security-principles)
- [Secrets Management](#secrets-management)
- [Git Security](#git-security)
- [Container Security](#container-security)
- [SSL/HTTPS Security](#sslhttps-security)
- [Production Deployment](#production-deployment)
- [Monitoring & Incident Response](#monitoring--incident-response)
- [Security Checklist](#security-checklist)

## 🛡️ General Security Principles

### Defense in Depth
- Multiple layers of security controls
- No single point of failure
- Regular security assessments

### Principle of Least Privilege
- Grant minimal necessary permissions
- Regular access reviews
- Use dedicated service accounts

### Security by Default
- Secure configurations out of the box
- Fail securely when errors occur
- Regular security updates

## 🔑 Secrets Management

### Environment Variables

**❌ NEVER DO:**
```bash
# Don't commit secrets to git
DOMAIN=example.com
EMAIL=admin@example.com
API_KEY=sk-1234567890abcdef  # ❌ EXPOSED SECRET
```

**✅ CORRECT APPROACH:**
```bash
# Use .env files (ignored by git)
cp .env.ssl.example .env
# Edit .env with your secrets
```

### Secret Types to Protect

| Secret Type | Examples | Storage Method |
|-------------|----------|----------------|
| SSL Certificates | `*.pem`, `*.key` | Docker volumes, secure storage |
| API Keys | Let's Encrypt tokens | Environment variables |
| Passwords | Database passwords | Docker secrets |
| SSH Keys | `id_rsa`, `id_ed25519` | SSH agent, secure storage |
| Email Credentials | SMTP passwords | Environment variables |

### Best Practices

1. **Use Docker Secrets** for production:
   ```yaml
   secrets:
     ssl_cert:
       file: ./ssl/cert.pem
     ssl_key:
       file: ./ssl/key.pem
   ```

2. **Environment-specific configurations**:
   ```bash
   # Development
   .env.development
   
   # Staging
   .env.staging
   
   # Production
   .env.production
   ```

3. **Rotate secrets regularly**:
   ```bash
   # SSL certificates (automated via Let's Encrypt)
   ./deploy/ssl-deploy.sh cert-renew
   
   # SSH keys (annually)
   ssh-keygen -t ed25519 -C "deploy-$(date +%Y)"
   ```

## 📝 Git Security

### Files to NEVER Commit

```gitignore
# Secrets and credentials
.env
.env.*
*.key
*.pem
*.crt
secrets/
credentials/

# SSH keys
id_rsa*
id_ed25519*
*.ppk

# Backup files (may contain secrets)
*.backup
*.dump
backup-*/

# Configuration with secrets
config.local.*
*-secrets.*
```

### Commit Message Security

**❌ BAD:**
```bash
git commit -m "Add API key: sk-1234567890abcdef for production"
```

**✅ GOOD:**
```bash
git commit -m "Add API key configuration support"
```

### Git Hooks for Security

Create `.git/hooks/pre-commit`:
```bash
#!/bin/bash
# Check for potential secrets before commit

# Check for common secret patterns
if grep -r "api[_-]key.*=" --include="*.env*" .; then
    echo "❌ Potential API key found in commit!"
    exit 1
fi

# Check for SSL private keys
if find . -name "*.key" -not -path "./.git/*"; then
    echo "❌ SSL private key found in commit!"
    exit 1
fi

echo "✅ Security pre-commit check passed"
```

### Cleaning Git History

If secrets were accidentally committed:

```bash
# Remove file from all history
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch path/to/secret-file' \
  --prune-empty --tag-name-filter cat -- --all

# Force push (⚠️ dangerous, coordinate with team)
git push --force --all
git push --force --tags
```

## 🐳 Container Security

### Dockerfile Security

**✅ SECURE DOCKERFILE:**
```dockerfile
# Use specific versions, not latest
FROM nginx:1.24-alpine

# Create non-root user
RUN addgroup -g 1001 -S appuser && \
    adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G appuser -g appuser appuser

# Set secure permissions
COPY --chown=appuser:appuser build/ /usr/share/nginx/html/
RUN chmod -R 755 /usr/share/nginx/html

# Drop privileges
USER appuser

# Use specific port
EXPOSE 8080
```

### Container Runtime Security

```yaml
# docker-compose.yml security settings
services:
  blog:
    # Security options
    security_opt:
      - no-new-privileges:true
    
    # Read-only root filesystem
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
    
    # Resource limits
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '1.0'
    
    # Health checks
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Image Scanning

```bash
# Scan for vulnerabilities
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image gladys-blog:latest

# Update base images regularly
docker pull nginx:alpine
docker build --no-cache -t gladys-blog:latest .
```

## 🔒 SSL/HTTPS Security

### SSL Configuration Security

**Strong SSL settings in nginx:**
```nginx
# Use only secure protocols
ssl_protocols TLSv1.2 TLSv1.3;

# Strong cipher suites
ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384;

# Perfect Forward Secrecy
ssl_ecdh_curve secp384r1;
ssl_prefer_server_ciphers on;

# Security headers
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
```

### Certificate Security

1. **Use strong encryption**:
   ```bash
   # Generate strong DH parameters
   openssl dhparam -out dhparam.pem 4096
   ```

2. **Monitor certificate expiry**:
   ```bash
   # Check certificate expiry
   ./deploy/ssl-deploy.sh cert-info
   
   # Automated monitoring
   echo "0 0 * * * /path/to/cert-check.sh" | crontab -
   ```

3. **Certificate backup**:
   ```bash
   # Regular backups
   ./deploy/ssl-deploy.sh backup
   
   # Store securely offsite
   rsync -av ssl-backup-*/ user@backup-server:/secure/backups/
   ```

## 🏭 Production Deployment

### Server Hardening

1. **System Updates**:
   ```bash
   # Keep system updated
   sudo apt update && sudo apt upgrade -y
   
   # Enable automatic security updates
   sudo apt install unattended-upgrades
   sudo dpkg-reconfigure unattended-upgrades
   ```

2. **Firewall Configuration**:
   ```bash
   # Configure UFW
   sudo ufw default deny incoming
   sudo ufw default allow outgoing
   sudo ufw allow 22/tcp
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

3. **SSH Hardening**:
   ```bash
   # /etc/ssh/sshd_config
   Port 2222                    # Change default port
   PermitRootLogin no           # Disable root login
   PasswordAuthentication no    # Use keys only
   PubkeyAuthentication yes     # Enable key auth
   MaxAuthTries 3               # Limit auth attempts
   ClientAliveInterval 300      # Auto-disconnect idle
   ```

### Deployment Security

1. **Use dedicated deployment user**:
   ```bash
   # Create deploy user
   sudo useradd -m -s /bin/bash deploy
   sudo usermod -aG docker deploy
   
   # Limited sudo access
   echo "deploy ALL=(ALL) NOPASSWD: /usr/bin/docker, /usr/bin/docker-compose" | sudo tee /etc/sudoers.d/deploy
   ```

2. **Secure file permissions**:
   ```bash
   # Set correct permissions
   chmod 600 .env
   chmod 700 ssl/
   chmod 600 ssl/*.pem
   ```

3. **Network security**:
   ```bash
   # Use internal networks
   docker network create --internal backend-network
   
   # Limit exposed ports
   docker run -p 127.0.0.1:8080:80 gladys-blog
   ```

### Jenkins Security

1. **Secure Jenkins configuration**:
   ```groovy
   // Jenkinsfile security
   pipeline {
       agent any
       
       options {
           // Prevent concurrent builds
           disableConcurrentBuilds()
           
           // Timeout builds
           timeout(time: 30, unit: 'MINUTES')
       }
       
       environment {
           // Use Jenkins credentials
           DEPLOY_KEY = credentials('deploy-ssh-key')
           DOMAIN = credentials('domain-name')
       }
   }
   ```

2. **Credential management**:
   ```bash
   # Store credentials securely in Jenkins
   # Never hardcode in Jenkinsfile
   withCredentials([string(credentialsId: 'api-key', variable: 'API_KEY')]) {
       sh 'deploy-with-key.sh $API_KEY'
   }
   ```

## 📊 Monitoring & Incident Response

### Security Monitoring

1. **Log monitoring**:
   ```bash
   # Monitor access logs
   tail -f /var/log/nginx/access.log | grep -E "(40[1-4]|50[0-5])"
   
   # Monitor for suspicious activity
   grep -i "attack\|hack\|exploit" /var/log/nginx/access.log
   ```

2. **Automated alerts**:
   ```bash
   # Create monitoring script
   #!/bin/bash
   # /home/deploy/security-monitor.sh
   
   # Check for failed login attempts
   failed_logins=$(grep "Failed password" /var/log/auth.log | wc -l)
   if [ $failed_logins -gt 10 ]; then
       curl -X POST "$WEBHOOK_URL" -d "🚨 High number of failed login attempts: $failed_logins"
   fi
   
   # Check SSL certificate expiry
   if ! openssl x509 -checkend 604800 -noout -in /etc/ssl/cert.pem; then
       curl -X POST "$WEBHOOK_URL" -d "⚠️ SSL certificate expires within 7 days"
   fi
   ```

3. **Health checks**:
   ```yaml
   # Enhanced health check
   healthcheck:
     test: |
       curl -f https://localhost/health &&
       curl -f https://localhost/security-check
     interval: 60s
     timeout: 10s
     retries: 3
     start_period: 30s
   ```

### Incident Response

1. **Emergency procedures**:
   ```bash
   # Immediate response to security incident
   
   # 1. Isolate the system
   sudo ufw deny in
   
   # 2. Stop all services
   docker stop $(docker ps -q)
   
   # 3. Preserve evidence
   cp -r /var/log/ /tmp/incident-$(date +%Y%m%d-%H%M%S)/
   
   # 4. Notify team
   curl -X POST "$ALERT_WEBHOOK" -d "🚨 SECURITY INCIDENT - System isolated"
   ```

2. **Recovery procedures**:
   ```bash
   # Recovery checklist
   # 1. Analyze logs
   # 2. Patch vulnerabilities
   # 3. Rotate all secrets
   # 4. Update all dependencies
   # 5. Gradual service restoration
   # 6. Enhanced monitoring
   ```

## ✅ Security Checklist

### Pre-Deployment Checklist

- [ ] All secrets removed from git repository
- [ ] `.env` files properly configured and ignored
- [ ] SSL certificates properly generated and secured
- [ ] Container running as non-root user
- [ ] Strong SSL configuration applied
- [ ] Security headers configured
- [ ] Rate limiting enabled
- [ ] Firewall properly configured
- [ ] SSH properly hardened
- [ ] Monitoring and alerting configured

### Regular Security Tasks

#### Weekly
- [ ] Check for security updates
- [ ] Review access logs for anomalies
- [ ] Test backup and recovery procedures

#### Monthly
- [ ] Update Docker images
- [ ] Review SSL certificate expiry
- [ ] Security scan of containers
- [ ] Review user access and permissions

#### Quarterly
- [ ] Full security assessment
- [ ] Rotate SSH keys
- [ ] Review and update security policies
- [ ] Penetration testing (if applicable)

### Emergency Contacts

| Role | Contact | When to Contact |
|------|---------|----------------|
| System Admin | admin@example.com | System compromises |
| DevOps Team | devops@example.com | Deployment issues |
| Security Team | security@example.com | Security incidents |
| On-call Engineer | +1-XXX-XXX-XXXX | Service outages |

## 📚 Additional Resources

### Security Tools
- **Container Scanning**: [Trivy](https://github.com/aquasecurity/trivy)
- **SSL Testing**: [SSL Labs](https://www.ssllabs.com/ssltest/)
- **Security Headers**: [Security Headers](https://securityheaders.com/)
- **Dependency Scanning**: [Snyk](https://snyk.io/)

### Documentation
- [OWASP Docker Security](https://owasp.org/www-project-docker-top-10/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [Let's Encrypt Best Practices](https://letsencrypt.org/docs/)
- [Nginx Security](https://nginx.org/en/docs/http/nginx_security.html)

### Training
- Security awareness training for all team members
- Regular security workshops
- Stay updated with security advisories

---

## 🔴 Emergency Security Response

**If you suspect a security breach:**

1. **STOP** - Don't panic, but act quickly
2. **ISOLATE** - Disconnect affected systems
3. **PRESERVE** - Save logs and evidence
4. **NOTIFY** - Contact security team immediately
5. **DOCUMENT** - Record all actions taken

**Emergency Contact**: security@example.com | +1-XXX-XXX-XXXX

---

*Last updated: $(date)*
*Review this document quarterly and after any security incidents.*