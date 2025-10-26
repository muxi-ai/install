# Cloudflare Workers Setup Guide

Complete guide to deploying the MUXI installer on Cloudflare Workers.

---

## Option 1: Cloudflare Workers WITHOUT Moving Nameservers (Recommended for You)

**Requirements:**
- Cloudflare Workers Paid plan ($5/month for custom domains)
- Keep your current DNS provider
- Just point `install.muxi.org` CNAME to Cloudflare

**Why this costs $5/month:** Custom domains on Workers require the paid plan when your domain isn't on Cloudflare nameservers.

---

## Option 2: Full Cloudflare (FREE but requires NS transfer)

**Requirements:**
- Move your domain nameservers to Cloudflare (free)
- Cloudflare becomes your DNS provider
- Custom domains on Workers are free

**Pros:** Completely free, includes CDN, DDoS protection, analytics
**Cons:** Need to move NS records (5-10 min setup)

---

## Option 3: Just Use Nginx (Simplest for You!)

**Since you already have nginx running:**
```bash
# You're already set up! Just deploy:
sudo cp install.sh install.ps1 /var/www/install.muxi.org/
sudo cp nginx.conf /etc/nginx/sites-available/install.muxi.org
sudo ln -s /etc/nginx/sites-available/install.muxi.org /etc/nginx/sites-enabled/
sudo certbot --nginx -d install.muxi.org
sudo systemctl reload nginx
```

**Point DNS:** `A record: install.muxi.org → your-server-ip`

**Done!** No Cloudflare needed.

---

## Recommendation: Which Option?

| Scenario | Best Choice | Why |
|----------|-------------|-----|
| **You have a VPS with nginx** | Option 3 (nginx) | Simplest, free, you control everything |
| **You want global edge performance** | Option 2 (Full Cloudflare) | Free, fast, includes CDN |
| **You can't move nameservers** | Option 1 (Workers + $5/mo) | Paid but no NS change needed |

**My recommendation:** Start with **Option 3 (nginx)** since you already have it set up. You can always migrate to Cloudflare later if you want edge performance.

---

## Full Guide: Option 2 (Free Cloudflare Workers)

Let's go with the free option that gives you maximum performance!

### Step 1: Move Domain to Cloudflare (One-Time Setup)

#### 1.1. Create Cloudflare Account
```bash
# Go to: https://dash.cloudflare.com/sign-up
# Sign up with your email (free plan is fine)
```

#### 1.2. Add Your Domain
1. Click **"Add a Site"** in Cloudflare dashboard
2. Enter: `muxi.org` (your root domain)
3. Select **Free plan**
4. Click **"Continue"**

#### 1.3. Cloudflare Will Scan Your DNS Records
- Cloudflare automatically imports your existing DNS records
- Review them to make sure everything is there
- Click **"Continue"**

#### 1.4. Update Nameservers at Your Domain Registrar
Cloudflare will show you two nameservers like:
```
ns1.cloudflare.com
ns2.cloudflare.com
```

**Go to your domain registrar** (e.g., Namecheap, GoDaddy, etc.) and update:
```
Old NS: your-current-nameservers.com
New NS: 
  - ns1.cloudflare.com (or whatever Cloudflare shows)
  - ns2.cloudflare.com
```

**Wait 5-60 minutes** for DNS propagation. Cloudflare will email you when it's active.

---

### Step 2: Deploy Cloudflare Worker

#### 2.1. Install Wrangler (Cloudflare CLI)
```bash
# Install Node.js if you don't have it
# (Check: node --version)

# Install Wrangler globally
npm install -g wrangler

# Login to Cloudflare
wrangler login
# This opens a browser - click "Allow" to authorize
```

#### 2.2. Create Worker Project
```bash
# Navigate to your install repo
cd /Users/ran/Projects/muxi/code/install

# Create wrangler.toml config
cat > wrangler.toml << 'EOF'
name = "muxi-installer"
main = "cloudflare-worker.js"
compatibility_date = "2024-10-26"

# Route for install.muxi.org
routes = [
  { pattern = "install.muxi.org/*", zone_name = "muxi.org" }
]
EOF
```

#### 2.3. Deploy Worker
```bash
# Deploy to Cloudflare
wrangler deploy

# Output will show:
# ✨ Built successfully
# ✨ Uploaded successfully
# 🌎 Published to https://muxi-installer.your-subdomain.workers.dev
```

---

### Step 3: Connect Custom Domain

