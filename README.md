# MUXI Installation Scripts

Official installation scripts for MUXI tools.

**Hosted at:** `install.muxi.org`

---

## Usage

### Linux / macOS

```bash
# Interactive (prompts for email, offers to configure)
curl -sSL https://install.muxi.org | sudo bash

# Non-interactive (CI/Docker)
curl -sSL https://install.muxi.org | sudo bash -s -- --non-interactive

# With email (no prompt)
curl -sSL https://install.muxi.org | sudo bash -s -- --email=dev@company.com

# With email + auto-configure
curl -sSL https://install.muxi.org | sudo bash -s -- --email=dev@company.com --configure
```

### Windows

```powershell
# Interactive
irm https://install.muxi.org/windows.ps1 | iex

# Non-interactive
irm https://install.muxi.org/windows.ps1 | iex -NonInteractive

# With parameters
irm https://install.muxi.org/windows.ps1 | iex -Email "dev@company.com" -Configure
```

---

## What It Installs

**MUXI Server** (production-grade agent orchestration)
- Binary: `muxi-server`
- Config directory: `~/.muxi/server/`
- Credentials: Auto-generated on init

**MUXI CLI** (future)
- Binary: `muxi`
- Config directory: `~/.muxi/`
- Auto-detects local server

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

✓ Downloading MUXI Server v0.20251024.3...
✓ Installed to /usr/local/bin/muxi-server

→ Join the MUXI community? (optional)
  Get early access to features, workshops, and exclusive content!
  
  Email [press Enter to skip]: _

→ Configure server now? [Y/n]: _
```

### Non-Interactive Mode (Auto-Detected)

```
Downloading MUXI Server v0.20251024.3...
✓ Installed to /usr/local/bin/muxi-server
✓ Installation complete

Start server:
  muxi-server init
  muxi-server start
```

---

## Features

- **Auto-detection:** Detects if running in CI/Docker (non-interactive)
- **Optional email:** Community building, easily skippable
- **Auto-configure:** Offers to run `muxi-server init` after install
- **Arguments:** Override auto-detection with flags
- **Safe:** All prompts are optional, never blocks automation

---

## Development

This repository hosts only the installation scripts. The actual MUXI tools are in:
- Server: [github.com/muxi-ai/server](https://github.com/muxi-ai/server)
- CLI: [github.com/muxi-ai/cli](https://github.com/muxi-ai/cli) (future)
- Homebrew: [github.com/muxi-ai/homebrew-tap](https://github.com/muxi-ai/homebrew-tap)

---

## Hosting

**Production:** `install.muxi.org`
- Serves `install.sh` at `/` or `/install.sh`
- Serves `install.ps1` at `/windows.ps1`
- Can be hosted on GitHub Pages, Cloudflare Workers, or Vercel

**Testing locally:**
```bash
# Serve with Python
python3 -m http.server 8080

# Test
curl -sSL http://localhost:8080/install.sh | bash
```

---

## License

MIT License - see main MUXI Server [LICENSE](https://github.com/muxi-ai/server/blob/main/LICENSE)
