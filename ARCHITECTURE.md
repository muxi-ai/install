# MUXI Installation Architecture

Design decisions for installation methods and CLI/Server integration.

---

## Repository Purpose

This repository hosts installation scripts for MUXI tools:
- `install.sh` - Unix/Linux/macOS installation
- `install.ps1` - Windows PowerShell installation

**Hosted at:** `install.muxi.org` (serves scripts directly)

**Decoupled from code repositories** to allow independent evolution of installation methods.

**Key Innovation:** Single installer with component selection - users choose what to install instead of navigating multiple repos.

---

## Installation Methods

### 1. Unified Install Script (Primary Method)

**Linux / macOS:**
```bash
# Interactive - prompts for component selection
curl -sSL https://install.muxi.org | sudo bash

# Non-interactive - CLI only (default for automation)
curl -sSL https://install.muxi.org | bash -s -- --non-interactive

# Non-interactive - specific components
curl -sSL https://install.muxi.org | bash -s -- --non-interactive --components=server,cli
curl -sSL https://install.muxi.org | bash -s -- --non-interactive --components=cli
curl -sSL https://install.muxi.org | bash -s -- --non-interactive --components=server
```

**Windows:**
```powershell
irm https://install.muxi.org/windows.ps1 | iex
```

**Component Options:**
1. **Server + CLI** (Interactive default)
   - Full local development setup
   - Server binary: `muxi-server`
   - CLI binary: `muxi`
   - Best for: Local development, learning, testing

2. **CLI only** (Non-interactive default)
   - Lightweight client for remote server management
   - CLI binary: `muxi`
   - Best for: Managing remote production servers

3. **Server only**
   - Production-optimized server installation
   - Server binary: `muxi-server`
   - Best for: Production deployments, headless servers

**Philosophy:** One installer, flexible deployment - users explicitly choose their use case.

---

### 2. Homebrew (Package Manager)

**macOS/Linux package manager alternative for advanced users:**

```bash
# CLI only (when available)
brew install muxi-ai/tap/muxi-cli

# Server only (currently available)
brew install muxi-ai/tap/muxi-server

# Both components (when available)
brew install muxi-ai/tap/muxi
```

**Structure:**
```
Formula/
├── muxi-cli.rb       # CLI only (lightweight, for remote management) - COMING SOON
├── muxi-server.rb    # Server only (production deployments) - AVAILABLE NOW
└── muxi.rb           # Meta-package (depends on both) - COMING SOON
```

> **Note:** Currently only `muxi-server.rb` exists. Once CLI is built, we'll create:
> - `muxi-cli.rb` - Standalone CLI formula
> - `muxi.rb` - Unified meta-package that depends on both server and CLI

**Philosophy:** Package manager control - separate components for granular dependency management.

