# 📦 Cal.com Coolify Deployment - Complete Package

## ✅ What's Been Created

Your Cal.com repository now includes everything needed for Coolify deployment:

### Core Files

1. **`Dockerfile`** - Production-optimized multi-stage Docker image
   - Multi-stage build for minimal image size
   - Security hardened (non-root user)
   - Built-in health checks
   - Optimized for production use

2. **`.dockerignore`** - Optimizes build time and image size
   - Excludes development files
   - Reduces build context

3. **`docker-compose.coolify.yml`** - Complete stack with PostgreSQL
   - Includes Cal.com application
   - PostgreSQL database with persistence
   - Health checks for both services
   - Pre-configured networking

### Documentation

4. **`COOLIFY-QUICKSTART.md`** - ⭐ **START HERE!**
   - 5-step deployment guide
   - Copy-paste ready commands
   - Common configurations
   - Quick troubleshooting

5. **`DEPLOYMENT.md`** - Comprehensive deployment guide
   - Detailed setup instructions
   - All configuration options
   - Integration guides (Google, Zoom, Stripe, etc.)
   - Performance optimization tips
   - Security best practices

6. **`DOCKER-README.md`** - Docker-specific documentation
   - Docker commands reference
   - Resource requirements
   - Performance tuning
   - Troubleshooting guide

7. **`.env.coolify.example`** - Complete environment variables template
   - All required variables documented
   - Optional integrations included
   - Comments explain each variable
   - Ready to copy and customize

### Scripts

8. **`scripts/generate-secrets.sh`** - Security key generator
   - Generates NEXTAUTH_SECRET
   - Generates CALENDSO_ENCRYPTION_KEY
   - Generates CRON_API_KEY
   - Executable script ready to run

## 🚀 Next Steps

### 1. Read the Quick Start Guide

Open [`COOLIFY-QUICKSTART.md`](./COOLIFY-QUICKSTART.md) and follow the 5 steps.

### 2. Generate Your Secrets

Run locally:
```bash
./scripts/generate-secrets.sh
```

Or manually:
```bash
openssl rand -base64 32  # NEXTAUTH_SECRET
openssl rand -base64 24  # CALENDSO_ENCRYPTION_KEY  
openssl rand -base64 32  # CRON_API_KEY
```

### 3. Set Up Coolify

1. Create PostgreSQL database
2. Create new Docker Compose application
3. Point to your Cal.com repository
4. Add environment variables
5. Configure domain
6. Deploy!

## 📋 Minimum Requirements

### Server
- **CPU**: 2 cores (minimum 1 core)
- **RAM**: 4GB (minimum 2GB)
- **Disk**: 20GB
- **OS**: Any Linux with Docker support

### External Services
- **PostgreSQL 13+** (17 or 15+ recommended, can be hosted in Coolify)
- **SMTP Server** (Gmail, SendGrid, etc.)
- **Domain Name** (pointed to your VPS)

### Time Investment
- **Initial Setup**: 15-30 minutes
- **First Build**: 10-15 minutes
- **Total**: ~30-45 minutes

## 🔑 Required Environment Variables

These are the **absolute minimum** to get Cal.com running:

```bash
# URLs
NEXT_PUBLIC_WEBAPP_URL=https://your-domain.com
NEXT_PUBLIC_WEBSITE_URL=https://your-domain.com
NEXTAUTH_URL=https://your-domain.com/api/auth

# Security (generate these!)
NEXTAUTH_SECRET=<generated-secret>
CALENDSO_ENCRYPTION_KEY=<generated-key>
CRON_API_KEY=<generated-key>

# Database
DATABASE_URL=postgresql://user:pass@host:5432/calcom

# Email
EMAIL_FROM=notifications@your-domain.com
EMAIL_SERVER_HOST=smtp.provider.com
EMAIL_SERVER_PORT=587
EMAIL_SERVER_USER=username
EMAIL_SERVER_PASSWORD=password

# Settings
CRON_ENABLE_APP_SYNC=true
CALCOM_TELEMETRY_DISABLED=1
NODE_ENV=production
```

See `.env.coolify.example` for all optional variables.

## 🎯 Deployment Options

### Option 1: Coolify (Recommended)
- ✅ Easiest to use
- ✅ Automatic SSL
- ✅ Built-in monitoring
- ✅ One-click deployments
- ✅ Web UI management

**Guide**: `COOLIFY-QUICKSTART.md`

### Option 2: Docker Compose
- ✅ Full control
- ✅ Works on any Docker host
- ✅ Easy to customize
- ⚠️ Manual SSL setup
- ⚠️ Manual monitoring

**Guide**: `DOCKER-README.md`

### Option 3: Standalone Docker
- ✅ Maximum flexibility
- ✅ Minimal overhead
- ⚠️ More complex setup
- ⚠️ Manual database management

**Guide**: `DEPLOYMENT.md` → Docker section

