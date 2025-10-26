# MUXI Installation Scripts

Official installation scripts for MUXI tools.

**Hosted at:** `install.muxi.org`

---

## Usage

### Linux / macOS

```bash
# Interactive (prompts for email and component selection)
curl -sSL https://install.muxi.org | sudo bash

# Non-interactive - installs CLI only by default
curl -sSL https://install.muxi.org | sudo bash -s -- --non-interactive

# Non-interactive - install specific components
curl -sSL https://install.muxi.org | sudo bash -s -- --non-interactive --components=server,cli
curl -sSL https://install.muxi.org | sudo bash -s -- --non-interactive --components=cli
curl -sSL https://install.muxi.org | sudo bash -s -- --non-interactive --components=server
```

### Windows

```powershell
# Interactive
irm https://install.muxi.org/windows.ps1 | iex

# Non-interactive
irm https://install.muxi.org/windows.ps1 | iex -NonInteractive
```

---

## What It Installs

**MUXI Server** (production-grade agent orchestration)
- Binary: `muxi-server`
- Config directory: `~/.muxi/server/`
- Credentials: Auto-generated on init
- Install when: Running formations locally or on production servers

**MUXI CLI** (coming soon)
- Binary: `muxi`
- Config directory: `~/.muxi/`
- Auto-detects local server
- Install when: Managing remote servers or local development

---

## Installation Flow

### Interactive Mode

```
 ███╗   ███╗██╗   ██╗██╗  ██╗██╗
 ████╗ ████║██║   ██║╚██╗██╔╝██║
 ██╔████╔██║██║   ██║ ╚███╔╝ ██║
 ██║╚██╔╝██║██║   ██║ ██╔██╗ ██║
 ██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗██║
 ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝

MUXI Installation

→ Join the MUXI community? (optional)
  Get early access to features, workshops, and exclusive content!
  
  Email [press Enter to skip]: user@example.com

✓ Thanks for joining!

→ What would you like to install?
  [1] Server + CLI (recommended for local development)
  [2] CLI only (for managing remote servers)
  [3] Server only (for production deployments)
  
  Choice [1]: 1

→ Installing: Server + CLI

 ███╗   ███╗██╗   ██╗██╗  ██╗██╗
 ████╗ ████║██║   ██║╚██╗██╔╝██║
 ██╔████╔██║██║   ██║ ╚███╔╝ ██║
 ██║╚██╔╝██║██║   ██║ ██╔██╗ ██║
 ██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗██║
 ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝

MUXI Installation

→ Platform: darwin/arm64
→ Components: Server + CLI
→ Server binary: /usr/local/bin/muxi-server
→ Server paths:  ~/.muxi/server/
→ CLI binary: /usr/local/bin/muxi
→ CLI config: ~/.muxi/

→ Downloading MUXI Server from GitHub...
✓ Installed MUXI Server: v0.20251024.3
! MUXI CLI is not yet available

  The CLI is coming soon! For now, you can:
  • Manage the server directly with muxi-server commands
  • Use the REST API
  • Check https://github.com/muxi-ai/cli for updates

────────────────────────────────────────────────────────────
✓ Installation complete!
────────────────────────────────────────────────────────────

→ Configure server now? [Y/n]: y

→ Initializing MUXI Server...

✓ Server ready!

Start server:
  muxi-server start

Connect CLI to server:
  muxi profile add localhost http://localhost:7890
```

### Non-Interactive Mode (Default: CLI only)

```bash
curl -sSL https://install.muxi.org | bash -s -- --non-interactive
```

```
! MUXI CLI is not yet available

  The CLI is coming soon! For now, you can:
  • Manage the server directly with muxi-server commands
  • Use the REST API
  • Check https://github.com/muxi-ai/cli for updates

────────────────────────────────────────────────────────────
✓ Installation complete!
────────────────────────────────────────────────────────────
```

### Non-Interactive Mode (Server Only)

```bash
curl -sSL https://install.muxi.org | bash -s -- --non-interactive --components=server
```

```
✓ Installed MUXI Server: v0.20251024.3

────────────────────────────────────────────────────────────
✓ Installation complete!
────────────────────────────────────────────────────────────

Next steps:

  1. Initialize the server:
     muxi-server init

  2. Start the server:
     muxi-server start
```

---

## Features

- **Component selection:** Choose what to install (Server, CLI, or both)
- **Smart defaults:** Interactive mode defaults to "Server + CLI", non-interactive defaults to "CLI only"
- **Auto-detection:** Automatically detects CI/Docker environments (non-interactive mode)
- **Optional email:** Community building, easily skippable
- **Auto-configure:** Offers to run `muxi-server init` after install
- **Flexible:** Specify components with `--components=server,cli` flag
- **Safe:** All prompts are optional, never blocks automation
- **Future-proof:** Gracefully handles CLI not being available yet

---

## Use Cases

### For Local Development
```bash
curl -sSL https://install.muxi.org | bash
# Choose option 1: Server + CLI
```
Get both server and CLI for full local development experience.

### For Remote Server Management
```bash
curl -sSL https://install.muxi.org | bash -s -- --non-interactive
```
Installs CLI only by default - lightweight and ready to manage remote servers.

### For Production Servers
```bash
curl -sSL https://install.muxi.org | bash -s -- --non-interactive --components=server
```
Server-only installation - no CLI overhead, optimized for production.

---

## Development

This repository hosts only the installation scripts. The actual MUXI tools are in:
- Server: [github.com/muxi-ai/server](https://github.com/muxi-ai/server)
- CLI: [github.com/muxi-ai/cli](https://github.com/muxi-ai/cli) (coming soon)
- Homebrew: [github.com/muxi-ai/homebrew-tap](https://github.com/muxi-ai/homebrew-tap)

---

## Hosting

**Production:** `install.muxi.org`

The installer supports **automatic client detection** - one URL works for all platforms:

```bash
# Linux/macOS (serves install.sh)
curl -sSL install.muxi.org | bash

# Windows (serves install.ps1)
irm install.muxi.org | iex

# Browser (redirects to docs)
# Visit https://install.muxi.org in your browser → redirects to muxi.org/docs/install
```

**How it works:** Detects client via `User-Agent` header and serves the appropriate script.

**Hosting options:**
- ✅ **Cloudflare Workers** (recommended) - Edge computing, free, instant
- ✅ **Vercel Serverless** - Simple deployment, GitHub integration
- ✅ **PHP** - Traditional hosting, works everywhere
- ✅ **Apache .htaccess** - Static hosting, no server-side code

See [HOSTING.md](HOSTING.md) for detailed setup instructions.

**Testing locally:**
```bash
# Option 1: PHP built-in server (with detection)
php -S localhost:8080

# Option 2: Python (static files only)
python3 -m http.server 8080

# Test
curl -sSL http://localhost:8080 | bash
```

---

## License

MIT License - see main MUXI Server [LICENSE](https://github.com/muxi-ai/server/blob/main/LICENSE)
