# MUXI Installer Documentation

## Overview

Single-script installer that downloads and installs MUXI Server and/or CLI from GitHub releases.

```bash
curl -fsSL https://muxi.org/install | bash
```

## UI Flow

```
 ███╗   ███╗██╗   ██╗██╗  ██╗██╗
 ████╗ ████║██║   ██║╚██╗██╔╝██║
 ██╔████╔██║██║   ██║ ╚███╔╝ ██║
 ██║╚██╔╝██║██║   ██║ ██╔██╗ ██║
 ██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗██║
 ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝
Welcome to MUXI installer!

→ What would you like to install?
  ◉ Server + CLI (recommended)
  ○ CLI only

→ Platform: darwin/arm64
→ Installing: Server + CLI

⠋ Downloading MUXI Server...
✓ Downloaded MUXI Server v0.20251205.1

⠋ Downloading MUXI CLI...
✓ Downloaded MUXI CLI v0.1.0

✓ Installation complete!

────────────────────────────────────────────────────────────
→ STAY IN THE LOOP
────────────────────────────────────────────────────────────
Get security alerts, release notes, and early access to new features.
(low volume, unsubscribe anytime)

Email [Enter to skip]: user@example.com

Email: user@example.com

✓ Subscribed! Check your inbox for a welcome email.
────────────────────────────────────────────────────────────

Next steps:
  1. Initialize the server:
     muxi-server init
  2. Start the server:
     muxi-server start
```

## Design Decisions

### 1. Banner & Branding

- **Gold color `#c98b45`** - Matches CLI brand color (RGB 201, 139, 69)
- **ASCII art banner** - Displays in interactive mode only
- **"Welcome to MUXI installer!"** - Friendly greeting after banner

### 2. Component Selection (Interactive Mode)

- **Radio button UI** with filled (◉) and empty (○) circles
- **Gold highlight** for selected option
- **Arrow keys** (↑/↓) to toggle selection
- **Number keys** (1/2) for direct selection
- **Enter** to confirm
- **Default**: Server + CLI (recommended)

### 3. Version Detection

- **No extra API call** - Uses GitHub redirect from `/releases/latest`
- HEAD request to `https://github.com/muxi-ai/server/releases/latest`
- Extracts version from `Location` header (e.g., `/tag/v0.20251205.1`)
- Constructs direct download URL with version

### 4. Download Progress

- **Spinner character** (⠋) shown during download
- **Line replacement** - Clears spinner and shows checkmark on completion
- `✓ Downloaded MUXI Server v0.20251205.1`

### 5. Installation Paths

| Platform | Install Directory |
|----------|------------------|
| macOS    | `~/.local/bin`   |
| Linux    | `~/.local/bin`   |
| Windows  | TBD              |

Config directory: `~/.muxi/`

### 6. Telemetry

**Endpoint**: `https://capture.muxi.org/v1/telemetry/`

**Payload**:
```json
{
  "module": "install",
  "machine_id": "uuid-from-~/.muxi/machine_id",
  "ts": "2025-12-31T16:00:00Z",
  "country": "US",
  "payload": {
    "version": "0.1.0",
    "install_method": "curl",
    "os": "darwin",
    "arch": "arm64",
    "server": true,
    "cli": true,
    "success": true,
    "duration_ms": 1500
  }
}
```

**Decisions**:
- **Async fire-and-forget** - Subshell `(curl ... &)` survives script exit
- **Trailing slash** on URL to avoid 308 redirect
- **UTC timestamps** for consistent server-side partitioning
- **Deterministic Machine ID** - Derived from OS hardware ID (see [MACHINE-ID.md](../telemetry/docs/MACHINE-ID.md))
- **Geo lookup** via ip-api.com (ipapi.co blocked by Cloudflare)
- **24-hour geo cache** in `~/.muxi/geo.json`
- **Opt-out** via `MUXI_TELEMETRY=0` env var or `telemetry: false` in config

### 7. Email Opt-in

**Endpoint**: `https://capture.muxi.org/v1/optin/`

**Payload**:
```json
{
  "email": "user@example.com",
  "machine_id": "uuid"
}
```

**UI Flow**:
- Prompt: `Email [Enter to skip]: `
- After input, line is replaced with `Email: user@example.com` or `Email: Skipped`
- Success message: `✓ Subscribed! Check your inbox for a welcome email.`
- Writes `email_optin: true` to `~/.muxi/config.yaml`

### 8. PATH Management

- Detects shell type (bash, zsh, fish)
- Appends to appropriate config file:
  - bash: `~/.bash_profile` (macOS) or `~/.bashrc` (Linux)
  - zsh: `~/.zshrc`
  - fish: `~/.config/fish/config.fish`

### 9. Command-Line Flags

| Flag | Description |
|------|-------------|
| `--non-interactive` | Skip prompts, use defaults |
| `--cli-only` | Install CLI only (no server) |
| `--dry-run` | Download but don't move to install dir (testing) |

### 10. Error Handling

- Checks for `curl` availability
- Validates platform support (darwin, linux)
- Validates architecture (amd64, arm64)
- Reports download failures with telemetry
- Cleans up temp directory on exit (`trap`)

### 11. Non-Interactive Mode

Triggered by:
- `--non-interactive` flag
- Piped input (stdin not a terminal)

Behavior:
- Skips banner and welcome message
- Skips component selection (uses default: Server + CLI)
- Skips email opt-in prompt

## File Structure

```
~/.muxi/
├── config.yaml     # Main config (machine_id, telemetry, email_optin)
├── geo.json        # Cached geo data (24h TTL)
└── cli/
    └── profiles.yaml   # CLI server profiles (created by muxi-server init)

~/.local/bin/
├── muxi-server     # Server binary
└── muxi            # CLI binary
```

### config.yaml

Created on first install:
```yaml
machine_id: 90bbde51-ef4e-41c9-8ec2-8e270bbbec66
telemetry: true
email_optin: true  # Added if user subscribes
```

### cli/profiles.yaml

Created by `muxi-server init` when CLI is detected:
```yaml
version: "1.0"
default: localhost
profiles:
    localhost:
        url: http://localhost:7890
        key_id: muxi_pk_...
        secret_key: muxi_sk_...
        added_at: 2025-12-31T12:00:00Z
```

## Testing

```bash
# Test downloads without installing
bash install.sh --dry-run

# Test non-interactive mode
bash install.sh --non-interactive --dry-run

# Test CLI-only installation
bash install.sh --cli-only --dry-run
```
