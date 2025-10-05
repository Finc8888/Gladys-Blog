#!/bin/bash

# Hugo Build Fix Script
# Fixes common Hugo build issues in Docker containers

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BLOG_DIR="$PROJECT_ROOT/blog"

# Function to show usage
show_usage() {
    echo "Hugo Build Fix Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --fix-git          Fix git repository issues"
    echo "  --fix-theme        Fix theme and layout issues"
    echo "  --fix-shortcodes   Fix problematic shortcodes"
    echo "  --fix-config       Fix Hugo configuration"
    echo "  --test-build       Test Hugo build locally"
    echo "  --fix-all          Apply all fixes"
    echo "  --docker-rebuild   Rebuild Docker containers"
    echo "  --help             Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 --fix-all       # Apply all fixes"
    echo "  $0 --test-build    # Test build locally"
    echo "  $0 --docker-rebuild # Rebuild containers"
    echo ""
}

# Function to check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    if [ ! -d "$BLOG_DIR" ]; then
        error "Blog directory not found: $BLOG_DIR"
        exit 1
    fi
    
    cd "$BLOG_DIR"
    
    if ! command -v hugo &> /dev/null; then
        warn "Hugo not found locally. Docker will be used for building."
        return 1
    fi
    
    success "Prerequisites check completed"
    return 0
}

# Function to fix git repository issues
fix_git_issues() {
    log "Fixing git repository issues..."
    
    cd "$BLOG_DIR"
    
    # Initialize git if not present
    if [ ! -d ".git" ]; then
        log "Initializing git repository..."
        git init
        git config user.email "docker@gladys-blog.com"
        git config user.name "Docker Build"
        git add .
        git commit -m "Initial commit for Hugo build" || true
        success "Git repository initialized"
    else
        info "Git repository already exists"
    fi
    
    # Update .gitignore for Hugo
    if [ ! -f ".gitignore" ]; then
        log "Creating Hugo .gitignore..."
        cat > .gitignore << 'EOF'
# Hugo
public/
resources/
.hugo_build.lock

# OS
.DS_Store
Thumbs.db

# Editor
*.swp
*.swo
*~
EOF
        success ".gitignore created"
    fi
}

# Function to fix theme issues
fix_theme_issues() {
    log "Fixing theme and layout issues..."
    
    cd "$BLOG_DIR"
    
    # Check if theme exists
    if [ ! -d "themes/archie" ]; then
        error "Theme 'archie' not found"
        log "Attempting to fix theme..."
        
        # Create themes directory
        mkdir -p themes
        cd themes
        
        # Clone theme
        if git clone https://github.com/athul/archie.git; then
            success "Theme cloned successfully"
        else
            warn "Failed to clone theme, creating fallback layouts..."
            cd "$BLOG_DIR"
            create_fallback_layouts
        fi
    else
        info "Theme 'archie' found"
        
        # Update theme if it's a git repository
        cd themes/archie
        if [ -d ".git" ]; then
            log "Updating theme..."
            git pull origin master || git pull origin main || warn "Failed to update theme"
        fi
    fi
    
    cd "$BLOG_DIR"
}

