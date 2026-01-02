# MUXI Installer - Windows
# Usage: irm https://muxi.org/install | iex
#
# TODO: This script needs to be tested on a Windows machine!

param(
    [switch]$NonInteractive,
    [switch]$CliOnly,
    [switch]$SkipDownload,
    [switch]$DryRun,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# Colors (gold brand color #c98b45)
$Gold = "`e[38;2;201;139;69m"
$Green = "`e[32m"
$Blue = "`e[34m"
$Cyan = "`e[36m"
$Red = "`e[31m"
$Reset = "`e[0m"

# Symbols
$Check = "${Green}✓${Reset}"
$Cross = "${Red}✗${Reset}"
$Arrow = "${Blue}→${Reset}"

# URLs
$TelemetryUrl = "https://capture.muxi.org"

# Display help
if ($Help) {
    Write-Host @"
MUXI Installer - Windows

USAGE:
    irm https://muxi.org/install | iex
    
OPTIONS:
    -NonInteractive   Skip prompts, use defaults
    -CliOnly          Install CLI only (no server)
    -SkipDownload     Skip downloads (testing)
    -DryRun           Download but don't install
    -Help             Show this help

EXAMPLES:
    # Interactive install
    irm https://muxi.org/install | iex
    
    # CLI only
    irm https://muxi.org/install | iex -CliOnly
"@
    exit 0
}

# Banner
$Banner = "${Gold}
███╗   ███╗██╗   ██╗██╗  ██╗██╗
████╗ ████║██║   ██║╚██╗██╔╝██║
██╔████╔██║██║   ██║ ╚███╔╝ ██║
██║╚██╔╝██║██║   ██║ ██╔██╗ ██║
██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗██║
╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝
${Reset}"

# Paths
$MuxiDir = "$env:USERPROFILE\.muxi"
$InstallDir = "$env:LOCALAPPDATA\MUXI\bin"
$ConfigFile = "$MuxiDir\config.yaml"

# Detect architecture
$Arch = if ([Environment]::Is64BitOperatingSystem) {
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "arm64" } else { "amd64" }
} else {
    Write-Host "${Cross} 32-bit Windows is not supported" -ForegroundColor Red
    exit 1
}

# Detect headless environment (no GUI/browser available)
function Test-Headless {
    # SSH session
    if ($env:SSH_CLIENT -or $env:SSH_TTY) { return $true }
    
    # CI environments
    if ($env:CI) { return $true }
    
    # Windows Server Core (no GUI)
    try {
        $gui = Get-WindowsFeature -Name "Server-Gui-Shell" -ErrorAction SilentlyContinue
        if ($gui -and -not $gui.Installed) { return $true }
    } catch {}
    
    return $false
}

# Get OS machine ID (deterministic)
function Get-OSMachineId {
    try {
        $uuid = (Get-CimInstance -Class Win32_ComputerSystemProduct).UUID
        return $uuid
    } catch {
        return ""
    }
}

# Generate deterministic machine ID
function Get-MachineId {
    # Check if already in config
    if (Test-Path $ConfigFile) {
        $content = Get-Content $ConfigFile -Raw
        if ($content -match "machine_id:\s*(.+)") {
            return $matches[1].Trim()
        }
    }
    
    # Generate from OS machine ID
    $osId = Get-OSMachineId
    if ($osId) {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes("${osId}muxi")
        $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
        $hashHex = [BitConverter]::ToString($hash) -replace '-', ''
        $machineId = "$($hashHex.Substring(0,8))-$($hashHex.Substring(8,4))-$($hashHex.Substring(12,4))-$($hashHex.Substring(16,4))-$($hashHex.Substring(20,12))".ToLower()
    } else {
        # Fallback to random GUID
        $machineId = [guid]::NewGuid().ToString()
    }
    
    # Create config
    New-Item -ItemType Directory -Force -Path $MuxiDir | Out-Null
    @"
machine_id: $machineId
telemetry: true
"@ | Set-Content $ConfigFile
    
    return $machineId
}

# Get geo info (cached)
function Get-GeoInfo {
    $geoFile = "$MuxiDir\geo.json"
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    
    # Check cache (24h)
    if (Test-Path $geoFile) {
        try {
            $geo = Get-Content $geoFile | ConvertFrom-Json
            if ($geo.cached_at -and ($now - $geo.cached_at) -lt 86400) {
                return $geo
            }
        } catch {}
    }
    
    # Fetch fresh
    try {
        $response = Invoke-RestMethod -Uri "http://ip-api.com/json/" -TimeoutSec 2
        $geo = @{
            ip = $response.query
            country_code = $response.countryCode
            cached_at = $now
        }
        New-Item -ItemType Directory -Force -Path $MuxiDir | Out-Null
        $geo | ConvertTo-Json | Set-Content $geoFile
        return $geo
    } catch {
        return @{ ip = ""; country_code = "" }
    }
}

