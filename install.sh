#!/bin/bash
#
# MUXI Installation Script
# https://muxi.org/install
#
# Usage:
#   Interactive:       curl -sSL https://muxi.org/install | sudo bash
#   Non-interactive:   curl -sSL https://muxi.org/install | sudo bash -s --non-interactive
#   CLI only:          curl -sSL https://muxi.org/install | sudo bash -s --cli-only
#

set -e

# Telemetry endpoint
TELEMETRY_URL="https://capture.muxi.org"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GOLD='\033[38;2;201;139;69m'  # Brand color #c98b45
NC='\033[0m'

# Symbols
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
ARROW="${BLUE}→${NC}"
BULLET="•"
LINE="────────────────────────────────────────────────────────────"

# Spinner function - runs command with spinner
# Usage: spin "message" command [args...]
spin() {
    local msg="$1"
    shift
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local i=0
    
    # Run command in background
    "$@" &
    local pid=$!
    
    # Show spinner while command runs
    while kill -0 $pid 2>/dev/null; do
        printf "\r${BLUE}%s${NC} %s" "${frames[$i]}" "$msg"
        i=$(( (i + 1) % 10 ))
        sleep 0.1
    done
    
    # Wait for command and get exit code
    wait $pid
    local exit_code=$?
    
    # Clear the spinner line
    printf "\r\033[K"
    
    return $exit_code
}

# Detect headless environment (no GUI/browser available)
is_headless() {
    # SSH session
    [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] && return 0
    
    # No display (Linux)
    [ "$OS" = "linux" ] && [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && return 0
    
    # Docker/container
    [ -f "/.dockerenv" ] && return 0
    
    # CI environments
    [ -n "$CI" ] && return 0
    
    return 1
}

# Banner
BANNER="${GOLD}
███╗   ███╗██╗   ██╗██╗  ██╗██╗
████╗ ████║██║   ██║╚██╗██╔╝██║
██╔████╔██║██║   ██║ ╚███╔╝ ██║
██║╚██╔╝██║██║   ██║ ██╔██╗ ██║
██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗██║
╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝
${NC}"

# Parse arguments
NON_INTERACTIVE=0
CLI_ONLY=0
DRY_RUN=0
SKIP_DOWNLOAD=0

for arg in "$@"; do
    case $arg in
        --non-interactive)
            NON_INTERACTIVE=1
            ;;
        --cli-only)
            CLI_ONLY=1
            ;;
        --dry-run)
            DRY_RUN=1
            ;;
        --skip-download)
            SKIP_DOWNLOAD=1
            ;;
    esac
done

# Auto-detect interactive mode
if [ "$NON_INTERACTIVE" = "0" ] && [ ! -t 0 ]; then
    NON_INTERACTIVE=1
fi

# Detect platform
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$ARCH" in
    x86_64)  ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *)
        echo -e "${CROSS} Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

case "$OS" in
    linux|darwin) ;;
    *)
        echo -e "${CROSS} Unsupported OS: $OS"
        exit 1
        ;;
esac

# Setup paths based on privileges
if [ "$(id -u)" = "0" ]; then
    # Running as root (sudo) - production install
    INSTALL_DIR="/usr/local/bin"
    MUXI_DIR="/etc/muxi"
    IS_ROOT=1
else
    # User install
    INSTALL_DIR="$HOME/.local/bin"
    MUXI_DIR="$HOME/.muxi"
    IS_ROOT=0
fi
CONFIG_FILE="$MUXI_DIR/config.yaml"

# Read value from config.yaml
read_config() {
    local key=$1
    if [ -f "$CONFIG_FILE" ]; then
        grep "^$key:" "$CONFIG_FILE" 2>/dev/null | cut -d' ' -f2-
    fi
}

# Get OS-level machine identifier (deterministic)
get_os_machine_id() {
    local raw_id=""
    
    case "$OS" in
        darwin)
            # macOS: Hardware UUID
            raw_id=$(ioreg -rd1 -c IOPlatformExpertDevice 2>/dev/null | grep IOPlatformUUID | sed 's/.*"\([^"]*\)".*/\1/')
            ;;
        linux)
            # Linux: systemd machine-id or dbus machine-id
            if [ -f /etc/machine-id ]; then
                raw_id=$(cat /etc/machine-id)
            elif [ -f /var/lib/dbus/machine-id ]; then
                raw_id=$(cat /var/lib/dbus/machine-id)
            fi
            ;;
    esac
    
    echo "$raw_id"
}

