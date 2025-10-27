#!/bin/bash

# Docker Container Setup Script for Claude Code Development Environment
# This script sets up a complete development environment in a Docker container
# Usage: Run as root in the container: bash setup-docker-container.sh

set -e  # Exit on error

# Configuration
DEVELOPER_USER="${DEVELOPER_USER:-developer}"
DEVELOPER_PASSWORD="${DEVELOPER_PASSWORD:-developer}"
NODE_VERSION="${NODE_VERSION:-lts}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root"
    exit 1
fi

log_info "Starting Docker container setup..."

# Step 1: Update package lists and upgrade existing packages
log_info "Step 1: Updating system packages..."
apt update
DEBIAN_FRONTEND=noninteractive apt upgrade -y

# Step 2: Install essential packages
log_info "Step 2: Installing essential packages..."
DEBIAN_FRONTEND=noninteractive apt install -y \
    curl \
    wget \
    sudo \
    git \
    vim \
    nano \
    build-essential \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    unzip \
    zip \
    htop \
    tree \
    jq \
    less \
    man-db

# Step 3: Create developer user if it doesn't exist
log_info "Step 3: Setting up developer user '$DEVELOPER_USER'..."
if id "$DEVELOPER_USER" &>/dev/null; then
    log_warn "User '$DEVELOPER_USER' already exists, skipping creation"
else
    useradd -m -s /bin/bash "$DEVELOPER_USER"
    log_info "Created user '$DEVELOPER_USER'"
fi

# Ensure home directory exists and has correct permissions
if [ ! -d "/home/$DEVELOPER_USER" ]; then
    mkdir -p "/home/$DEVELOPER_USER"
    log_info "Created home directory for '$DEVELOPER_USER'"
fi

chown -R "$DEVELOPER_USER:$DEVELOPER_USER" "/home/$DEVELOPER_USER"
log_info "Set permissions on home directory"

# Set password for developer user
log_info "Setting password for '$DEVELOPER_USER'..."
echo "$DEVELOPER_USER:$DEVELOPER_PASSWORD" | chpasswd
log_info "Password set to '$DEVELOPER_PASSWORD'"

# Step 4: Configure sudo privileges
log_info "Step 4: Configuring sudo privileges..."
if ! grep -q "^$DEVELOPER_USER ALL=(ALL) NOPASSWD:ALL" /etc/sudoers; then
    echo "$DEVELOPER_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    log_info "Granted passwordless sudo to '$DEVELOPER_USER'"
else
    log_warn "Sudo privileges already configured"
fi

# Step 5: Install Node.js
log_info "Step 5: Installing Node.js ($NODE_VERSION)..."
if command -v node &> /dev/null; then
    CURRENT_NODE=$(node --version)
    log_warn "Node.js already installed: $CURRENT_NODE"
    read -p "Reinstall Node.js? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping Node.js installation"
    else
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
        apt install -y nodejs
    fi
else
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
    apt install -y nodejs
    log_info "Installed Node.js $(node --version) and npm $(npm --version)"
fi

# Step 6: Install Claude Code and Codex
log_info "Step 6: Installing Claude Code and Codex..."

# Install Claude Code
if command -v claude-code &> /dev/null; then
    CURRENT_CLAUDE=$(su - "$DEVELOPER_USER" -c "claude-code --version" 2>/dev/null || echo "unknown")
    log_warn "Claude Code already installed: $CURRENT_CLAUDE"
else
    npm install -g @anthropic-ai/claude-code
    log_info "Installed Claude Code"
fi

# Install Codex
if command -v codex &> /dev/null; then
    CURRENT_CODEX=$(codex --version 2>/dev/null || echo "unknown")
    log_warn "Codex already installed: $CURRENT_CODEX"
else
    npm install -g @openai/codex
    log_info "Installed Codex"
fi

# Step 7: Configure git defaults for developer user
log_info "Step 7: Configuring git defaults..."
su - "$DEVELOPER_USER" -c "git config --global init.defaultBranch main" || true
su - "$DEVELOPER_USER" -c "git config --global pull.rebase false" || true
log_info "Git configuration complete"

# Step 8: Create useful directory structure
log_info "Step 8: Creating directory structure..."
su - "$DEVELOPER_USER" -c "mkdir -p ~/source ~/bin"
log_info "Created workspace directories"

# Step 8b: Clone docker repository
log_info "Step 8b: Cloning docker repository..."
if [ -d "/home/$DEVELOPER_USER/source/docker" ]; then
    log_warn "Docker repo already exists at ~/source/docker, skipping clone"
else
    su - "$DEVELOPER_USER" -c "cd ~/source && git clone https://github.com/jsperson/docker.git"
    log_info "Cloned docker repository to ~/source/docker"
fi

# Step 9: Set up bash aliases and environment
log_info "Step 9: Setting up shell environment..."
cat > "/home/$DEVELOPER_USER/.bash_aliases" <<'EOF'
# Useful aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias h='history'
alias c='clear'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
EOF

chown "$DEVELOPER_USER:$DEVELOPER_USER" "/home/$DEVELOPER_USER/.bash_aliases"
log_info "Created .bash_aliases"

# Step 10: Clean up
log_info "Step 10: Cleaning up..."
apt autoremove -y
apt clean
log_info "Cleanup complete"

# Summary
log_info "=========================================="
log_info "Setup complete! Summary:"
log_info "  User: $DEVELOPER_USER"
log_info "  Password: $DEVELOPER_PASSWORD"
log_info "  Node.js: $(node --version)"
log_info "  npm: $(npm --version)"
log_info "  Claude Code: $(command -v claude-code &> /dev/null && echo 'Installed' || echo 'Not installed')"
log_info "  Codex: $(command -v codex &> /dev/null && echo 'Installed' || echo 'Not installed')"
log_info "=========================================="
log_info "To switch to developer user, run:"
log_info "  su - $DEVELOPER_USER"
log_info "Or to start Claude Code:"
log_info "  su - $DEVELOPER_USER -c 'claude-code'"
log_info "Or to start Codex:"
log_info "  su - $DEVELOPER_USER -c 'codex'"
log_info "=========================================="