## 📊 What You're Deploying

Cal.com includes these features out of the box:

### Core Features
- ✅ Calendar scheduling
- ✅ Event types with custom durations
- ✅ Team scheduling
- ✅ Multiple calendar integrations
- ✅ Custom booking questions
- ✅ Email notifications
- ✅ SMS reminders (with Twilio)
- ✅ Multi-language support (30+ languages)
- ✅ Time zone support
- ✅ Availability management

### Integrations (Optional)
- 📅 Google Calendar
- 📅 Microsoft 365 / Outlook
- 📅 Apple Calendar
- 🎥 Zoom
- 🎥 Google Meet
- 🎥 Microsoft Teams
- 🎥 Daily.co
- 💳 Stripe payments
- 📧 SendGrid
- 📱 Twilio SMS
- 🔗 Zapier
- 🔗 Webhooks

### Advanced Features
- 🔒 SSO (SAML/OIDC)
- 👥 Organizations
- 📊 Analytics & Insights
- 🔄 Workflows & Automations
- 🎨 White-label/Branding
- 🌐 Embed bookings on your website

## 🔐 Security Checklist

Before going live:

- [ ] Generate strong, unique secrets
- [ ] Use HTTPS (Coolify handles this)
- [ ] Set strong database password
- [ ] Configure firewall rules
- [ ] Enable database backups
- [ ] Set `CALCOM_TELEMETRY_DISABLED=1`
- [ ] Optionally set `NEXT_PUBLIC_DISABLE_SIGNUP=1`
- [ ] Review and set `RESERVED_SUBDOMAINS`
- [ ] Configure `IP_BANLIST` if needed
- [ ] Keep system and packages updated

## 🆘 Getting Help

### Documentation
1. **Quick Start**: `COOLIFY-QUICKSTART.md`
2. **Full Guide**: `DEPLOYMENT.md`
3. **Docker Info**: `DOCKER-README.md`
4. **Environment Vars**: `.env.coolify.example`

### Community Support
- 💬 [Cal.com Discord](https://discord.gg/calcom)
- 💬 [Coolify Discord](https://discord.gg/coolify)
- 🐛 [GitHub Issues](https://github.com/calcom/cal.com/issues)
- 📖 [Official Docs](https://cal.com/docs)

### Troubleshooting
See the **Troubleshooting** section in:
- `COOLIFY-QUICKSTART.md` for common quick fixes
- `DEPLOYMENT.md` for detailed debugging
- `DOCKER-README.md` for Docker-specific issues

## 📈 After Deployment

### Verify Installation
1. Visit your domain
2. Check health: `https://your-domain.com/api/version`
3. Create first user
4. Configure event types
5. Test booking flow

### Configure Integrations
1. **Email**: Test email delivery
2. **Calendars**: Connect your calendar
3. **Video**: Set up Zoom or other providers
4. **Payments**: Configure Stripe (if needed)

### Optimize Performance
1. **Monitoring**: Set up Sentry or similar
2. **Backups**: Configure automated database backups
3. **Caching**: Consider adding Redis for better performance
4. **CDN**: Use a CDN for static assets (optional)

### Maintain Your Instance
1. **Updates**: Redeploy regularly for security patches
2. **Backups**: Test backup restoration
3. **Monitoring**: Check logs periodically
4. **Database**: Monitor database size and performance

## 🎉 You're Ready!

Everything you need is now in this repository:

```
cal/
├── Dockerfile                      # Docker image definition
├── docker-compose.coolify.yml      # Complete stack
├── .dockerignore                   # Build optimization
├── COOLIFY-QUICKSTART.md          # ⭐ START HERE
├── DEPLOYMENT.md                   # Full guide
├── DOCKER-README.md               # Docker reference
├── .env.coolify.example           # Environment template
└── scripts/
    └── generate-secrets.sh        # Secret generator
```

**Start with**: `COOLIFY-QUICKSTART.md` for the fastest path to deployment.

## 💡 Pro Tips

1. **Test locally first** using Docker Compose
2. **Start minimal** - add integrations later
3. **Document your setup** - save your environment variables securely
4. **Monitor from day one** - set up logging/monitoring early
5. **Backup regularly** - automate database backups
6. **Update safely** - test updates in staging first

## 📝 License

Cal.com is licensed under AGPLv3:
- ✅ Free for self-hosting (commercial use allowed)
- ✅ Can modify and distribute
- ✅ Must keep source open if distributed
- ⚠️ Enterprise features require commercial license

See [LICENSE](./LICENSE) and [PERMISSIONS.md](./PERMISSIONS.md) for details.

---

## 🚀 Ready to Deploy?

1. Open `COOLIFY-QUICKSTART.md`
2. Follow the 5 steps
3. Deploy in 15 minutes!

**Good luck with your Cal.com deployment! 🎊**

If you need help, the community is here to support you. Don't hesitate to ask questions!

