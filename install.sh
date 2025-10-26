#!/bin/bash
#
# MUXI Installation Script
# https://install.muxi.org (or https://get.muxi.org)
#
# Usage:
#   Interactive:             curl -sSL https://install.muxi.org | sudo bash
#   Non-interactive:         curl -sSL https://install.muxi.org | bash -s -- --non-interactive
#   Non-interactive (custom): curl -sSL https://install.muxi.org | bash -s -- --non-interactive --components=server,cli
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ASCII Banner
BANNER="${CYAN}
 ███╗   ███╗██╗   ██╗██╗  ██╗██╗
 ████╗ ████║██║   ██║╚██╗██╔╝██║
 ██╔████╔██║██║   ██║ ╚███╔╝ ██║
 ██║╚██╔╝██║██║   ██║ ██╔██╗ ██║
 ██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗██║
 ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝
${NC}"

# Parse arguments
NON_INTERACTIVE=0
COMPONENTS="cli"  # Default: CLI only for non-interactive

for arg in "$@"; do
    case $arg in
        --non-interactive)
            NON_INTERACTIVE=1
            ;;
        --components=*)
            COMPONENTS="${arg#*=}"
            ;;
    esac
done

# Auto-detect interactive mode (if not explicitly set)
if [ "$NON_INTERACTIVE" = "0" ]; then
    if [ ! -t 0 ]; then
        # stdin is not a terminal (piped from curl)
        # Auto-enable non-interactive mode
        NON_INTERACTIVE=1
    fi
fi

# Constants
SERVER_REPO="muxi-ai/server"
CLI_REPO="muxi-ai/cli"
INSTALL_VERSION="${MUXI_VERSION:-latest}"  # Allow override with MUXI_VERSION env var

# Component flags (will be set based on user selection)
INSTALL_SERVER=0
INSTALL_CLI=0

# Detect platform
OS="$(uname -s)"
ARCH="$(uname -m)"

# Map architecture names
case "$ARCH" in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    *)
        echo -e "${RED}✗ Unsupported architecture: $ARCH${NC}"
        exit 1
        ;;
esac

# Map OS names
case "$OS" in
    Linux)
        OS="linux"
        ;;
    Darwin)
        OS="darwin"
        ;;
    *)
        echo -e "${RED}✗ Unsupported operating system: $OS${NC}"
        echo "  MUXI Server supports Linux and macOS"
        exit 1
        ;;
esac

# Helper functions
print_header() {
    echo ""
    echo "███╗   ███╗██╗   ██╗██╗  ██╗██╗"
    echo "████╗ ████║██║   ██║╚██╗██╔╝██║"
    echo "██╔████╔██║██║   ██║ ╚███╔╝ ██║"
    echo "██║╚██╔╝██║██║   ██║ ██╔██╗ ██║"
    echo "██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗██║"
    echo "╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝"
    echo ""
    echo "MUXI Server Installation"
    echo ""
}