# Generate deterministic machine_id from OS identifier
# Algorithm: sha256(os_machine_id + "muxi") -> format as UUID
generate_machine_id() {
    mkdir -p "$MUXI_DIR"
    
    # Check if already in config
    local mid=$(read_config "machine_id")
    if [ -n "$mid" ]; then
        echo "$mid"
        return
    fi
    
    # Get OS machine ID and hash it
    local os_id=$(get_os_machine_id)
    if [ -n "$os_id" ]; then
        # Hash with salt for privacy: sha256(os_id + "muxi")
        local hash=$(echo -n "${os_id}muxi" | shasum -a 256 | cut -d' ' -f1)
        # Format as UUID: 8-4-4-4-12
        mid="${hash:0:8}-${hash:8:4}-${hash:12:4}-${hash:16:4}-${hash:20:12}"
    else
        # Fallback to random UUID if OS ID not available
        if command -v uuidgen >/dev/null 2>&1; then
            mid=$(uuidgen | tr '[:upper:]' '[:lower:]')
        else
            mid=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "$(date +%s)-$$-$RANDOM")
        fi
    fi
    
    # Initialize config with machine_id and telemetry
    cat > "$CONFIG_FILE" << EOF
machine_id: $mid
telemetry: true
EOF
    echo "$mid"
}

# Get geo info (best effort, cached)
get_geo() {
    local geo_file="$MUXI_DIR/geo.json"
    local now=$(date +%s)
    
    # Check cache (24h) - only if it looks like valid JSON
    if [ -f "$geo_file" ]; then
        if grep -q '"ip"' "$geo_file" 2>/dev/null; then
            local cached_at=$(grep -o '"cached_at":[0-9]*' "$geo_file" 2>/dev/null | cut -d: -f2)
            if [ -n "$cached_at" ] && [ $((now - cached_at)) -lt 86400 ]; then
                cat "$geo_file"
                return
            fi
        else
            # Invalid cache, remove it
            rm -f "$geo_file"
        fi
    fi
    
    # Fetch fresh - try ip-api.com as fallback (no Cloudflare)
    local geo=$(curl -s --max-time 2 "http://ip-api.com/json/" 2>/dev/null || echo "{}")
    
    # Validate response contains expected fields
    if echo "$geo" | grep -q '"query"' 2>/dev/null; then
        # ip-api.com uses "query" for IP and "countryCode" for country
        local ip=$(echo "$geo" | grep -o '"query":"[^"]*"' | cut -d'"' -f4)
        local country=$(echo "$geo" | grep -o '"countryCode":"[^"]*"' | cut -d'"' -f4)
        # Normalize to our format
        geo="{\"ip\":\"$ip\",\"country_code\":\"$country\",\"cached_at\":$now}"
        echo "$geo" > "$geo_file"
        echo "$geo"
    else
        echo "{}"
    fi
}

# Send telemetry
send_telemetry() {
    local success=$1
    local duration_ms=$2
    local install_method=$3
    
    # Check opt-out (env var or config)
    if [ "$MUXI_TELEMETRY" = "0" ] || [ "$(read_config telemetry)" = "false" ]; then
        return
    fi
    
    # Convert to JSON booleans
    local server_json="false"
    local cli_json="false"
    [ "$INSTALL_SERVER" = "1" ] && server_json="true"
    [ "$INSTALL_CLI" = "1" ] && cli_json="true"
    
    local payload=$(cat <<EOF
{
  "module": "install",
  "machine_id": "$MACHINE_ID",
  "ts": "$INSTALL_TS",
  "country": "$GEO_COUNTRY",
  "payload": {
    "version": "0.1.0",
    "install_method": "$install_method",
    "os": "$OS",
    "arch": "$ARCH",
    "server": $server_json,
    "cli": $cli_json,
    "success": $success,
    "duration_ms": $duration_ms
  }
}
EOF
)
    
    # Fire and forget (disown to survive script exit)
    (curl -sL -X POST "$TELEMETRY_URL/v1/telemetry/" \
        -H "Content-Type: application/json" \
        -d "$payload" >/dev/null 2>&1 &)
}

