<?php
/**
 * MUXI Installation Router
 * 
 * Serves appropriate installation script based on client detection:
 * - curl/wget (Linux/macOS) → install.sh
 * - PowerShell (Windows) → install.ps1
 * - Browser → landing page with instructions
 * 
 * Usage:
 *   curl -sSL install.muxi.org | bash
 *   irm install.muxi.org | iex
 *   wget -qO- install.muxi.org | bash
 */

// Get User-Agent
$userAgent = $_SERVER['HTTP_USER_AGENT'] ?? '';

// Detect client type
function detectClient($userAgent) {
    $ua = strtolower($userAgent);
    
    // PowerShell detection (Windows)
    if (strpos($ua, 'windowspowershell') !== false || 
        strpos($ua, 'powershell') !== false) {
        return 'powershell';
    }
    
    // curl detection (Linux/macOS)
    if (strpos($ua, 'curl') !== false) {
        return 'curl';
    }
    
    // wget detection (Linux)
    if (strpos($ua, 'wget') !== false) {
        return 'wget';
    }
    
    // Invoke-WebRequest detection (PowerShell modern)
    if (strpos($ua, 'invoke-webrequest') !== false) {
        return 'powershell';
    }
    
    // Default to browser
    return 'browser';
}

$clientType = detectClient($userAgent);

// Route to appropriate response
switch ($clientType) {
    case 'powershell':
        // Serve PowerShell script
        header('Content-Type: text/plain; charset=utf-8');
        readfile(__DIR__ . '/install.ps1');
        break;
    
    case 'curl':
    case 'wget':
        // Serve bash script
        header('Content-Type: text/plain; charset=utf-8');
        readfile(__DIR__ . '/install.sh');
        break;
    
    case 'browser':
    default:
        // Redirect browsers to documentation
        header('Location: https://muxi.org/docs/install', true, 302);
        exit;
        break;
}

?>
