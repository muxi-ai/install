# AGENTS.md -- AI Agent Development Guide

**Project:** MUXI Installer
**Language:** Bash (install.sh), PowerShell (install.ps1)
**License:** Apache-2.0

## What This Is

Installation scripts for MUXI Server and CLI. Downloads pre-built binaries from GitHub Releases and installs them to the user's system.

This repo is part of the [MUXI ecosystem](https://github.com/muxi-ai/muxi/blob/main/ARCHITECTURE.md).

## Repository Structure

```
.
├── install.sh         # Unix/macOS/Linux installer
├── install.ps1        # Windows PowerShell installer
├── .version           # ScalVer version file
├── DESIGN.md          # Installer internals and design decisions
├── README.md          # Public README
├── LICENSE            # Apache-2.0
└── .github/workflows/
    ├── ci.yml         # Lint and test
    ├── rc.yml         # Release candidate
    └── release.yml    # Auto-release on main push
```

## How It Works

1. Detect platform (OS + architecture)
2. Interactive component selection (Server + CLI or CLI only)
3. Resolve latest version via GitHub Releases redirect
4. Download binaries to temp directory
5. Move to install location (`~/.local/bin` or `/usr/local/bin`)
6. Configure PATH in shell rc file
7. Fire-and-forget telemetry ping
8. Optional email opt-in prompt

## Key Design Decisions

- Single script, no dependencies beyond `curl` and `bash`
- Version detection via HTTP HEAD redirect (no GitHub API calls)
- Interactive UI with arrow keys and radio buttons (PTY-aware)
- Non-interactive mode for CI/scripts (`--non-interactive`)
- See [DESIGN.md](DESIGN.md) for full details

## Testing

```bash
bash install.sh --dry-run                    # Download only, don't install
bash install.sh --non-interactive --dry-run  # Non-interactive dry run
bash install.sh --cli-only --dry-run         # CLI-only dry run
```

## Git Workflow

- `develop` -- Active development
- `rc` -- Release candidate
- `main` -- Production (auto-tagged, auto-released)

Commit style: `feat:`, `fix:`, `chore:`, `docs:`
