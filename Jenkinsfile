pipeline {
    agent any

    environment {
        // Docker image settings
        IMAGE_NAME = "gladys-blog"
        IMAGE_TAG = "${BUILD_NUMBER}"
        CONTAINER_NAME = "gladys-blog-container"

        // Server settings
        SERVER_HOST = "${params.SERVER_HOST ?: 'your-server.com'}"
        SERVER_USER = "${params.SERVER_USER ?: 'deploy'}"
        DEPLOY_PORT = "80"

        // Docker registry (optional)
        REGISTRY_URL = "${params.REGISTRY_URL ?: ''}"

        // Paths
        DOCKERFILE_PATH = "deploy/Dockerfile"
        BUILD_CONTEXT = "."
    }

    parameters {
        string(name: 'SERVER_HOST', defaultValue: 'your-server.com', description: 'Server host for deployment')
        string(name: 'SERVER_USER', defaultValue: 'deploy', description: 'User for SSH connection')
        string(name: 'REGISTRY_URL', defaultValue: '', description: 'Docker registry URL (optional)')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Skip tests')
        booleanParam(name: 'FORCE_DEPLOY', defaultValue: false, description: 'Force deployment')
        choice(name: 'ENVIRONMENT', choices: ['production', 'staging'], description: 'Environment for deployment')
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "🚀 Starting GladysAI-Blog deployment"
                    echo "Build: ${BUILD_NUMBER}"
                    echo "Environment: ${params.ENVIRONMENT}"
                    echo "Server: ${SERVER_HOST}"
                }

                // Clean workspace
                cleanWs()

                // Checkout code
                checkout scm

                // Show commit information
                script {
                    def gitCommit = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
                    def gitBranch = sh(returnStdout: true, script: 'git rev-parse --abbrev-ref HEAD').trim()
                    def gitMessage = sh(returnStdout: true, script: 'git log -1 --pretty=%B').trim()

                    echo "Git Branch: ${gitBranch}"
                    echo "Git Commit: ${gitCommit}"
                    echo "Commit Message: ${gitMessage}"
                }
            }
        }

        stage('Validate') {
            steps {
                script {
                    echo "🔍 Project validation"

                    // Check for required files
                    if (!fileExists(DOCKERFILE_PATH)) {
                        error("Dockerfile not found: ${DOCKERFILE_PATH}")
                    }

                    if (!fileExists('blog/hugo.toml')) {
                        error("Hugo configuration not found: blog/hugo.toml")
                    }

                    echo "✅ All required files found"
                }
            }
        }

        stage('Build Hugo Site') {
            when {
                not { params.SKIP_TESTS }
            }
            steps {
                script {
                    echo "🏗️ Building Hugo site for testing"

                    // Create temporary container for build
                    sh """
                        docker build -f ${DOCKERFILE_PATH} -t ${IMAGE_NAME}-temp:${BUILD_NUMBER} .
                        docker run --rm -v \$(pwd)/blog:/blog -v \$(pwd)/public:/blog/public \
                            ${IMAGE_NAME}-temp:${BUILD_NUMBER} hugo --destination /blog/public
                    """

                    // Check that site was built
                    if (!fileExists('public/index.html')) {
                        error("Hugo build error - public/index.html missing")
                    }

                    echo "✅ Hugo site built successfully"
                }
            }
            post {
                always {
                    // Cleanup temporary image
                    sh "docker rmi ${IMAGE_NAME}-temp:${BUILD_NUMBER} || true"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Building Docker image"

                    // Create optimized Dockerfile for production
                    writeFile file: 'Dockerfile.prod', text: '''
FROM alpine:latest as hugo-builder
WORKDIR /blog
RUN apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community hugo
COPY blog/ ./
RUN hugo --minify --destination /public

FROM nginx:alpine
RUN apk add --no-cache curl
COPY --from=hugo-builder /public /usr/share/nginx/html
COPY deploy/nginx.conf /etc/nginx/nginx.conf 2>/dev/null || echo "No custom nginx.conf found"

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

EXPOSE 80
'''

                    // Create nginx configuration if it doesn't exist
                    if (!fileExists('deploy/nginx.conf')) {
                        writeFile file: 'deploy/nginx.conf', text: '''
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    sendfile on;
    keepalive_timeout 65;
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;

    server {
        listen 80;
        server_name _;
        root /usr/share/nginx/html;
        index index.html;

        location / {
            try_files $uri $uri/ /index.html;
        }

        location /health {
            access_log off;
            return 200 "healthy\\n";
            add_header Content-Type text/plain;
        }
    }
}
'''
                    }

                    // Build image
                    def image = docker.build("${IMAGE_NAME}:${IMAGE_TAG}", "-f Dockerfile.prod .")

                    // Tag as latest
                    sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest"

                    echo "✅ Docker image built: ${IMAGE_NAME}:${IMAGE_TAG}"
                }
            }
        }

        stage('Push to Registry') {
            when {
                expression { params.REGISTRY_URL != '' }
            }
            steps {
                script {
                    echo "📤 Pushing image to registry"

                    docker.withRegistry(params.REGISTRY_URL, 'docker-registry-credentials') {
                        def image = docker.image("${IMAGE_NAME}:${IMAGE_TAG}")
                        image.push()
                        image.push("latest")
                    }

                    echo "✅ Image pushed to registry"
                }
            }
        }

        stage('Deploy to Server') {
            steps {
                script {
                    echo "🚀 Deploying to server ${SERVER_HOST}"

                    // Connect to server and deploy
                    sshagent(['ssh-deploy-key']) {

                        // Create deploy script
                        def deployScript = '''#!/bin/bash
set -e

IMAGE_NAME="''' + IMAGE_NAME + '''"
IMAGE_TAG="''' + IMAGE_TAG + '''"
CONTAINER_NAME="''' + CONTAINER_NAME + '''"
DEPLOY_PORT="''' + DEPLOY_PORT + '''"

echo "🚀 Starting deployment on $(hostname)"
echo "Image: $IMAGE_NAME:$IMAGE_TAG"
echo "Container: $CONTAINER_NAME"
echo "Port: $DEPLOY_PORT"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check application health
health_check() {
    local max_attempts=30
    local attempt=1

    log "Checking application health..."

    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost:$DEPLOY_PORT/health >/dev/null 2>&1; then
            log "✅ Application is ready!"
            return 0
        fi

        log "Attempt $attempt/$max_attempts - application not ready yet"
        sleep 2
        attempt=$((attempt + 1))
    done

    log "❌ Application not responding after $max_attempts attempts"
    return 1
}

# Stop and remove old container
if docker ps -q -f name=$CONTAINER_NAME | grep -q .; then
    log "Stopping old container..."
    docker stop $CONTAINER_NAME || true
fi

if docker ps -aq -f name=$CONTAINER_NAME | grep -q .; then
    log "Removing old container..."
    docker rm $CONTAINER_NAME || true
fi

# Start new container
log "Starting new container..."
docker run -d \
    --name $CONTAINER_NAME \
    --restart unless-stopped \
    -p $DEPLOY_PORT:80 \
    --memory="512m" \
    --cpus="1.0" \
    --log-driver json-file \
    --log-opt max-size=10m \
    --log-opt max-file=3 \
    $IMAGE_NAME:$IMAGE_TAG

# Health check
if health_check; then
    log "🎉 Deployment completed successfully!"

    # Cleanup old images (keep last 3)
    log "Cleaning up old images..."
    docker images $IMAGE_NAME --format "table {{.Repository}}:{{.Tag}}" | grep -v "TAG\\|latest" | tail -n +4 | xargs -r docker rmi || true

    # Show status
    log "Container status:"
    docker ps --filter name=$CONTAINER_NAME --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"

    exit 0
else
    log "❌ Deployment failed - application not responding"

    # Attempt rollback (if backup exists)
    if docker images -q $IMAGE_NAME:backup >/dev/null 2>&1; then
        log "Attempting rollback to previous version..."
        docker stop $CONTAINER_NAME || true
        docker rm $CONTAINER_NAME || true

        docker run -d \
            --name $CONTAINER_NAME \
            --restart unless-stopped \
            -p $DEPLOY_PORT:80 \
            $IMAGE_NAME:backup

        if health_check; then
            log "✅ Rollback completed successfully"
        else
            log "❌ Rollback also failed"
        fi
    fi

    exit 1
fi
'''

                        // Save image as backup before update
                        sh """
                            ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_HOST} '
                                if docker images -q ${IMAGE_NAME}:latest >/dev/null 2>&1; then
                                    echo "Creating backup of previous version..."
                                    docker tag ${IMAGE_NAME}:latest ${IMAGE_NAME}:backup || true
                                fi
                            '
                        """

                        // Copy image to server
                        if (params.REGISTRY_URL == '') {
                            echo "📦 Copying Docker image to server..."
                            sh """
                                docker save ${IMAGE_NAME}:${IMAGE_TAG} | \
                                ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_HOST} \
                                'docker load && docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest'
                            """
                        } else {
                            echo "📦 Pulling image from registry on server..."
                            sh """
                                ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_HOST} \
                                'docker pull ${params.REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG} && \
                                 docker tag ${params.REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:${IMAGE_TAG} && \
                                 docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest'
                            """
                        }

                        // Execute deployment
                        sh """
                            echo '${deployScript}' | \
                            ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_HOST} \
                            'cat > deploy.sh && chmod +x deploy.sh && ./deploy.sh && rm deploy.sh'
                        """
                    }

                    echo "✅ Deployment completed successfully"
                }
            }
        }

        stage('Post-Deploy Tests') {
            steps {
                script {
                    echo "🧪 Post-deployment tests"

                    // Check site availability
                    def maxAttempts = 10
                    def attempt = 1
                    def siteAvailable = false

                    while (attempt <= maxAttempts && !siteAvailable) {
                        try {
                            sh "curl -f http://${SERVER_HOST}/ >/dev/null 2>&1"
                            siteAvailable = true
                            echo "✅ Site available on attempt ${attempt}"
                        } catch (Exception e) {
                            echo "Attempt ${attempt}/${maxAttempts} - site not available yet"
                            sleep 5
                            attempt++
                        }
                    }

                    if (!siteAvailable) {
                        error("❌ Site unavailable after ${maxAttempts} attempts")
                    }

                    // Additional checks
                    sh """
                        # Check HTTP status
                        STATUS=\$(curl -o /dev/null -s -w "%{http_code}" http://${SERVER_HOST}/)
                        if [ "\$STATUS" != "200" ]; then
                            echo "❌ Unexpected HTTP status: \$STATUS"
                            exit 1
                        fi

                        # Check for main content
                        if ! curl -s http://${SERVER_HOST}/ | grep -q "title\\|<h1"; then
                            echo "❌ Main content not found"
                            exit 1
                        fi

                        echo "✅ All checks passed successfully"
                    """
                }
            }
        }
    }

    post {
        always {
            script {
                // Cleanup local images
                sh """
                    docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true
                    docker rmi ${IMAGE_NAME}:latest || true
                    docker system prune -f || true
                """

                // Archive logs
                archiveArtifacts artifacts: 'public/**/*', allowEmptyArchive: true, fingerprint: true
            }
        }

        success {
            script {
                def message = """
🎉 *Deployment completed successfully!*

📋 *Details:*
• Build: #${BUILD_NUMBER}
• Environment: ${params.ENVIRONMENT}
• Server: ${SERVER_HOST}
• Image: ${IMAGE_NAME}:${IMAGE_TAG}
• URL: http://${SERVER_HOST}

⏱️ *Duration:* ${currentBuild.durationString}
👤 *Started by:* ${currentBuild.getBuildCauses('hudson.model.Cause$UserIdCause')[0]?.userId ?: 'System'}

🔗 *Links:*
• [Open site](http://${SERVER_HOST})
• [Jenkins Build](${BUILD_URL})
"""

                echo message

                // Send to Slack/Discord (if configured)
                try {
                    slackSend(
                        color: 'good',
                        message: message,
                        channel: '#deployments'
                    )
                } catch (Exception e) {
                    echo "Failed to send Slack notification: ${e.message}"
                }
            }
        }

        failure {
            script {
                def message = """
❌ *Deployment failed!*

📋 *Details:*
• Build: #${BUILD_NUMBER}
• Environment: ${params.ENVIRONMENT}
• Server: ${SERVER_HOST}
• Error Stage: ${env.STAGE_NAME}

⏱️ *Duration:* ${currentBuild.durationString}
👤 *Started by:* ${currentBuild.getBuildCauses('hudson.model.Cause$UserIdCause')[0]?.userId ?: 'System'}

🔗 *Links:*
• [Jenkins Build](${BUILD_URL})
• [Console Output](${BUILD_URL}console)
"""

                echo message

                // Send error notification
                try {
                    slackSend(
                        color: 'danger',
                        message: message,
                        channel: '#deployments'
                    )
                } catch (Exception e) {
                    echo "Failed to send Slack notification: ${e.message}"
                }

                // Attempt to collect diagnostic information
                sshagent(['ssh-deploy-key']) {
                    try {
                        sh """
                            echo "🔍 Collecting diagnostic information..."
                            ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_HOST} '
                                echo "=== Docker containers ==="
                                docker ps -a --filter name=${CONTAINER_NAME}

                                echo "=== Docker logs ==="
                                docker logs --tail 50 ${CONTAINER_NAME} 2>&1 || true

                                echo "=== Resource usage ==="
                                df -h /
                                free -h
                            ' || true
                        """
                    } catch (Exception e) {
                        echo "Failed to collect diagnostic information: ${e.message}"
                    }
                }
            }
        }

        cleanup {
            // Final cleanup
            cleanWs()
        }
    }
}
