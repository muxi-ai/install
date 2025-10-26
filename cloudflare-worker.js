/**
 * MUXI Installation Router - Cloudflare Worker
 * 
 * Deploy to Cloudflare Workers for edge-based routing
 * 
 * Setup:
 *   1. Create Cloudflare Worker at install.muxi.org
 *   2. Paste this code
 *   3. Set up routes: install.muxi.org/*
 * 
 * GitHub URLs (replace with actual release URLs or use R2/KV storage)
 */

const INSTALL_SH_URL = 'https://raw.githubusercontent.com/muxi-ai/install/main/install.sh';
const INSTALL_PS1_URL = 'https://raw.githubusercontent.com/muxi-ai/install/main/install.ps1';

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
  const userAgent = request.headers.get('User-Agent') || '';
  const clientType = detectClient(userAgent);
  
  switch (clientType) {
    case 'powershell':
      return fetchScript(INSTALL_PS1_URL, 'text/plain');
    
    case 'curl':
    case 'wget':
      return fetchScript(INSTALL_SH_URL, 'text/plain');
    
    case 'browser':
    default:
      return Response.redirect('https://muxi.org/docs/install', 302);
  }
}

function detectClient(userAgent) {
  const ua = userAgent.toLowerCase();
  
  if (ua.includes('windowspowershell') || ua.includes('powershell')) {
    return 'powershell';
  }
  
  if (ua.includes('curl')) {
    return 'curl';
  }
  
  if (ua.includes('wget')) {
    return 'wget';
  }
  
  return 'browser';
}

async function fetchScript(url, contentType) {
  const response = await fetch(url);
  const script = await response.text();
  
  return new Response(script, {
    headers: { 
      'Content-Type': contentType,
      'Cache-Control': 'public, max-age=300' // Cache for 5 minutes
    }
  });
}