# Send telemetry (async)
function Send-Telemetry {
    param($Success, $DurationMs, $InstallServer, $InstallCli)
    
    # Check opt-out
    if ($env:MUXI_TELEMETRY -eq "0") { return }
    
    $ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    
    $payload = @{
        module = "install"
        machine_id = $script:MachineId
        ts = $ts
        country = $script:GeoCountry
        payload = @{
            version = "0.1.0"
            install_method = "powershell"
            os = "windows"
            arch = $Arch
            server = $InstallServer
            cli = $InstallCli
            success = $Success
            duration_ms = $DurationMs
        }
    } | ConvertTo-Json -Depth 3
    
    # Fire and forget
    Start-Job -ScriptBlock {
        param($url, $body)
        try {
            Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json" -TimeoutSec 5 | Out-Null
        } catch {}
    } -ArgumentList "$TelemetryUrl/v1/telemetry/", $payload | Out-Null
}

# Send optin (async)
function Send-Optin {
    param($Email)
    
    $geo = Get-GeoInfo
    
    $payload = @{
        email = $Email
        machine_id = $script:MachineId
        ip = $geo.ip
        country = $geo.country_code
    } | ConvertTo-Json
    
    Start-Job -ScriptBlock {
        param($url, $body)
        try {
            Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/json" -TimeoutSec 5 | Out-Null
        } catch {}
    } -ArgumentList "$TelemetryUrl/v1/optin/", $payload | Out-Null
}

# Get latest version from GitHub
function Get-LatestVersion {
    param($Repo)
    try {
        $response = Invoke-WebRequest -Uri "https://github.com/$Repo/releases/latest" -MaximumRedirection 0 -ErrorAction SilentlyContinue
    } catch {
        if ($_.Exception.Response.Headers.Location) {
            $location = $_.Exception.Response.Headers.Location.ToString()
            if ($location -match "/tag/(.+)$") {
                return $matches[1]
            }
        }
    }
    return "v0.1.0"
}

# Main installation
$StartTime = Get-Date

# Initialize
$script:MachineId = Get-MachineId
$InstallTs = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Get geo and save to config
$script:GeoData = Get-GeoInfo
$script:GeoCountry = $script:GeoData.country_code
if ($script:GeoCountry) {
    Set-ConfigValue "geo" $script:GeoCountry
}

# Component selection
$InstallServer = -not $CliOnly
$InstallCli = $true

# Show banner
if (-not $NonInteractive) {
    Write-Host $Banner
    Write-Host "Welcome to MUXI installer!"
    Write-Host ""
    
    # Interactive component selection
    if (-not $CliOnly) {
        Write-Host "${Arrow} What would you like to install?"
        Write-Host "  ${Gold}◉ Server + CLI (recommended)${Reset}"
        Write-Host "  ○ CLI only"
        Write-Host ""
        Write-Host "Press 1 or 2, then Enter: " -NoNewline
        $choice = Read-Host
        if ($choice -eq "2") {
            $InstallServer = $false
        }
        Write-Host ""
    }
}

# Show what we're installing
Write-Host "${Arrow} Platform: windows/${Arch}"
if ($InstallServer -and $InstallCli) {
    Write-Host "${Arrow} Installing: Server + CLI"
} else {
    Write-Host "${Arrow} Installing: CLI only"
}
Write-Host ""

# Create directories
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
New-Item -ItemType Directory -Force -Path $MuxiDir | Out-Null