**Repository:** [github.com/muxi-ai/homebrew-tap](https://github.com/muxi-ai/homebrew-tap) (separate from install scripts - follows Homebrew convention)

---

### Installation Method Comparison

| Method | Best For | Pros | Cons |
|--------|----------|------|------|
| **Unified Installer** | Most users, quick start | • One command<br>• Component selection<br>• Works everywhere | • Requires curl<br>• Manual updates |
| **Homebrew** | macOS/Linux power users | • Package management<br>• Auto-updates<br>• Dependency tracking | • macOS/Linux only<br>• Requires Homebrew |

**Recommendation:** Use the unified installer (`install.muxi.org`) unless you specifically need Homebrew's package management features.

---

## CLI/Server Integration

### Automatic Local Server Detection

When CLI runs for the first time, it detects local server installation:

```go
// Detection strategy (in order of confidence)
func DetectLocalServer() *ServerInfo {
    // 1. Check if binary exists in PATH
    binaryPath, _ := exec.LookPath("muxi-server")
    
    // 2. Check for config directory
    configPath := "~/.muxi/server/config.yaml"
    configExists := fileExists(configPath)
    
    // 3. Check for credentials
    credsPath := "~/.muxi/server/credentials.json"
    credsExist := fileExists(credsPath)
    
    // 4. Try to connect (if running)
    resp, _ := http.Get("http://localhost:7890/health")
    running := (resp != nil && resp.StatusCode == 200)
    
    return &ServerInfo{
        Installed:   binaryPath != "",
        ConfigPath:  configPath,
        CredsPath:   credsPath,
        Running:     running,
        Port:        7890,  // Read from config if exists
    }
}
```

### First-Run Scenarios

**Scenario 1: Server installed AND running**
```bash
$ muxi formation list

→ Detected local MUXI Server on port 7890
→ Add as default profile? [Y/n]: y

✓ Added profile 'localhost' as default
✓ Connected to http://localhost:7890

Formations:
  (empty)
```

**Scenario 2: Server installed but NOT running**
```bash
$ muxi formation list

→ Detected local MUXI Server (not running)
→ Start server and add as default profile? [Y/n]: y

✓ Starting server...
✓ Server started on port 7890
✓ Added profile 'localhost' as default

Formations:
  (empty)
```

**Scenario 3: Server NOT installed**
```bash
$ muxi formation list

→ No profiles configured.
→ Install MUXI Server locally? [Y/n]: y

✓ Installing MUXI Server...
  curl -sSL https://install.muxi.org | bash
✓ Installed successfully
✓ Initializing server...
✓ Added profile 'localhost' as default

Ready to deploy formations!
```

**Scenario 4: Has existing profiles**
```bash
$ muxi formation list

Using profile: production (http://prod.company.com:7890)

Formations:
  - customer-support
  - sales-assistant
```

### Manual Profile Management

```bash
# Add server manually
muxi server add localhost --url http://localhost:7890 --default

# Add remote server
muxi server add production --url https://muxi.company.com:7890

# Switch default
muxi server set-default production

# List servers
muxi server list
```

---

## Config File Structure

**Location:** `~/.muxi/profiles.yaml`

```yaml
profiles:
  localhost:
    url: http://localhost:7890
    auth:
      key_id: "auto-detected"
      secret_key: "auto-detected"  # Read from ~/.muxi/server/credentials.json
    default: true
    
  production:
    url: https://muxi.company.com:7890
    auth:
      key_id: "MUXI_PROD_KEY"
      secret_key: "MUXI_PROD_SECRET"
    default: false
```

**Auto-detection for localhost:**
- Reads `~/.muxi/server/credentials.json` automatically
- No need to copy/paste credentials
- Updates if credentials regenerated

---

## Detection Without Running Server

**YES! Multiple detection methods:**

### Method 1: Check Binary
```go
if _, err := exec.LookPath("muxi-server"); err == nil {
    // Server binary is installed
}
```

### Method 2: Check Config Directory
```go
homeDir, _ := os.UserHomeDir()
configPaths := []string{
    filepath.Join(homeDir, ".muxi/server"),          // User install
    "/etc/muxi/server",                              // System install (Linux)
    "/Library/Application Support/muxi/server",      // System install (macOS)
}

for _, path := range configPaths {
    if stat, err := os.Stat(path); err == nil && stat.IsDir() {
        // Server config directory exists
        return true
    }
}
```

### Method 3: Check Credentials File
```go
credsPaths := []string{
    filepath.Join(homeDir, ".muxi/server/credentials.json"),
    "/etc/muxi/server/credentials.json",
}

for _, path := range credsPaths {
    if _, err := os.Stat(path); err == nil {
        // Server credentials exist = server was initialized
        return true
    }
}
```

### Method 4: Check for Registry File (Most Reliable)
```go
registryPaths := []string{
    filepath.Join(homeDir, ".muxi/server/registry.json"),
    "/var/lib/muxi/server/registry.json",
}

for _, path := range registryPaths {
    if _, err := os.Stat(path); err == nil {
        // Registry exists = server has been started at least once
        return true
    }
}
```

### Confidence Levels

| Artifact | Means | Confidence |
|----------|-------|------------|
| Binary exists | Installed | 🟢 High |
| Config exists | Initialized | 🟢 High |
| Credentials exist | Initialized + has auth | 🟢 Very High |
| Registry exists | Has been run | 🟢 Very High |
| Port 7890 responds | Currently running | 🟡 Medium (could be different server) |

**Best approach:** Check for **credentials.json** - this means:
- ✅ Server is installed
- ✅ Server was initialized (`muxi-server init` ran)
- ✅ We can read the credentials to auto-populate CLI profile

---

## Implementation Flow

```go
func (cli *CLI) EnsureProfile() error {
    // Check if profiles.yaml exists
    if cli.ProfilesExist() {
        return nil  // Already configured
    }
    
    // Try to detect local server
    server := DetectLocalServer()
    
    if !server.Installed {
        // Scenario 3: Nothing installed
        return cli.PromptInstallServer()
    }
    
    if !server.HasCredentials {
        // Server installed but not initialized
        fmt.Println("→ Local server detected but not initialized")
        fmt.Print("  Run 'muxi-server init' now? [Y/n]: ")
        // ...
        return nil
    }
    
    // Server is installed AND initialized
    creds, _ := ReadCredentials(server.CredentialsPath)
    
    if server.Running {
        // Scenario 1: Running
        fmt.Printf("→ Detected local MUXI Server on port %d\n", server.Port)
    } else {
        // Scenario 2: Not running
        fmt.Printf("→ Detected local MUXI Server (not running)\n")
        fmt.Print("  Start server now? [Y/n]: ")
        // ...
    }
    
    fmt.Print("  Add as default profile? [Y/n]: ")
    // Auto-populate with detected credentials
    
    return nil
}
```

---

## Summary

**YES - We can detect server even if not running!**

**Detection hierarchy:**
1. ✅ Binary in PATH → "Server installed"
2. ✅ Config exists → "Server initialized"  
3. ✅ Credentials exist → **"Server ready"** (best signal!)
4. ✅ Registry exists → "Server has run before"
5. ⚠️ Port responds → "Server currently running" (bonus)

**First-run flow:**
- Detect installation artifacts (files, not processes)
- Offer to configure automatically
- Read credentials from server config (no copy/paste!)
- Offer to start server if not running

**This is super user-friendly** - CLI becomes self-configuring for local development! 🎯
