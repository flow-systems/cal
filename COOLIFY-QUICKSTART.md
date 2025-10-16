# 🚀 Cal.com Coolify Quick Start

Deploy Cal.com to your VPS with Coolify in under 15 minutes!

## Prerequisites Checklist

- [ ] Coolify installed and running on your VPS
- [ ] Domain name pointed to your VPS
- [ ] SMTP credentials (Gmail, SendGrid, or any email provider)

## 5-Step Deployment

### 1️⃣ Create PostgreSQL Database

1. In Coolify → **+ New Resource** → **Database** → **PostgreSQL 15**
2. Save the connection details shown
3. Your `DATABASE_URL` will look like:
   ```
   postgresql://username:password@postgres:5432/calcom
   ```

### 2️⃣ Create Cal.com Application

1. In Coolify → **+ New Resource** → **Docker Compose**
2. **Source**: Public Repository
3. **Repository URL**: `https://github.com/calcom/cal.com`
4. **Branch**: `main` or `staging`
5. **Build Pack**: `Dockerfile`

### 3️⃣ Set Environment Variables

Click **Environment Variables** and add these **REQUIRED** variables:

```bash
# Generate these first! Run on your computer:
# openssl rand -base64 32   (for NEXTAUTH_SECRET)
# openssl rand -base64 24   (for CALENDSO_ENCRYPTION_KEY)
# openssl rand -base64 32   (for CRON_API_KEY)

NEXT_PUBLIC_WEBAPP_URL=https://cal.yourdomain.com
NEXT_PUBLIC_WEBSITE_URL=https://cal.yourdomain.com
NEXTAUTH_URL=https://cal.yourdomain.com/api/auth
NEXTAUTH_SECRET=your-generated-secret-here
CALENDSO_ENCRYPTION_KEY=your-generated-key-here
DATABASE_URL=postgresql://user:pass@postgres:5432/calcom
EMAIL_FROM=notifications@yourdomain.com
EMAIL_SERVER_HOST=smtp.gmail.com
EMAIL_SERVER_PORT=587
EMAIL_SERVER_USER=your-email@gmail.com
EMAIL_SERVER_PASSWORD=your-app-password
CRON_API_KEY=your-generated-cron-key
CRON_ENABLE_APP_SYNC=true
CALCOM_TELEMETRY_DISABLED=1
NODE_ENV=production
```

### 4️⃣ Configure Domain & Deploy

1. **Domains** tab → Add domain: `cal.yourdomain.com`
2. Enable **HTTPS** (Coolify auto-configures Let's Encrypt)
3. Click **Deploy** button
4. ☕ Wait 10-15 minutes for first build

### 5️⃣ Initialize Database

Once deployed, open the **Terminal** in Coolify and run:

```bash
# Navigate to app directory
cd /app

# Run database migrations
yarn workspace @calcom/prisma db-deploy

# Optional: Add sample data
yarn workspace @calcom/prisma db-seed
```

## 🎉 Done! Access Your Cal.com

Visit `https://cal.yourdomain.com` and create your first user!

---

## Quick Configs

### Gmail SMTP Setup

1. Enable 2FA in your Google Account
2. Generate App Password: https://myaccount.google.com/apppasswords
3. Use these settings:
   ```bash
   EMAIL_SERVER_HOST=smtp.gmail.com
   EMAIL_SERVER_PORT=587
   EMAIL_SERVER_USER=your-email@gmail.com
   EMAIL_SERVER_PASSWORD=your-16-char-app-password
   ```

### SendGrid Setup (Alternative)

1. Create account at https://sendgrid.com
2. Get API key from Settings → API Keys
3. Use these settings:
   ```bash
   SENDGRID_API_KEY=SG.xxxxx
   SENDGRID_EMAIL=notifications@yourdomain.com
   ```

### Disable Public Signups

Add this to environment variables:
```bash
NEXT_PUBLIC_DISABLE_SIGNUP=1
```

---

## Common Issues & Fixes

### ❌ "Build failed" or "Out of memory"
**Solution**: Increase memory in Coolify server settings to at least 4GB

### ❌ "Cannot connect to database"
**Solution**: 
- Check DATABASE_URL format
- Ensure PostgreSQL service is running
- Try using internal docker network name for host

### ❌ "Email not sending"
**Solution**:
- Verify SMTP credentials
- For Gmail: use App Password, not regular password
- Check EMAIL_SERVER_PORT (usually 587 or 465)

### ❌ "Site not accessible"
**Solution**:
- Verify DNS is pointed to VPS IP
- Check domain configuration in Coolify
- Wait a few minutes for SSL provisioning

### ❌ "Application keeps restarting"
**Solution**:
- Check logs in Coolify
- Verify all required env variables are set
- Ensure NEXTAUTH_SECRET and CALENDSO_ENCRYPTION_KEY are set

---

## Optional Integrations

### Google Calendar

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/dashboard)
2. Create project → Enable Calendar API
3. Create OAuth 2.0 credentials
4. Add redirect: `https://cal.yourdomain.com/api/integrations/googlecalendar/callback`
5. Add to environment:
   ```bash
   GOOGLE_API_CREDENTIALS={"web":{"client_id":"...","client_secret":"...","redirect_uris":["..."]}}
   GOOGLE_LOGIN_ENABLED=true
   ```

### Zoom Integration

1. Go to [Zoom Marketplace](https://marketplace.zoom.us/)
2. Create → General App
3. Add redirect: `https://cal.yourdomain.com/api/integrations/zoomvideo/callback`
4. Add to environment:
   ```bash
   ZOOM_CLIENT_ID=your-client-id
   ZOOM_CLIENT_SECRET=your-client-secret
   ```

### Stripe Payments

1. Get API keys from [Stripe Dashboard](https://dashboard.stripe.com)
2. Add to environment:
   ```bash
   NEXT_PUBLIC_STRIPE_PUBLIC_KEY=pk_live_...
   STRIPE_PRIVATE_KEY=sk_live_...
   STRIPE_CLIENT_ID=ca_...
   STRIPE_WEBHOOK_SECRET=whsec_...
   ```

---

## Updating Cal.com

### Method 1: Via Coolify UI
1. Go to your application in Coolify
2. Click **Redeploy**
3. Wait for rebuild

### Method 2: Automatic Updates
1. Enable **Auto Deploy** in General settings
2. Coolify will deploy on each Git push

---

## Pro Tips

1. **Backup Your Database**: Use Coolify's backup feature weekly
2. **Monitor Logs**: Check Coolify logs if something goes wrong
3. **Resource Limits**: Set at least 2GB RAM for smooth operation
4. **Security**: Never commit `.env` files, use strong passwords
5. **Performance**: Consider adding Redis for caching in production

---

## Need Help?

- 📖 Full Guide: See `DEPLOYMENT.md` in this repository
- 💬 Cal.com Discord: https://discord.gg/calcom
- 🐛 Issues: https://github.com/calcom/cal.com/issues
- 📚 Docs: https://cal.com/docs

---

## What You Just Deployed

Cal.com is a powerful open-source scheduling platform:
- 📅 Calendar integrations (Google, Outlook, Apple)
- 🎥 Video conferencing (Zoom, Google Meet, MS Teams)
- 💳 Payment processing (Stripe)
- 📧 Automated reminders & workflows
- 🌍 Multi-language support
- 🔐 Enterprise-grade security

**License**: AGPLv3 (Free for self-hosting)

---

Enjoy your self-hosted Cal.com! 🎊