# Send optin
send_optin() {
    local email=$1
    
    local geo=$(get_geo)
    local ip=$(echo "$geo" | grep -o '"ip":"[^"]*"' | cut -d'"' -f4)
    local country=$(echo "$geo" | grep -o '"country_code":"[^"]*"' | cut -d'"' -f4)
    
    # Determine install type
    local installed="cli"
    [ "$INSTALL_SERVER" = "1" ] && installed="all"
    
    local payload=$(cat <<EOF
{
  "email": "$email",
  "machine_id": "$MACHINE_ID",
  "ip": "$ip",
  "country": "$country",
  "installed": "$installed"
}
EOF
)
    
    # Fire and forget (subshell survives script exit)
    (curl -sL -X POST "$TELEMETRY_URL/v1/optin/" \
        -H "Content-Type: application/json" \
        -d "$payload" >/dev/null 2>&1 &)
}

# Write config
write_config() {
    local key=$1
    local value=$2
    
    mkdir -p "$MUXI_DIR"
    
    if [ -f "$CONFIG_FILE" ]; then
        # Update existing key or append
        if grep -q "^$key:" "$CONFIG_FILE" 2>/dev/null; then
            sed -i.bak "s/^$key:.*/$key: $value/" "$CONFIG_FILE" && rm -f "$CONFIG_FILE.bak"
        else
            echo "$key: $value" >> "$CONFIG_FILE"
        fi
    else
        echo "$key: $value" > "$CONFIG_FILE"
    fi
}

# Check for curl
if ! command -v curl >/dev/null 2>&1; then
    echo -e "${CROSS} curl is required but not installed"
    exit 1
fi

# Initialize
MACHINE_ID=$(generate_machine_id)
INSTALL_TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
START_TIME=$(date +%s)

# Get geo and save to config
GEO_DATA=$(get_geo)
GEO_COUNTRY=$(echo "$GEO_DATA" | grep -o '"country_code":"[^"]*"' | cut -d'"' -f4)
if [ -n "$GEO_COUNTRY" ]; then
    write_config "geo" "$GEO_COUNTRY"
fi

# Component selection
INSTALL_SERVER=1
INSTALL_CLI=1

if [ "$CLI_ONLY" = "1" ]; then
    INSTALL_SERVER=0
fi

# Show banner (interactive only)
if [ "$NON_INTERACTIVE" = "0" ]; then
    echo -e "$BANNER"
    echo "Welcome to MUXI installer!"
    echo ""
    
    # Component selection with radio buttons
    selected=1
    first_draw=0
    
    draw_menu() {
        if [ "$first_draw" = "1" ]; then
            printf "\033[3A\033[J"
        fi
        first_draw=1
        
        echo -e "${ARROW} What would you like to install?"
        if [ "$selected" = "1" ]; then
            echo -e "  ${GOLD}◉ Server + CLI (recommended)${NC}"
            echo "  ○ CLI only"
        else
            echo "  ○ Server + CLI (recommended)"
            echo -e "  ${GOLD}◉ CLI only${NC}"
        fi
    }
    
    draw_menu
    while true; do
        read -rsn1 key
        case "$key" in
            1) selected=1; draw_menu ;;
            2) selected=2; draw_menu ;;
            "") break ;;  # Enter key
            $'\x1b')  # Arrow keys
                read -rsn2 arrow
                case "$arrow" in
                    '[A'|'[B') 
                        [ "$selected" = "1" ] && selected=2 || selected=1
                        draw_menu
                        ;;
                esac
                ;;
        esac
    done
    echo ""
    
    case "$selected" in
        2)
            INSTALL_SERVER=0
            INSTALL_CLI=1
            ;;
        *)
            INSTALL_SERVER=1
            INSTALL_CLI=1
            ;;
    esac
fi

