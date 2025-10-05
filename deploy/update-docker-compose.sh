#!/bin/bash

# Docker Compose Update Script
# Updates Docker Compose to the latest version

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

# Function to show usage
show_usage() {
    echo "Docker Compose Update Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -v, --version VERSION   Install specific version (e.g., 2.21.0)"
    echo "  -f, --force            Force installation even if already latest"
    echo "  -b, --backup           Create backup of current version"
    echo "  -r, --rollback         Rollback to previous version"
    echo "  -c, --check            Only check current version"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                     # Update to latest version"
    echo "  $0 -v 2.21.0          # Install specific version"
    echo "  $0 --check            # Check current version"
    echo "  $0 --rollback         # Rollback to previous version"
    echo ""
}

# Function to get current Docker Compose version
get_current_version() {
    if command -v docker-compose &> /dev/null; then
        docker-compose --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
    else
        echo "not_installed"
    fi
}

# Function to get latest Docker Compose version
get_latest_version() {
    curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")'
}

# Function to check if sudo is needed
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        if ! sudo -n true 2>/dev/null; then
            warn "This script requires sudo privileges for installation"
            echo "Please enter your password when prompted"
        fi
        SUDO_CMD="sudo"
    else
        SUDO_CMD=""
    fi
}

# Function to backup current Docker Compose
backup_docker_compose() {
    local current_path=""
    
    if command -v docker-compose &> /dev/null; then
        current_path=$(which docker-compose)
        local backup_path="${current_path}.backup.$(date +%Y%m%d_%H%M%S)"
        
        log "Creating backup of current Docker Compose..."
        $SUDO_CMD cp "$current_path" "$backup_path"
        success "Backup created: $backup_path"
        
        # Store backup path for potential rollback
        echo "$backup_path" > /tmp/docker-compose-backup-path
    else
        warn "No existing Docker Compose found to backup"
    fi
}

# Function to install Docker Compose
install_docker_compose() {
    local version="$1"
    local install_path="/usr/local/bin/docker-compose"
    
    # Detect system architecture
    local arch=$(uname -m)
    local os=$(uname -s)
    
    case $arch in
        x86_64)
            arch="x86_64"
            ;;
        aarch64|arm64)
            arch="aarch64"
            ;;
        armv7l)
            arch="armv7"
            ;;
        *)
            error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac
    
    local download_url="https://github.com/docker/compose/releases/download/${version}/docker-compose-${os}-${arch}"
    
    log "Downloading Docker Compose ${version} for ${os}-${arch}..."
    
    # Download to temporary location
    local temp_file="/tmp/docker-compose-${version}"
    
    if curl -L "$download_url" -o "$temp_file"; then
        success "Download completed"
    else
        error "Failed to download Docker Compose ${version}"
        exit 1
    fi
    
    # Verify download
    if [ ! -f "$temp_file" ] || [ ! -s "$temp_file" ]; then
        error "Downloaded file is empty or missing"
        exit 1
    fi
    
    log "Installing Docker Compose to $install_path..."
    
    # Install the binary
    $SUDO_CMD mv "$temp_file" "$install_path"
    $SUDO_CMD chmod +x "$install_path"
    
    # Verify installation
    if docker-compose --version &> /dev/null; then
        local installed_version=$(get_current_version)
        success "Docker Compose ${installed_version} installed successfully"
        
        # Test basic functionality
        log "Testing Docker Compose functionality..."
        if docker-compose --help &> /dev/null; then
            success "Docker Compose is working correctly"
        else
            warn "Docker Compose installed but may have issues"
        fi
    else
        error "Installation failed - Docker Compose not working"
        exit 1
    fi
}

