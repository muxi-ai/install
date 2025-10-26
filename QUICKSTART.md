# Quick Start Guide

Choose your deployment method:

---

## 🚀 Option 1: Nginx (Simplest - You Already Have It!)

**Time: 5 minutes**

```bash
# Copy files
sudo mkdir -p /var/www/install.muxi.org
sudo cp install.sh install.ps1 /var/www/install.muxi.org/
sudo cp nginx.conf /etc/nginx/sites-available/install.muxi.org

# Enable site
sudo ln -s /etc/nginx/sites-available/install.muxi.org /etc/nginx/sites-enabled/

# Get SSL cert
sudo certbot --nginx -d install.muxi.org

# Reload
sudo nginx -t && sudo systemctl reload nginx
```

**Update DNS at your registrar:**
```
A record: install.muxi.org → your-server-ip
```

**Test:**
```bash
curl -sSL install.muxi.org | bash
```

✅ **Done!**

---

## ⚡ Option 2: Cloudflare Workers (Global Edge Performance)

**Time: 15 minutes | Cost: FREE (requires NS move to Cloudflare)**

### Quick Setup

```bash
# 1. Install Wrangler
npm install -g wrangler

# 2. Login
wrangler login

# 3. Create config
cd /Users/ran/Projects/muxi/code/install
cat > wrangler.toml << 'EOF'
name = "muxi-installer"
main = "cloudflare-worker.js"
compatibility_date = "2024-10-26"
routes = [
  { pattern = "install.muxi.org/*", zone_name = "muxi.org" }
]
EOF

# 4. Deploy
wrangler deploy
```

### DNS Setup (in Cloudflare Dashboard)

1. Add site: `muxi.org` to Cloudflare
2. Move nameservers to Cloudflare (they'll give you NS records)
3. Add DNS record:
   ```
   Type: CNAME
   Name: install
   Target: muxi-installer.YOUR-SUBDOMAIN.workers.dev
   Proxy: ON (orange cloud)
   ```

**Test:**
```bash
curl -sSL install.muxi.org | bash
```

✅ **Done!**

---

## 📊 Comparison

| Feature | Nginx | Cloudflare Workers |
|---------|-------|-------------------|
| **Setup Time** | 5 min | 15 min |
| **Cost** | VPS cost | Free |
| **Performance** | Single location | Global edge (200+ cities) |
| **NS Change** | No | Yes (for free tier) |
| **SSL** | Let's Encrypt | Automatic |
| **Updates** | Manual file copy | `wrangler deploy` |
| **Maintenance** | You manage | Cloudflare manages |

---

## Recommendation

- **Start with nginx** (you already have it!)
- **Upgrade to Cloudflare later** if you want global edge performance

Both work perfectly - nginx is simpler to start! 🎯