info() {
    echo -e "${BLUE}→${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warn() {
    echo -e "${YELLOW}!${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Show banner (only in interactive mode)
if [ "$NON_INTERACTIVE" = "0" ]; then
    echo -e "$BANNER"
    echo "MUXI Installation"
    echo ""
fi

# Check if running as root
IS_ROOT=0
if [ "$EUID" = 0 ]; then
    IS_ROOT=1
fi

# Determine installation type
if [ "$IS_ROOT" = 1 ] && [ "$OS" = "linux" ]; then
    INSTALL_TYPE="system"
    INSTALL_DIR="/usr/local/bin"
    CONFIG_DIR="/etc/muxi/server"
    DATA_DIR="/var/lib/muxi"
    LOG_DIR="/var/log/muxi"
else
    INSTALL_TYPE="user"
    INSTALL_DIR="$HOME/.local/bin"
    CONFIG_DIR="$HOME/.muxi/server"
    DATA_DIR="$HOME/.muxi/server"
    LOG_DIR="$HOME/.muxi/server/logs"
fi

# Print header (only in interactive mode - moved to after component selection)
# We'll print this after we know what components to install

# Check for required commands
if ! command -v curl >/dev/null 2>&1; then
    error "curl is required but not installed"
    echo "  Install with: sudo apt install curl  (Debian/Ubuntu)"
    echo "  Install with: sudo yum install curl  (RHEL/CentOS)"
    echo "  Install with: brew install curl      (macOS)"
    exit 1
fi

# Create temporary directory
TMP_DIR="$(mktemp -d)"
trap "rm -rf $TMP_DIR" EXIT

# Create install directory
mkdir -p "$INSTALL_DIR"

# Installation functions
install_server() {
    info "Downloading MUXI Server from GitHub..."
    
    # Determine download URL
    BINARY_NAME="muxi-server-${OS}-${ARCH}"
    if [ "$INSTALL_VERSION" = "latest" ]; then
        DOWNLOAD_URL="https://github.com/${SERVER_REPO}/releases/latest/download/${BINARY_NAME}"
    else
        DOWNLOAD_URL="https://github.com/${SERVER_REPO}/releases/download/${INSTALL_VERSION}/${BINARY_NAME}"
    fi
    
    # Download binary
    if ! curl -fsSL -o "$TMP_DIR/muxi-server" "$DOWNLOAD_URL"; then
        error "Failed to download MUXI Server"
        echo ""
        echo "Possible reasons:"
        echo "  • No release available for $OS/$ARCH"
        echo "  • Network connectivity issues"
        echo "  • GitHub API rate limiting"
        echo ""
        echo "Try downloading manually from:"
        echo "  https://github.com/${SERVER_REPO}/releases"
        return 1
    fi
    
    success "Downloaded MUXI Server"
    
    # Create directories
    if [ "$INSTALL_TYPE" = "system" ]; then
        mkdir -p "$CONFIG_DIR" "$DATA_DIR" "$LOG_DIR"
        chmod 755 "$CONFIG_DIR" "$DATA_DIR" "$LOG_DIR"
    else
        mkdir -p "$HOME/.muxi/server"
    fi
    
    # Install binary
    mv "$TMP_DIR/muxi-server" "$INSTALL_DIR/muxi-server"
    chmod +x "$INSTALL_DIR/muxi-server"
    
    # Verify installation
    if ! "$INSTALL_DIR/muxi-server" version >/dev/null 2>&1; then
        error "Server binary verification failed"
        return 1
    fi
    
    VERSION_OUTPUT=$("$INSTALL_DIR/muxi-server" version 2>/dev/null || echo "unknown")
    success "Installed MUXI Server: $VERSION_OUTPUT"
}

install_cli() {
    info "Downloading MUXI CLI from GitHub..."
    
    # Determine download URL
    BINARY_NAME="muxi-${OS}-${ARCH}"
    if [ "$INSTALL_VERSION" = "latest" ]; then
        DOWNLOAD_URL="https://github.com/${CLI_REPO}/releases/latest/download/${BINARY_NAME}"
    else
        DOWNLOAD_URL="https://github.com/${CLI_REPO}/releases/download/${INSTALL_VERSION}/${BINARY_NAME}"
    fi
    
    # Download binary
    if ! curl -fsSL -o "$TMP_DIR/muxi" "$DOWNLOAD_URL"; then
        warn "MUXI CLI is not yet available"
        echo ""
        echo "The CLI is coming soon! For now, you can:"
        echo "  • Manage the server directly with muxi-server commands"
        echo "  • Use the REST API"
        echo "  • Check https://github.com/${CLI_REPO} for updates"
        echo ""
        return 0  # Not a failure - just not available yet
    fi
    
    success "Downloaded MUXI CLI"
    
    # Create CLI config directory
    mkdir -p "$HOME/.muxi"
    
    # Install binary
    mv "$TMP_DIR/muxi" "$INSTALL_DIR/muxi"
    chmod +x "$INSTALL_DIR/muxi"
    
    # Verify installation
    if ! "$INSTALL_DIR/muxi" version >/dev/null 2>&1; then
        error "CLI binary verification failed"
        return 1
    fi
    
    VERSION_OUTPUT=$("$INSTALL_DIR/muxi" version 2>/dev/null || echo "unknown")
    success "Installed MUXI CLI: $VERSION_OUTPUT"
}

# Perform installations based on component selection
echo ""
if [ "$INSTALL_SERVER" = "1" ]; then
    install_server || exit 1
fi

if [ "$INSTALL_CLI" = "1" ]; then
    install_cli  # Don't exit on failure - CLI might not exist yet
fi

echo ""
echo "────────────────────────────────────────────────────────────"
success "Installation complete!"
echo "────────────────────────────────────────────────────────────"
echo ""

# PATH management for user installs
if [ "$INSTALL_TYPE" = "user" ]; then
    # Check if already in PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        warn "Adding $INSTALL_DIR to PATH"
        echo ""
        
        # Detect shell and update appropriate config file
        SHELL_CONFIG=""
        SHELL_NAME=$(basename "$SHELL")
        
        case "$SHELL_NAME" in
            bash)
                if [ "$OS" = "darwin" ]; then
                    SHELL_CONFIG="$HOME/.bash_profile"
                else
                    SHELL_CONFIG="$HOME/.bashrc"
                fi
                ;;
            zsh)
                SHELL_CONFIG="$HOME/.zshrc"
                ;;
            fish)
                SHELL_CONFIG="$HOME/.config/fish/config.fish"
                ;;
            *)
                warn "Unknown shell: $SHELL_NAME"
                ;;
        esac
        
        if [ -n "$SHELL_CONFIG" ]; then
            # Add to PATH in shell config
            echo "" >> "$SHELL_CONFIG"
            echo "# Added by MUXI Server installer" >> "$SHELL_CONFIG"
            if [ "$SHELL_NAME" = "fish" ]; then
                echo "set -gx PATH $INSTALL_DIR \$PATH" >> "$SHELL_CONFIG"
            else
                echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_CONFIG"
            fi
            
            success "Added to $SHELL_CONFIG"
            echo ""
            info "Reload your shell:"
            echo "  source $SHELL_CONFIG"
            echo ""
            info "Or open a new terminal window"
        else
            # Fallback: show manual instructions
            warn "Please add to your PATH manually:"
            echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
            echo ""
            info "Add this to your shell config file:"
            echo "  ~/.bashrc (bash)"
            echo "  ~/.zshrc (zsh)"
            echo "  ~/.config/fish/config.fish (fish)"
        fi
        echo ""
    else
        success "$INSTALL_DIR is already in PATH"
        echo ""
    fi
