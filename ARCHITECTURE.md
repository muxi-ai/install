# MUXI Installation Architecture

Design decisions for installation methods and CLI/Server integration.

---

## Repository Purpose

This repository hosts installation scripts for MUXI tools:
- `install.sh` - Unix/Linux/macOS installation
- `install.ps1` - Windows PowerShell installation

**Hosted at:** `muxi.org/install` (serves scripts directly)

**Decoupled from code repositories** to allow independent evolution of installation methods.

**Key Innovation:** Single installer with component selection - users choose what to install instead of navigating multiple repos.

---

## Installation Methods

### 1. Unified Install Script (Primary Method)

**Linux / macOS:**
```bash
# Interactive - prompts for component selection
curl -fsSL https://muxi.org/install | bash

# With sudo for production (/usr/local/bin)
curl -fsSL https://muxi.org/install | sudo bash

# Non-interactive - Server + CLI (default)
curl -fsSL https://muxi.org/install | bash -s -- --non-interactive

# CLI only
curl -fsSL https://muxi.org/install | bash -s -- --cli-only
```

**Windows:**
```powershell
irm https://muxi.org/install | iex
```

**Component Options:**
1. **Server + CLI** (default)
   - Full local development setup
   - Server binary: `muxi-server`
   - CLI binary: `muxi`
   - Best for: Local development, learning, testing

2. **CLI only** (`--cli-only` flag)
   - Lightweight client for remote server management
   - CLI binary: `muxi`
   - Best for: Managing remote production servers

**Philosophy:** One installer, flexible deployment - users explicitly choose their use case.

---

### 2. Homebrew (Package Manager)

**macOS/Linux package manager alternative for advanced users:**

```bash
brew install muxi-ai/tap/muxi
```

**Structure:**
```
Formula/
└── muxi.rb
```

> - `muxi.rb` - Unified meta-package that depends on both server and CLI

**Philosophy:** Package manager control - separate components for granular dependency management.

**Repository:** [github.com/muxi-ai/homebrew-tap](https://github.com/muxi-ai/homebrew-tap) (separate from install scripts - follows Homebrew convention)

---

### Installation Method Comparison

| Method | Best For | Pros | Cons |
|--------|----------|------|------|
| **Unified Installer** | Most users, quick start | • One command<br>• Component selection<br>• Works everywhere | • Requires curl<br>• Manual updates |
| **Homebrew** | macOS/Linux power users | • Package management<br>• Auto-updates<br>• Dependency tracking | • macOS/Linux only<br>• Requires Homebrew |

**Recommendation:** Use the unified installer (`muxi.org/install`) unless you specifically need Homebrew's package management features.