# Show what we're installing
echo -e "${ARROW} Platform: ${OS}/${ARCH}"
if [ "$INSTALL_SERVER" = "1" ] && [ "$INSTALL_CLI" = "1" ]; then
    echo -e "${ARROW} Installing: Server + CLI"
elif [ "$INSTALL_CLI" = "1" ]; then
    echo -e "${ARROW} Installing: CLI only"
fi
echo ""

# Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$MUXI_DIR"

# Temp directory for downloads
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

# ============================================================
# INSTALL SERVER
# ============================================================
if [ "$INSTALL_SERVER" = "1" ]; then
    if [ "$SKIP_DOWNLOAD" = "1" ]; then
        echo -e "${CHECK} Downloaded MUXI Server v0.0.0 (skipped)"
    else
        BINARY_NAME="muxi-server-${OS}-${ARCH}"
        
        # Get version from releases/latest redirect
        SERVER_VERSION=$(curl -sI "https://github.com/muxi-ai/server/releases/latest" | grep -i location | sed 's|.*/tag/||' | tr -d '\r\n')
        DOWNLOAD_URL="https://github.com/muxi-ai/server/releases/download/${SERVER_VERSION}/${BINARY_NAME}"
        
        printf "${BLUE}⠋${NC} Downloading MUXI Server..."
        if ! curl -fsSL -o "$TMP_DIR/muxi-server" "$DOWNLOAD_URL" 2>/dev/null; then
            printf "\r\033[K"
            echo -e "${CROSS} Failed to download MUXI Server"
            END_TIME=$(date +%s)
            DURATION_MS=$(( (END_TIME - START_TIME) * 1000 ))
            send_telemetry false $DURATION_MS "curl"
            exit 1
        fi
        
        printf "\r\033[K"
        chmod +x "$TMP_DIR/muxi-server"
        if [ "$DRY_RUN" = "0" ]; then
            mv "$TMP_DIR/muxi-server" "$INSTALL_DIR/muxi-server"
        fi
        echo -e "${CHECK} Downloaded MUXI Server ${SERVER_VERSION}"
    fi
fi

# ============================================================
# INSTALL CLI
# ============================================================
if [ "$INSTALL_CLI" = "1" ]; then
    if [ "$SKIP_DOWNLOAD" = "1" ]; then
        echo -e "${CHECK} Downloaded MUXI CLI v0.0.0 (skipped)"
    else
        BINARY_NAME="muxi-${OS}-${ARCH}"
        
        # Get version from releases/latest redirect
        CLI_VERSION=$(curl -sI "https://github.com/muxi-ai/cli/releases/latest" | grep -i location | sed 's|.*/tag/||' | tr -d '\r\n')
        DOWNLOAD_URL="https://github.com/muxi-ai/cli/releases/download/${CLI_VERSION}/${BINARY_NAME}"
        
        printf "${BLUE}⠋${NC} Downloading MUXI CLI..."
        if ! curl -fsSL -o "$TMP_DIR/muxi" "$DOWNLOAD_URL" 2>/dev/null; then
            printf "\r\033[K"
            echo -e "${CROSS} Failed to download MUXI CLI"
            END_TIME=$(date +%s)
            DURATION_MS=$(( (END_TIME - START_TIME) * 1000 ))
            send_telemetry false $DURATION_MS "curl"
            exit 1
        fi
        
        printf "\r\033[K"
        chmod +x "$TMP_DIR/muxi"
        if [ "$DRY_RUN" = "0" ]; then
            mv "$TMP_DIR/muxi" "$INSTALL_DIR/muxi"
        fi
        echo -e "${CHECK} Downloaded MUXI CLI ${CLI_VERSION}"
    fi
fi

# Calculate duration
END_TIME=$(date +%s)
DURATION_MS=$(( (END_TIME - START_TIME) * 1000 ))

echo ""
echo -e "${CHECK} Installation complete!"
echo ""

# Send telemetry
send_telemetry true $DURATION_MS "curl"

