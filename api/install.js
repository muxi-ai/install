/**
 * MUXI Installation Router - Vercel Serverless Function
 * 
 * Deploy to Vercel for serverless routing
 * 
 * Setup:
 *   1. Deploy this repo to Vercel
 *   2. Set custom domain: install.muxi.org
 *   3. Scripts are served from /install.sh and /install.ps1
 */

const fs = require('fs');
const path = require('path');

module.exports = async (req, res) => {
  const userAgent = req.headers['user-agent'] || '';
  const clientType = detectClient(userAgent);
  
  try {
    switch (clientType) {
      case 'powershell':
        return serveScript(res, 'install.ps1');
      
      case 'curl':
      case 'wget':
        return serveScript(res, 'install.sh');
      
      case 'browser':
      default:
        return res.redirect(302, 'https://muxi.org/docs/install');
    }
  } catch (error) {
    res.status(500).send('Error loading installation script');
  }
};

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

function serveScript(res, filename) {
  const scriptPath = path.join(process.cwd(), filename);
  const script = fs.readFileSync(scriptPath, 'utf8');
  
  res.setHeader('Content-Type', 'text/plain; charset=utf-8');
  res.setHeader('Cache-Control', 'public, max-age=300');
  res.status(200).send(script);
}