fi

# Community email collection (only in interactive mode)
if [ "$NON_INTERACTIVE" = "0" ]; then
    echo ""
    echo -e "${CYAN}→ Join the MUXI community?${NC} (optional)"
    echo "  Get early access to features, workshops, and exclusive content!"
    echo ""
    read -p "  Email [press Enter to skip]: " USER_EMAIL
    echo ""
    
    # Send email to community API if provided
    if [ -n "$USER_EMAIL" ]; then
        # TODO: Send to https://api.muxi.org/community/subscribe
        # For now, just acknowledge
        success "Welcome to MUXI! Check your email for community resources."
        echo ""
    fi
    
    # Component selection
    echo ""
    echo -e "${CYAN}→ What would you like to install?${NC}"
    echo "  [1] Server + CLI (recommended for local development)"
    echo "  [2] CLI only (for managing remote servers)"
    echo "  [3] Server only (for production deployments)"
    echo ""
    read -p "  Choice [1]: " COMPONENT_CHOICE
    echo ""
    
    # Default to option 1
    COMPONENT_CHOICE="${COMPONENT_CHOICE:-1}"
    
    case "$COMPONENT_CHOICE" in
        1)
            INSTALL_SERVER=1
            INSTALL_CLI=1
            info "Installing: Server + CLI"
            ;;
        2)
            INSTALL_CLI=1
            info "Installing: CLI only"
            ;;
        3)
            INSTALL_SERVER=1
            info "Installing: Server only"
            ;;
        *)
            error "Invalid choice: $COMPONENT_CHOICE"
            exit 1
            ;;
    esac
else
    # Non-interactive: parse components from argument
    # Default is "cli" (set earlier)
    if [[ "$COMPONENTS" == *"server"* ]]; then
        INSTALL_SERVER=1
    fi
    if [[ "$COMPONENTS" == *"cli"* ]]; then
        INSTALL_CLI=1
    fi
    
    # If neither was specified, default to CLI only
    if [ "$INSTALL_SERVER" = "0" ] && [ "$INSTALL_CLI" = "0" ]; then
        INSTALL_CLI=1
    fi
fi

# Print header and installation details (after we know what to install)
if [ "$NON_INTERACTIVE" = "0" ]; then
    echo ""
fi

print_header

# Show what will be installed
info "Platform: $OS/$ARCH"
if [ "$INSTALL_SERVER" = "1" ] && [ "$INSTALL_CLI" = "1" ]; then
    info "Components: Server + CLI"
elif [ "$INSTALL_SERVER" = "1" ]; then
    info "Components: Server only"
elif [ "$INSTALL_CLI" = "1" ]; then
    info "Components: CLI only"
fi

# Show installation paths
if [ "$INSTALL_SERVER" = "1" ]; then
    if [ "$INSTALL_TYPE" = "system" ]; then
        info "Server binary: $INSTALL_DIR/muxi-server"
        info "Server config: $CONFIG_DIR"
        info "Server data:   $DATA_DIR"
        info "Server logs:   $LOG_DIR"
    else
        info "Server binary: $INSTALL_DIR/muxi-server"
        info "Server paths:  ~/.muxi/server/"
        
        if [ "$OS" = "darwin" ]; then
            warn "macOS detected: Using user-level install (no system paths)"
        fi
    fi