# Function to create fallback layouts
create_fallback_layouts() {
    log "Creating fallback layouts..."
    
    cd "$BLOG_DIR"
    mkdir -p layouts/_default
    
    # Create basic single page layout
    cat > layouts/_default/single.html << 'EOF'
<!DOCTYPE html>
<html lang="{{ .Site.LanguageCode | default "en" }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ .Title }} - {{ .Site.Title }}</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1 { color: #333; }
        .meta { color: #666; margin-bottom: 20px; }
        .content { line-height: 1.6; }
    </style>
</head>
<body>
    <header>
        <h1><a href="{{ .Site.BaseURL }}" style="text-decoration: none; color: inherit;">{{ .Site.Title }}</a></h1>
    </header>
    <main>
        <article>
            <h1>{{ .Title }}</h1>
            <div class="meta">
                {{ if .Date }}Published: {{ .Date.Format "2006-01-02" }}{{ end }}
                {{ if .Params.tags }}| Tags: {{ range .Params.tags }}<span>{{ . }}</span> {{ end }}{{ end }}
            </div>
            <div class="content">
                {{ .Content }}
            </div>
        </article>
    </main>
</body>
</html>
EOF

    # Create basic list layout
    cat > layouts/_default/list.html << 'EOF'
<!DOCTYPE html>
<html lang="{{ .Site.LanguageCode | default "en" }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ .Title }} - {{ .Site.Title }}</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        h1 { color: #333; }
        .post { margin-bottom: 20px; padding: 15px; border-left: 3px solid #007acc; }
        .post h2 { margin-top: 0; }
        .post a { text-decoration: none; color: #007acc; }
        .post a:hover { text-decoration: underline; }
        .meta { color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <header>
        <h1><a href="{{ .Site.BaseURL }}" style="text-decoration: none; color: inherit;">{{ .Site.Title }}</a></h1>
    </header>
    <main>
        <h1>{{ .Title }}</h1>
        {{ range .Pages }}
        <div class="post">
            <h2><a href="{{ .Permalink }}">{{ .Title }}</a></h2>
            <div class="meta">
                {{ if .Date }}{{ .Date.Format "2006-01-02" }}{{ end }}
                {{ if .Params.tags }}| {{ range .Params.tags }}{{ . }} {{ end }}{{ end }}
            </div>
            <p>{{ .Summary }}</p>
        </div>
        {{ end }}
    </main>
</body>
</html>
EOF

    # Create index layout
    cp layouts/_default/list.html layouts/index.html

    success "Fallback layouts created"
}

# Function to fix shortcode issues
fix_shortcode_issues() {
    log "Fixing shortcode issues..."
    
    cd "$BLOG_DIR"
    
    # Find and fix problematic shortcodes
    log "Searching for problematic shortcodes..."
    
    # Fix x shortcode (Twitter)
    if grep -r "{{< x " content/ 2>/dev/null; then
        warn "Found 'x' shortcodes, commenting them out..."
        find content/ -name "*.md" -exec sed -i 's/{{< x /<!-- {{< x /g; s/ >}}/ >}} -->/g' {} \; 2>/dev/null || true
    fi
    
    # Fix gist shortcode
    if grep -r "{{< gist " content/ 2>/dev/null; then
        warn "Found 'gist' shortcodes, commenting them out..."
        find content/ -name "*.md" -exec sed -i 's/{{< gist /<!-- {{< gist /g; s/ >}}/ >}} -->/g' {} \; 2>/dev/null || true
    fi
    
    success "Shortcode issues fixed"
}

# Function to fix Hugo configuration
fix_hugo_config() {
    log "Fixing Hugo configuration..."
    
    cd "$BLOG_DIR"
    
    # Backup original config
    if [ -f "hugo.toml" ]; then
        cp hugo.toml hugo.toml.backup
    fi
    
    # Update configuration
    cat > hugo.toml << 'EOF'
baseURL = '/'
languageCode = 'ru'
title = 'Gladys-ai blog'
theme = "archie"
copyright = "© 2025 Gladys-ai blog"

# Code Highlight
pygmentsstyle = "monokai"
pygmentscodefences = true
pygmentscodefencesguesssyntax = true

pagination.pagerSize = 3

# Build configuration - disable problematic features
enableGitInfo = false
ignoreErrors = ["error-missing-layout"]
ignoreLogs = ['shortcode-x-getremote', 'shortcode-gist']
buildFuture = true
buildExpired = true
buildDrafts = false

[params]
    mode = "auto"
    useCDN = false
    subtitle = "Персональный блог о математике, программировании и науке"
    mathjax = true
    katex = true

[[params.social]]
name = "GitHub"
icon = "github"
url = "https://github.com/athul/archie"

[[menu.main]]
name = "Главная"
url = "/"
weight = 1

[[menu.main]]
name = "Все посты"
url = "/posts"
weight = 2

[[menu.main]]
name = "О блоге"
url = "/about"
weight = 3

[[menu.main]]
name = "Теги"
url = "/tags"
weight = 4
EOF

    success "Hugo configuration updated"
}

# Function to test Hugo build
test_hugo_build() {
    log "Testing Hugo build..."
    
    cd "$BLOG_DIR"
    
    if command -v hugo &> /dev/null; then
        log "Testing with local Hugo installation..."
        
        # Clean previous builds
        rm -rf public/
        rm -rf resources/
        
        # Test build
        if hugo --minify --destination public --baseURL "/" --cleanDestinationDir --ignoreCache; then
            success "Local Hugo build successful"
            ls -la public/
            return 0
        else
            error "Local Hugo build failed"
            return 1
        fi
    else
        log "Local Hugo not available, testing with Docker..."
        
        # Create temporary Dockerfile for testing
        cat > Dockerfile.test << 'EOF'
FROM alpine:latest

WORKDIR /src

RUN apk add --no-cache \
    --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community \
    hugo git

COPY . .

RUN git init && \
    git config user.email "test@test.com" && \
    git config user.name "Test" && \
    git add . && \
    git commit -m "test" || true

RUN hugo --minify --destination /dist --baseURL "/" --cleanDestinationDir --ignoreCache

CMD ["ls", "-la", "/dist"]
EOF

        if docker build -f Dockerfile.test -t hugo-test . && docker run --rm hugo-test; then
            success "Docker Hugo build test successful"
            rm -f Dockerfile.test
            return 0
        else
            error "Docker Hugo build test failed"
            rm -f Dockerfile.test
            return 1
        fi
    fi
}

# Function to rebuild Docker containers
rebuild_docker_containers() {
    log "Rebuilding Docker containers..."
    
    cd "$PROJECT_ROOT"
    
    # Stop existing containers
    docker-compose -f docker-compose.ssl.yaml down 2>/dev/null || true
    docker-compose -f docker-compose.yaml down 2>/dev/null || true
    
    # Remove existing images
    docker rmi gladys-blog:latest 2>/dev/null || true
    docker rmi $(docker images | grep gladys-blog | awk '{print $3}') 2>/dev/null || true
    
    # Build new image
    log "Building new Docker image..."
    if docker build -f deploy/Dockerfile.prod.ssl -t gladys-blog:ssl .; then
        success "Docker SSL image built successfully"
    else
        warn "SSL build failed, trying simple build..."
        if docker build -f deploy/Dockerfile.prod.simple -t gladys-blog:simple .; then
            success "Simple Docker image built successfully"
        else
            error "All Docker builds failed"
            return 1
        fi
    fi
    
    success "Docker containers rebuilt"
}

# Main function
main() {
    local fix_git=0
    local fix_theme=0
    local fix_shortcodes=0
    local fix_config=0
    local test_build=0
    local rebuild_docker=0
    local fix_all=0
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --fix-git)
                fix_git=1
                shift
                ;;
            --fix-theme)
                fix_theme=1
                shift
                ;;
            --fix-shortcodes)
                fix_shortcodes=1
                shift
                ;;
            --fix-config)
                fix_config=1
                shift
                ;;
            --test-build)
                test_build=1
                shift
                ;;
            --docker-rebuild)
                rebuild_docker=1
                shift
                ;;
            --fix-all)
                fix_all=1
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # If no specific options, show usage
    if [ $fix_git -eq 0 ] && [ $fix_theme -eq 0 ] && [ $fix_shortcodes -eq 0 ] && [ $fix_config -eq 0 ] && [ $test_build -eq 0 ] && [ $rebuild_docker -eq 0 ] && [ $fix_all -eq 0 ]; then
        show_usage
        exit 1
    fi
    
    log "Hugo Build Fix Script Starting..."
    
    check_prerequisites || warn "Some prerequisites missing, continuing anyway..."
    
    # Apply fixes
    if [ $fix_all -eq 1 ] || [ $fix_git -eq 1 ]; then
        fix_git_issues
    fi
    
    if [ $fix_all -eq 1 ] || [ $fix_theme -eq 1 ]; then
        fix_theme_issues
    fi
    
    if [ $fix_all -eq 1 ] || [ $fix_shortcodes -eq 1 ]; then
        fix_shortcode_issues
    fi
    
    if [ $fix_all -eq 1 ] || [ $fix_config -eq 1 ]; then
        fix_hugo_config
    fi
    
    if [ $fix_all -eq 1 ] || [ $test_build -eq 1 ]; then
        test_hugo_build
    fi
    
    if [ $rebuild_docker -eq 1 ]; then
        rebuild_docker_containers
    fi
    
    success "Hugo build fix completed!"
    
    info "Next steps:"
    echo "1. Test locally: ./deploy/fix-hugo-build.sh --test-build"
    echo "2. Rebuild Docker: ./deploy/fix-hugo-build.sh --docker-rebuild"
    echo "3. Deploy: ./deploy/ssl-deploy.sh prod"
}

# Run main with all arguments
main "$@"