# ============================================================
# PATH MANAGEMENT
# ============================================================
PATH_UPDATED=0
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    SHELL_NAME=$(basename "$SHELL")
    case "$SHELL_NAME" in
        bash)
            if [ "$OS" = "darwin" ]; then
                SHELL_CONFIG="$HOME/.bash_profile"
            else
                SHELL_CONFIG="$HOME/.bashrc"
            fi
            ;;
        zsh)  SHELL_CONFIG="$HOME/.zshrc" ;;
        fish) SHELL_CONFIG="$HOME/.config/fish/config.fish" ;;
        *)    SHELL_CONFIG="" ;;
    esac
    
    if [ -n "$SHELL_CONFIG" ]; then
        echo "" >> "$SHELL_CONFIG"
        echo "# Added by MUXI installer" >> "$SHELL_CONFIG"
        if [ "$SHELL_NAME" = "fish" ]; then
            echo "set -gx PATH $INSTALL_DIR \$PATH" >> "$SHELL_CONFIG"
        else
            echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_CONFIG"
        fi
        PATH_UPDATED=1
    fi
fi

# ============================================================
# EMAIL OPTIN (interactive only)
# ============================================================
if [ "$NON_INTERACTIVE" = "0" ]; then
    echo "$LINE"
    echo -e "${ARROW} STAY IN THE LOOP"
    echo "$LINE"
    echo "Get security alerts, release notes, and early access to new features."
    echo "(low volume, unsubscribe anytime)"
    echo ""
    read -ep "Email [Enter to skip]: " USER_EMAIL
    
    # Replace prompt line with clean output
    printf "\033[1A\033[K"  # Move up and clear line
    if [ -n "$USER_EMAIL" ]; then
        echo "Email: $USER_EMAIL"
        echo ""
        send_optin "$USER_EMAIL"
        write_config "email_optin" "true"
        echo -e "${CHECK} Subscribed! Check your inbox for a welcome email."
    else
        echo "Email: Skipped"
    fi
    echo "$LINE"
    echo ""
fi

# ============================================================
# QUICKSTART VIDEO PROMPT (headed machines only)
# ============================================================
if [ "$NON_INTERACTIVE" = "0" ] && ! is_headless; then
    if [ "$INSTALL_SERVER" = "1" ]; then
        echo -e "${ARROW} Watch how to set up your server and deploy your"
        echo "  first AI agent in under 2 minutes!"
        MODE="all"
    else
        echo -e "${ARROW} Watch how to configure the CLI and deploy your"
        echo "  first AI agent in under 2 minutes!"
        MODE="cli"
    fi
    echo ""
    read -p "  Show the guide? [Y/n]: " OPEN_VIDEO
    if [ -z "$OPEN_VIDEO" ] || [ "$OPEN_VIDEO" = "y" ] || [ "$OPEN_VIDEO" = "Y" ]; then
        URL="https://muxi.org/post-install?mode=${MODE}&ic=${MACHINE_ID}"
        case "$OS" in
            darwin) open "$URL" ;;
            linux) xdg-open "$URL" 2>/dev/null || echo "  Open: $URL" ;;
        esac
    fi
    echo ""
fi

# ============================================================
# NEXT STEPS
# ============================================================
echo "Thank you for installing MUXI!"
echo ""
echo "Next steps:"
echo ""
if [ "$INSTALL_SERVER" = "1" ]; then
    echo "  1. Initialize the server:"
    echo -e "     ${CYAN}muxi-server init${NC}"
    echo ""
    echo "  2. Start the server:"
    echo -e "     ${CYAN}muxi-server start${NC}"
    echo ""
else
    echo "  1. Connect to a server:"
    echo -e "     ${CYAN}muxi profiles add${NC}"
    echo ""
    echo "  2. Create a formation:"
    echo -e "     ${CYAN}muxi new formation${NC}"
    echo ""
    echo "You can also start with a demo formation:"
    echo -e "  ${CYAN}muxi pull @muxi/quickstart${NC}"
    echo ""
fi

if [ "$PATH_UPDATED" = "1" ]; then
    echo -e "${YELLOW}Note:${NC} Open a new terminal or run ${CYAN}source $SHELL_CONFIG${NC}"
    echo ""
fi

echo "Docs: https://muxi.org/docs"
echo ""