fi

if [ "$INSTALL_CLI" = "1" ]; then
    info "CLI binary: $INSTALL_DIR/muxi"
    info "CLI config: ~/.muxi/"
fi

echo ""

# Offer to configure server (only in interactive mode and if server was installed)
AUTO_CONFIGURE=0
if [ "$NON_INTERACTIVE" = "0" ] && [ "$INSTALL_SERVER" = "1" ]; then
    read -p "$(echo -e ${BLUE}→${NC}) Configure server now? [Y/n]: " configure_now
    echo ""
    
    if [ "$configure_now" != "n" ] && [ "$configure_now" != "N" ]; then
        AUTO_CONFIGURE=1
    fi
fi

# Run init if requested
if [ "$AUTO_CONFIGURE" = "1" ]; then
    info "Initializing MUXI Server..."
    echo ""
    
    if [ "$IS_ROOT" = 1 ]; then
        sudo -u "${SUDO_USER:-$USER}" "$INSTALL_DIR/muxi-server" init || {
            warn "Init requires non-root user. Run manually:"
            echo "  muxi-server init"
        }
    else
        "$INSTALL_DIR/muxi-server" init
    fi
    
    echo ""
    success "Server ready!"
    echo ""
    echo "Start server:"
    if [ "$IS_ROOT" = 1 ]; then
        echo "  sudo systemctl start muxi-server  # As service"
        echo "  # or"
        echo "  sudo muxi-server start            # Foreground"
    else
        echo "  muxi-server start"
    fi
    echo ""
    
    if [ "$INSTALL_CLI" = "1" ]; then
        echo "Connect CLI to server:"
        echo "  muxi profile add localhost http://localhost:7890"
        echo ""
    fi
    
    echo "Documentation: https://docs.muxi.org/getting-started"
    if [ "$INSTALL_SERVER" = "1" ]; then
        echo "Server repo:   https://github.com/${SERVER_REPO}"
    fi
    if [ "$INSTALL_CLI" = "1" ]; then
        echo "CLI repo:      https://github.com/${CLI_REPO}"
    fi
    echo ""
    exit 0
fi

# Manual next steps (if not auto-configured)
echo "Next steps:"
echo ""

STEP_NUM=1

if [ "$INSTALL_SERVER" = "1" ]; then
    if [ "$INSTALL_TYPE" = "system" ]; then
        echo "  ${STEP_NUM}. Initialize the server:"
        echo "     sudo muxi-server init"
        STEP_NUM=$((STEP_NUM + 1))
        echo ""
        echo "  ${STEP_NUM}. Start the server:"
        echo "     sudo muxi-server start"
        STEP_NUM=$((STEP_NUM + 1))
        echo ""
    else
        echo "  ${STEP_NUM}. Initialize the server:"
        echo "     muxi-server init"
        STEP_NUM=$((STEP_NUM + 1))
        echo ""
        echo "  ${STEP_NUM}. Start the server:"
        echo "     muxi-server start"
        STEP_NUM=$((STEP_NUM + 1))
        echo ""
    fi
fi

if [ "$INSTALL_CLI" = "1" ] && [ "$INSTALL_SERVER" = "1" ]; then
    echo "  ${STEP_NUM}. Connect CLI to local server:"
    echo "     muxi profile add localhost http://localhost:7890"
    STEP_NUM=$((STEP_NUM + 1))
    echo ""
elif [ "$INSTALL_CLI" = "1" ]; then
    echo "  ${STEP_NUM}. Connect CLI to a remote server:"
    echo "     muxi profile add production https://your-server.com:7890"
    STEP_NUM=$((STEP_NUM + 1))
    echo ""
fi

if [ "$INSTALL_CLI" = "1" ]; then
    echo "  ${STEP_NUM}. Try CLI commands:"
    echo "     muxi formation list"
    echo "     muxi formation deploy"
    STEP_NUM=$((STEP_NUM + 1))
    echo ""
fi

echo ""
echo "Documentation: https://docs.muxi.org/getting-started"
if [ "$INSTALL_SERVER" = "1" ]; then
    echo "Server repo:   https://github.com/${SERVER_REPO}"
fi
if [ "$INSTALL_CLI" = "1" ]; then
    echo "CLI repo:      https://github.com/${CLI_REPO}"
fi
echo ""
