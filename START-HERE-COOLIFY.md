# 🎯 START HERE - Deploy Cal.com to Coolify

## 🚀 Quick Navigation

This repository is now fully configured for Coolify deployment!

### Choose Your Path:

1. **I want to deploy quickly (15 min)** → [`COOLIFY-QUICKSTART.md`](./COOLIFY-QUICKSTART.md)
   - 5 simple steps
   - Copy-paste ready
   - Perfect for getting started

2. **I want comprehensive documentation** → [`DEPLOYMENT.md`](./DEPLOYMENT.md)
   - Detailed explanations
   - All configuration options
   - Troubleshooting guide
   - Integration setup

3. **I need Docker information** → [`DOCKER-README.md`](./DOCKER-README.md)
   - Docker commands reference
   - Docker Compose usage
   - Performance tuning
   - Resource requirements

4. **I want to see what was created** → [`DEPLOYMENT-SUMMARY.md`](./DEPLOYMENT-SUMMARY.md)
   - Complete file list
   - Overview of all features
   - Deployment options comparison
   - Security checklist

## 📦 What You Have

Your repository now includes:

```
✅ Dockerfile                    # Production-ready Docker image
✅ docker-compose.coolify.yml    # Complete stack with PostgreSQL
✅ .dockerignore                 # Build optimization
✅ .env.coolify.example          # All environment variables
✅ scripts/generate-secrets.sh   # Security key generator
✅ Complete documentation        # 4 comprehensive guides
```

## ⚡ Super Quick Start

### 1. Generate Secrets
```bash
./scripts/generate-secrets.sh
```

### 2. Copy Environment Template
```bash
cp .env.coolify.example .env
# Edit .env with your values
```

### 3. Deploy to Coolify
1. Create PostgreSQL database in Coolify
2. Create new Docker Compose application
3. Point to this repository
4. Add environment variables from `.env`
5. Add your domain
6. Click **Deploy**

### 4. Initialize Database
Open terminal in Coolify container:
```bash
yarn workspace @calcom/prisma db-deploy
```

### 5. Access Cal.com
Visit `https://your-domain.com` 🎉

## 🔑 Required Before Deploying

1. **Domain name** pointing to your VPS
2. **PostgreSQL database** (create in Coolify)
3. **SMTP credentials** (Gmail, SendGrid, etc.)
4. **Generated secrets** (run `./scripts/generate-secrets.sh`)

## 📚 Recommended Reading Order

1. **First time deploying Cal.com?**
   → Start with `COOLIFY-QUICKSTART.md`

2. **Want to understand everything?**
   → Read `DEPLOYMENT.md` after quick start

3. **Having Docker issues?**
   → Check `DOCKER-README.md`

4. **Just want an overview?**
   → See `DEPLOYMENT-SUMMARY.md`

## 🆘 Need Help?

### Quick Troubleshooting
- **Container won't start**: Check environment variables
- **Database errors**: Verify DATABASE_URL format
- **Email not working**: Check SMTP credentials
- **Build fails**: Increase memory to 4GB+

### Get Support
- 💬 [Cal.com Discord](https://discord.gg/calcom)
- 💬 [Coolify Discord](https://discord.gg/coolify)
- 📖 [Cal.com Docs](https://cal.com/docs)
- 🐛 [GitHub Issues](https://github.com/calcom/cal.com/issues)

## 💡 Pro Tips

1. **Test locally first** with Docker Compose
2. **Start with minimal config** - add features later
3. **Save your environment variables** securely
4. **Enable backups** from day one
5. **Monitor your logs** in Coolify

## 🎊 Ready?

**[Click here to get started → COOLIFY-QUICKSTART.md](./COOLIFY-QUICKSTART.md)**

---

Made with ❤️ for the Cal.com community

Questions? Open an issue or ask in Discord!

