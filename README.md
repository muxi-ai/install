# MUXI Installer

Official installation scripts for MUXI Server and CLI.

## Quick Install

### macOS (Homebrew)

```bash
brew install muxi-ai/tap/muxi
```

### macOS / Linux

```bash
curl -fsSL https://muxi.org/install | bash
```

### Linux (Production)

```bash
curl -fsSL https://muxi.org/install | sudo bash
```

### Windows

```powershell
irm https://muxi.org/install | iex
```

## What Gets Installed

| Binary | Description |
|--------|-------------|
| `muxi-server` | Production infrastructure for running AI agents |
| `muxi` | CLI for managing formations and deployments |

### Install Locations

| Method | Binaries | Config |
|--------|----------|--------|
| Homebrew | `/opt/homebrew/bin` | `~/.muxi/` |
| curl (user) | `~/.local/bin` | `~/.muxi/` |
| curl (sudo) | `/usr/local/bin` | `/etc/muxi/` |
| Windows | `%LOCALAPPDATA%\MUXI\bin` | `%USERPROFILE%\.muxi\` |

## Installation Options

### Flags

| Flag | Description |
|------|-------------|
| `--non-interactive` | Skip prompts, use defaults |
| `--cli-only` | Install CLI only (no server) |
| `--dry-run` | Download but don't install (testing) |

### Examples

```bash
# Interactive install (default: Server + CLI)
curl -fsSL https://muxi.org/install | bash

# Non-interactive (for scripts/CI)
curl -fsSL https://muxi.org/install | bash -s -- --non-interactive

# CLI only
curl -fsSL https://muxi.org/install | bash -s -- --cli-only
```

## After Installation

### Server + CLI

```bash
# Initialize the server
muxi-server init

# Start the server
muxi-server start
```

### CLI Only

```bash
# Connect to a server
muxi profiles add

# Create a formation
muxi new formation

# Or start with a demo
muxi pull @muxi/quickstart
```

## Telemetry

The installer collects anonymous usage data to help improve MUXI:
- OS and architecture
- Install success/failure
- Duration

**No personal data is collected.** Opt-out:

```bash
MUXI_TELEMETRY=0 curl -fsSL https://muxi.org/install | bash
```

Or set `telemetry: false` in `~/.muxi/config.yaml`.

## Documentation

- [INSTALLER.md](INSTALLER.md) - Detailed design decisions
- [muxi.org/docs](https://muxi.org/docs) - Full documentation

## Related Repositories

- [muxi-ai/server](https://github.com/muxi-ai/server) - MUXI Server
- [muxi-ai/cli](https://github.com/muxi-ai/cli) - MUXI CLI
- [muxi-ai/homebrew-tap](https://github.com/muxi-ai/homebrew-tap) - Homebrew formulae

## License

Apache-2.0