#### 3.1. Add DNS Record in Cloudflare
1. Go to **Cloudflare Dashboard** → **DNS** → **Records**
2. Click **"Add record"**
3. Add:
   ```
   Type: CNAME
   Name: install
   Target: muxi-installer.your-subdomain.workers.dev
   Proxy status: Proxied (orange cloud)
   ```
4. Click **"Save"**

#### 3.2. Add Route in Worker Settings
1. Go to **Workers & Pages** in Cloudflare Dashboard
2. Click your worker: **muxi-installer**
3. Go to **Settings** → **Triggers** → **Routes**
4. Click **"Add route"**
5. Enter:
   ```
   Route: install.muxi.org/*
   Zone: muxi.org
   ```
6. Click **"Save"**

---

### Step 4: Test It!

```bash
# Test curl (should get install.sh)
curl -v install.muxi.org

# Test PowerShell (should get install.ps1)
# (Run in PowerShell on Windows)
Invoke-WebRequest install.muxi.org

# Test browser (should redirect to muxi.org/docs/install)
open https://install.muxi.org
```

**Expected outputs:**
```bash
# curl/wget → Returns bash script starting with "#!/bin/bash"
# PowerShell → Returns PS script
# Browser → 302 redirect to muxi.org/docs/install
```

---

## Troubleshooting

### Issue: "Route not found"
**Solution:** Make sure the route pattern matches:
- Worker route: `install.muxi.org/*`
- DNS CNAME: `install → your-worker.workers.dev`

### Issue: "DNS_PROBE_FINISHED_NXDOMAIN"
**Solution:** DNS hasn't propagated yet. Wait 5-10 minutes and try again.
```bash
# Check DNS propagation
dig install.muxi.org
# or
nslookup install.muxi.org
```

### Issue: Worker returns 404
**Solution:** Check that `cloudflare-worker.js` is uploaded correctly:
```bash
# Re-deploy
wrangler deploy

# Check logs
wrangler tail
# Then visit install.muxi.org in another terminal
```

### Issue: Can't find wrangler.toml
**Solution:** Make sure you're in the right directory:
```bash
cd /Users/ran/Projects/muxi/code/install
ls -la wrangler.toml
```

---

## Updating the Worker

When you update `cloudflare-worker.js`:
```bash
cd /Users/ran/Projects/muxi/code/install
wrangler deploy
```

**That's it!** Changes are live globally in ~30 seconds.

---

## Cost Breakdown

### Free Tier (after moving NS to Cloudflare):
- ✅ 100,000 requests/day
- ✅ Unlimited custom domains
- ✅ Global CDN (200+ cities)
- ✅ DDoS protection
- ✅ SSL certificates
- ✅ Analytics

**Total: $0/month** 🎉

### Paid Tier ($5/month):
- ✅ 10 million requests/month
- ✅ Everything above
- ✅ Custom domains without NS change

---

## Alternative: Quick Nginx Setup (No Cloudflare)

If you want to skip Cloudflare entirely:

```bash
# 1. Copy files
sudo mkdir -p /var/www/install.muxi.org
sudo cp install.sh install.ps1 /var/www/install.muxi.org/
sudo cp nginx.conf /etc/nginx/sites-available/install.muxi.org

# 2. Enable site
sudo ln -s /etc/nginx/sites-available/install.muxi.org /etc/nginx/sites-enabled/

# 3. Get SSL certificate
sudo certbot --nginx -d install.muxi.org

# 4. Test and reload
sudo nginx -t && sudo systemctl reload nginx
```

**DNS Setup:**
```
A record: install.muxi.org → your-server-ip
```

**Test:**
```bash
curl -sSL install.muxi.org | bash
```

**Done!** 🚀

---

## Summary

| Method | Setup Time | Cost | Performance |
|--------|------------|------|-------------|
| **Nginx** | 5 minutes | Free | Good (single server) |
| **Cloudflare Workers (Free)** | 15 minutes | Free | Excellent (global edge) |
| **Cloudflare Workers (Paid)** | 10 minutes | $5/month | Excellent (global edge) |

**Recommendation for you:** Start with **nginx** (you already have it!), then migrate to **Cloudflare Workers (free)** if you want better global performance later.

---

## Questions?

**Q: Which is faster - nginx or Cloudflare Workers?**
A: Cloudflare Workers are faster globally (200+ edge locations), but nginx is perfectly fine for a simple installer.

**Q: Can I use both?**
A: Yes! You could have nginx as a backup and Cloudflare as primary.

**Q: What if Cloudflare goes down?**
A: Very rare (99.99% uptime), but you could keep nginx as a fallback.

**Q: Do I need to move my whole domain to Cloudflare?**
A: No, but it's easier and free that way. Otherwise pay $5/month for Workers custom domains.