# Function to rollback to previous version
rollback_docker_compose() {
    local backup_path=""
    
    if [ -f /tmp/docker-compose-backup-path ]; then
        backup_path=$(cat /tmp/docker-compose-backup-path)
    fi
    
    if [ -z "$backup_path" ] || [ ! -f "$backup_path" ]; then
        error "No backup found for rollback"
        info "Available backups:"
        find /usr/local/bin/ -name "docker-compose.backup.*" 2>/dev/null || echo "  No backups found"
        exit 1
    fi
    
    log "Rolling back to previous version..."
    log "Backup path: $backup_path"
    
    # Restore backup
    $SUDO_CMD cp "$backup_path" /usr/local/bin/docker-compose
    $SUDO_CMD chmod +x /usr/local/bin/docker-compose
    
    # Verify rollback
    if docker-compose --version &> /dev/null; then
        local restored_version=$(get_current_version)
        success "Rollback successful - Docker Compose ${restored_version} restored"
    else
        error "Rollback failed"
        exit 1
    fi
}

# Function to check versions and show status
check_versions() {
    local current_version=$(get_current_version)
    
    if [ "$current_version" = "not_installed" ]; then
        warn "Docker Compose is not installed"
        return 1
    fi
    
    log "Current Docker Compose version: $current_version"
    
    # Try to get latest version
    info "Checking for latest version..."
    local latest_version=""
    
    if command -v curl &> /dev/null; then
        latest_version=$(get_latest_version 2>/dev/null || echo "unknown")
        if [ "$latest_version" != "unknown" ] && [ -n "$latest_version" ]; then
            info "Latest Docker Compose version: $latest_version"
            
            if [ "$current_version" = "$latest_version" ]; then
                success "You have the latest version"
                return 0
            else
                warn "Update available: $current_version → $latest_version"
                return 2
            fi
        else
            warn "Could not check latest version (network issue?)"
            return 1
        fi
    else
        warn "curl not found - cannot check latest version"
        return 1
    fi
}

# Main function
main() {
    local target_version=""
    local force_install=0
    local create_backup=1
    local check_only=0
    local rollback=0
    
    # Parse command line options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--version)
                target_version="$2"
                shift 2
                ;;
            -f|--force)
                force_install=1
                shift
                ;;
            -b|--backup)
                create_backup=1
                shift
                ;;
            --no-backup)
                create_backup=0
                shift
                ;;
            -r|--rollback)
                rollback=1
                shift
                ;;
            -c|--check)
                check_only=1
                shift
                ;;
            -h|--help)
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
    
    log "Docker Compose Update Script"
    echo ""
    
    # Handle rollback
    if [ $rollback -eq 1 ]; then
        check_sudo
        rollback_docker_compose
        exit 0
    fi
    
    # Check current status
    local version_check_result=0
    check_versions || version_check_result=$?
    
    # Handle check-only mode
    if [ $check_only -eq 1 ]; then
        exit $version_check_result
    fi
    
    # Determine target version
    if [ -z "$target_version" ]; then
        info "Getting latest version information..."
        target_version=$(get_latest_version)
        
        if [ -z "$target_version" ]; then
            error "Could not determine latest version"
            exit 1
        fi
    fi
    
    # Remove 'v' prefix if present
    target_version=${target_version#v}
    
    log "Target version: $target_version"
    
    # Check if update is needed
    local current_version=$(get_current_version)
    if [ "$current_version" = "$target_version" ] && [ $force_install -eq 0 ]; then
        success "Docker Compose $target_version is already installed"
        info "Use --force to reinstall"
        exit 0
    fi
    
    # Check for required tools
    if ! command -v curl &> /dev/null; then
        error "curl is required but not installed"
        exit 1
    fi
    
    # Check sudo access
    check_sudo
    
    # Create backup if requested
    if [ $create_backup -eq 1 ]; then
        backup_docker_compose
    fi
    
    # Install Docker Compose
    install_docker_compose "$target_version"
    
    echo ""
    success "Docker Compose update completed!"
    info "Old version: $current_version"
    info "New version: $(get_current_version)"
    
    # Show post-installation notes
    echo ""
    info "Post-installation notes:"
    echo "• Restart your shell or run 'hash -r' to refresh command cache"
    echo "• Test with: docker-compose --version"
    echo "• Rollback with: $0 --rollback (if backup was created)"
}

# Run main function with all arguments
main "$@"