# Download and install
if ($SkipDownload) {
    Write-Host "${Check} Downloaded MUXI Server v0.1.0 (skipped)"
    Write-Host "${Check} Downloaded MUXI CLI v0.1.0 (skipped)"
    $ServerVersion = "v0.1.0"
    $CliVersion = "v0.1.0"
} else {
    # Install Server
    if ($InstallServer) {
        $ServerVersion = Get-LatestVersion "muxi-ai/server"
        $binaryName = "muxi-server-windows-${Arch}.exe"
        $downloadUrl = "https://github.com/muxi-ai/server/releases/download/$ServerVersion/$binaryName"
        $targetPath = "$InstallDir\muxi-server.exe"
        
        Write-Host "${Blue}⠋${Reset} Downloading MUXI Server..." -NoNewline
        try {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $targetPath -UseBasicParsing
            Write-Host "`r${Check} Downloaded MUXI Server $ServerVersion    "
        } catch {
            Write-Host "`r${Cross} Failed to download MUXI Server"
            $EndTime = Get-Date
            $DurationMs = [int](($EndTime - $StartTime).TotalMilliseconds)
            Send-Telemetry -Success $false -DurationMs $DurationMs -InstallServer $InstallServer -InstallCli $InstallCli
            exit 1
        }
    }
    
    # Install CLI
    if ($InstallCli) {
        $CliVersion = Get-LatestVersion "muxi-ai/cli"
        $binaryName = "muxi-windows-${Arch}.exe"
        $downloadUrl = "https://github.com/muxi-ai/cli/releases/download/$CliVersion/$binaryName"
        $targetPath = "$InstallDir\muxi.exe"
        
        Write-Host "${Blue}⠋${Reset} Downloading MUXI CLI..." -NoNewline
        try {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $targetPath -UseBasicParsing
            Write-Host "`r${Check} Downloaded MUXI CLI $CliVersion    "
        } catch {
            Write-Host "`r${Cross} Failed to download MUXI CLI"
            $EndTime = Get-Date
            $DurationMs = [int](($EndTime - $StartTime).TotalMilliseconds)
            Send-Telemetry -Success $false -DurationMs $DurationMs -InstallServer $InstallServer -InstallCli $InstallCli
            exit 1
        }
    }
}

# Calculate duration
$EndTime = Get-Date
$DurationMs = [int](($EndTime - $StartTime).TotalMilliseconds)

Write-Host ""
Write-Host "${Check} Installation complete!"
Write-Host ""

# Send telemetry
Send-Telemetry -Success $true -DurationMs $DurationMs -InstallServer $InstallServer -InstallCli $InstallCli

# Update PATH
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$InstallDir", "User")
    $env:Path = "$env:Path;$InstallDir"
    Write-Host "${Check} Added to PATH"
    Write-Host "   Restart your terminal for changes to take effect"
    Write-Host ""
}

# Email opt-in (interactive only)
if (-not $NonInteractive) {
    $line = "─" * 60
    Write-Host $line
    Write-Host "${Arrow} STAY IN THE LOOP"
    Write-Host $line
    Write-Host "Get security alerts, release notes, and early access to new features."
    Write-Host "(low volume, unsubscribe anytime)"
    Write-Host ""
    $email = Read-Host "Email [Enter to skip]"
    
    if ($email) {
        Write-Host "Email: $email"
        Write-Host ""
        Send-Optin -Email $email
        
        # Update config
        Add-Content -Path $ConfigFile -Value "email_optin: true"
        
        Write-Host "${Check} Subscribed! Check your inbox for a welcome email."
    } else {
        Write-Host "Email: Skipped"
    }
    Write-Host $line
    Write-Host ""
}

# Quickstart video prompt (headed machines only)
if (-not $NonInteractive -and -not (Test-Headless)) {
    Write-Host ""
    if ($InstallServer) {
        Write-Host "${Arrow} Learn how to set up your server and deploy your first AI agent in under 2 minutes."
        $mode = "all"
    } else {
        Write-Host "${Arrow} Learn how to configure the CLI and deploy your first AI agent in under 2 minutes."
        $mode = "cli"
    }
    
    $openVideo = Read-Host "  Open quickstart video? (Y/n)"
    if (-not $openVideo -or $openVideo -eq "y" -or $openVideo -eq "Y") {
        $url = "https://muxi.org/post-install?mode=$mode&ic=$($script:MachineId)"
        Start-Process $url
    }
    Write-Host ""
}

# Next steps
Write-Host "Next steps:"
Write-Host ""
if ($InstallServer) {
    Write-Host "  1. Initialize the server:"
    Write-Host "     ${Cyan}muxi-server init${Reset}"
    Write-Host ""
    Write-Host "  2. Start the server:"
    Write-Host "     ${Cyan}muxi-server start${Reset}"
} else {
    Write-Host "  1. Connect to a server:"
    Write-Host "     ${Cyan}muxi profiles add${Reset}"
    Write-Host ""
    Write-Host "  2. Create a formation:"
    Write-Host "     ${Cyan}muxi new formation${Reset}"
    Write-Host ""
    Write-Host "You can also start with a demo formation:"
    Write-Host "  ${Cyan}muxi pull @muxi/quickstart${Reset}"
}
Write-Host ""
Write-Host "Docs: https://muxi.org/docs"
Write-Host ""
