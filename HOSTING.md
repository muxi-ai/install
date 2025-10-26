# Hosting Guide for install.muxi.org

This guide covers different ways to host the MUXI installer with automatic client detection.

---

## Detection Logic

The installer detects clients based on `User-Agent` headers:

| Client | User-Agent Contains | Action |
|--------|---------------------|--------|
| curl | `curl` | Serves `install.sh` |
| wget | `wget` | Serves `install.sh` |
| PowerShell | `WindowsPowerShell`, `PowerShell` | Serves `install.ps1` |
| Browser | (default) | Redirects to `https://muxi.org/docs/install` |

---

## Hosting Options

### 1. **Cloudflare Workers** (Recommended)

**Pros:** Edge computing, zero cold start, free tier, global CDN

**Setup:**
```bash
# 1. Install Wrangler CLI
npm install -g wrangler

# 2. Deploy worker
cd install/
wrangler deploy cloudflare-worker.js

# 3. Set custom domain in Cloudflare dashboard
# Workers > Your Worker > Settings > Triggers > Custom Domains
# Add: install.muxi.org
```

**Cost:** Free (100k requests/day)

---

### 2. **Vercel Serverless**

**Pros:** Simple deployment, GitHub integration, automatic HTTPS

**Setup:**
```bash
# 1. Install Vercel CLI
npm install -g vercel

# 2. Deploy
cd install/
vercel --prod

# 3. Set custom domain in Vercel dashboard
# Settings > Domains > Add: install.muxi.org
```

**Cost:** Free (100GB bandwidth/month)

---

### 3. **PHP Hosting** (Traditional)

**Pros:** Works on any shared hosting, simple

**Setup:**
1. Upload these files to your server:
   - `index.php`
   - `install.sh`
   - `install.ps1`

2. Point `install.muxi.org` to your server

3. Ensure PHP is enabled (most hosts have it by default)

**Requirements:**
- PHP 7.0+
- Apache or Nginx

**Cost:** Varies ($5-20/month for shared hosting)

---

### 4. **Nginx** (Recommended for VPS)

**Pros:** High performance, simple config, widely used

**Setup:**
```bash
# 1. Install nginx (if not already installed)
sudo apt update && sudo apt install nginx

# 2. Copy files to web root
sudo mkdir -p /var/www/install.muxi.org
sudo cp install.sh install.ps1 /var/www/install.muxi.org/

# 3. Copy nginx config
sudo cp nginx.conf /etc/nginx/sites-available/install.muxi.org

# 4. Enable site
sudo ln -s /etc/nginx/sites-available/install.muxi.org /etc/nginx/sites-enabled/

# 5. Get SSL certificate (Let's Encrypt)
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d install.muxi.org

# 6. Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

**Requirements:**
- Nginx 1.18+
- SSL certificate (use certbot for free Let's Encrypt cert)

**Cost:** $5-20/month (VPS like DigitalOcean, Linode, etc.)

---

### 5. **Apache with .htaccess** (No PHP)

**Pros:** Static hosting, no server-side code

**Setup:**
1. Upload these files:
   - `.htaccess`
   - `install.sh`
   - `install.ps1`

2. Enable `mod_rewrite` and `mod_headers` in Apache

3. Point `install.muxi.org` to your server

**Requirements:**
- Apache 2.4+
- `AllowOverride All` in Apache config

**Cost:** Varies (shared hosting)

---

### 5. **GitHub Pages + Cloudflare Worker**

**Pros:** Static hosting on GitHub, routing on Cloudflare

**Setup:**
1. Push `install.sh` and `install.ps1` to GitHub repo
2. Enable GitHub Pages
3. Deploy Cloudflare Worker (fetch scripts from GitHub Pages)
4. Route `install.muxi.org` to Cloudflare Worker

**Cost:** Free

---

### 6. **Netlify Edge Functions**

**Pros:** Similar to Vercel, great DX

**Setup:**
```bash
# 1. Install Netlify CLI
npm install -g netlify-cli

# 2. Create netlify/edge-functions/install.js:
export default async (request, context) => {
  const ua = request.headers.get('user-agent').toLowerCase();
  
  if (ua.includes('powershell')) {
    return fetch('https://raw.githubusercontent.com/muxi-ai/install/main/install.ps1');
  }
  if (ua.includes('curl') || ua.includes('wget')) {
    return fetch('https://raw.githubusercontent.com/muxi-ai/install/main/install.sh');
  }
  
  return new Response(landingPageHTML, {
    headers: { 'content-type': 'text/html' }
  });
};

# 3. Deploy
netlify deploy --prod

# 4. Set custom domain
```

**Cost:** Free (100GB bandwidth/month)

---

## Comparison

| Method | Complexity | Speed | Cost | Maintenance |
|--------|------------|-------|------|-------------|
| **Cloudflare Workers** | Low | ⚡ Instant | Free | Minimal |
| **Vercel** | Very Low | ⚡ Fast | Free | Minimal |
| **Netlify** | Low | ⚡ Fast | Free | Minimal |
| **PHP** | Medium | 🐢 Depends | $5-20/mo | Moderate |
| **Apache .htaccess** | Medium | 🐢 Depends | $5-20/mo | Moderate |
| **GitHub Pages + Worker** | Medium | ⚡ Fast | Free | Minimal |

---

## Recommended Setup

**Best for most cases:** Cloudflare Workers

```bash
# One-time setup
npm install -g wrangler
wrangler login

# Deploy
cd install/
wrangler deploy cloudflare-worker.js

# Done! Your installer is live at install.muxi.org
```

**Why Cloudflare Workers:**
- ✅ Free tier is generous (100k requests/day)
- ✅ Edge computing = zero cold start
- ✅ Global CDN = fast everywhere
- ✅ Simple deployment
- ✅ Easy to update (just `wrangler deploy`)
- ✅ Built-in HTTPS
- ✅ Custom domains included

---

## Testing

Test all client types:

```bash
# Test curl (should get install.sh)
curl -v install.muxi.org

# Test PowerShell (should get install.ps1)
pwsh -c "Invoke-WebRequest install.muxi.org"

# Test browser (should get landing page)
open https://install.muxi.org
```

---

## Security Considerations

1. **HTTPS Only:** Always serve over HTTPS
2. **Cache Headers:** Set appropriate `Cache-Control` (5-10 minutes)
3. **Rate Limiting:** Consider rate limiting to prevent abuse
4. **Script Integrity:** Serve scripts from trusted sources only
5. **CORS:** Not needed for install scripts (they're executed locally)

---

## Monitoring

Track usage with:
- Cloudflare Analytics (built-in)
- Vercel Analytics (built-in)
- Google Analytics (add to landing page)
- Custom logging (add to worker/function)

Example metrics:
- Total installs (curl/wget requests)
- Windows vs Unix/Mac ratio (PowerShell vs curl)
- Geographic distribution
- Browser visits (curiosity/documentation)

---

## Updating Scripts

When you update `install.sh` or `install.ps1`:

**Cloudflare Workers:**
```bash
wrangler deploy
```

**Vercel:**
```bash
git push origin main  # Auto-deploys
```

**PHP/Apache:**
```bash
scp install.sh install.ps1 user@server:/path/to/install/
```

**Pro tip:** Add version comments to scripts for tracking:
```bash
# Version: 2025-10-26-001
# Last updated: 2025-10-26
```
