# MUXI Installer

Official installation scripts for [MUXI](https://github.com/muxi-ai/muxi) -- open-source infrastructure for running AI agents in production.

> [!IMPORTANT]
> ## MUXI Ecosystem
>
> This repository is part of the larger MUXI ecosystem.
>
> **📋 Complete architectural overview:** See [muxi/ARCHITECTURE.md](https://github.com/muxi-ai/muxi/blob/main/ARCHITECTURE.md) - explains how all 9 repositories fit together, dependencies, status, and roadmap.


## Install

```bash
# macOS (Homebrew)
brew install muxi-ai/tap/muxi

# macOS / Linux
curl -fsSL https://muxi.org/install | bash

# Linux (system-wide)
curl -fsSL https://muxi.org/install | sudo bash

# Windows (PowerShell)
irm https://muxi.org/install | iex
```

### Options

| Flag | Description |
|------|-------------|
| `--non-interactive` | Skip prompts, use defaults |
| `--cli-only` | Install CLI only (no server) |
| `--dry-run` | Download but don't install |

## What Gets Installed

| Binary | Description |
|--------|-------------|
| `muxi-server` | Orchestration server for AI agent formations |
| `muxi` | CLI for managing formations and deployments |

## Next Steps

```bash
muxi-server init    # Generate credentials
muxi-server start   # Start the server
```

## Documentation

- [muxi.org/docs/installation](https://muxi.org/docs/installation) -- Full installation guide
- [muxi.org/docs/quickstart](https://muxi.org/docs/quickstart) -- Getting started
- [DESIGN.md](DESIGN.md) -- Installer internals and design decisions

## Related

- [muxi-ai/server](https://github.com/muxi-ai/server) -- MUXI Server
- [muxi-ai/cli](https://github.com/muxi-ai/cli) -- MUXI CLI
- [muxi-ai/homebrew-tap](https://github.com/muxi-ai/homebrew-tap) -- Homebrew formula

## License

Apache-2.0
