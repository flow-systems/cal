# 🐳 Cal.com Docker Deployment

This directory contains everything needed to deploy Cal.com using Docker on Coolify or any Docker-compatible platform.

## 📁 Files Overview

| File | Description |
|------|-------------|
| `Dockerfile` | Multi-stage production-optimized Docker image |
| `docker-compose.coolify.yml` | Complete Docker Compose with PostgreSQL |
| `.dockerignore` | Excludes unnecessary files from Docker build |
| `COOLIFY-QUICKSTART.md` | ⭐ **START HERE** - Quick deployment guide |
| `DEPLOYMENT.md` | Comprehensive deployment documentation |
| `.env.coolify.example` | All environment variables with descriptions |
| `scripts/generate-secrets.sh` | Generate secure random keys |

## 🚀 Quick Start

### For Coolify Users (Recommended)

**Read this first**: [`COOLIFY-QUICKSTART.md`](./COOLIFY-QUICKSTART.md)

It's a 5-step guide that gets you running in 15 minutes!

### For Docker Compose

1. **Generate secrets:**
   ```bash
   ./scripts/generate-secrets.sh
   ```

2. **Create `.env` file:**
   ```bash
   cp .env.coolify.example .env
   # Edit .env with your values
   ```

3. **Start services:**
   ```bash
   docker-compose -f docker-compose.coolify.yml up -d
   ```

4. **Initialize database:**
   ```bash
   docker-compose exec calcom yarn workspace @calcom/prisma db-deploy
   ```

5. **Access:** `http://localhost:3000`

### For Standalone Docker

1. **Build image:**
   ```bash
   docker build -t calcom:latest .
   ```

2. **Run container:**
   ```bash
   docker run -d \
     -p 3000:3000 \
     -e DATABASE_URL="postgresql://..." \
     -e NEXTAUTH_SECRET="..." \
     -e CALENDSO_ENCRYPTION_KEY="..." \
     -e NEXT_PUBLIC_WEBAPP_URL="https://your-domain.com" \
     # ... add other required env vars
     calcom:latest
   ```

## 📋 Minimum Required Environment Variables

```bash
DATABASE_URL=postgresql://user:pass@host:5432/calcom
NEXTAUTH_SECRET=<generate with: openssl rand -base64 32>
CALENDSO_ENCRYPTION_KEY=<generate with: openssl rand -base64 24>
NEXT_PUBLIC_WEBAPP_URL=https://your-domain.com
NEXT_PUBLIC_WEBSITE_URL=https://your-domain.com
NEXTAUTH_URL=https://your-domain.com/api/auth
EMAIL_FROM=notifications@your-domain.com
EMAIL_SERVER_HOST=smtp.provider.com
EMAIL_SERVER_PORT=587
EMAIL_SERVER_USER=username
EMAIL_SERVER_PASSWORD=password
CRON_API_KEY=<generate with: openssl rand -base64 32>
```

See `.env.coolify.example` for complete list with descriptions.

## 🏗️ Docker Image Details

### Build Stages

1. **deps**: Installs Node.js dependencies
2. **builder**: Builds the application with optimizations
3. **runner**: Minimal production image (~800MB)

### Features

- ✅ Multi-stage build for smaller image size
- ✅ Non-root user for security
- ✅ Health check endpoint
- ✅ Optimized layer caching
- ✅ Production-ready configuration
- ✅ Signal handling with dumb-init

### Exposed Ports

- `3000` - HTTP server (web application)

### Health Check

Endpoint: `http://localhost:3000/api/version`
- Interval: 30 seconds
- Timeout: 10 seconds
- Retries: 3

## 🔧 Common Docker Commands

```bash
# Build image
docker build -t calcom:latest .

# Run container
docker run -d -p 3000:3000 --env-file .env calcom:latest

# View logs
docker logs -f <container-id>

# Execute commands in container
docker exec -it <container-id> sh

# Run database migrations
docker exec <container-id> yarn workspace @calcom/prisma db-deploy

# Stop container
docker stop <container-id>

# Remove container
docker rm <container-id>
```

## 🐳 Docker Compose Commands

```bash
# Start services
docker-compose -f docker-compose.coolify.yml up -d

# View logs
docker-compose -f docker-compose.coolify.yml logs -f

# Stop services
docker-compose -f docker-compose.coolify.yml down

# Rebuild and restart
docker-compose -f docker-compose.coolify.yml up -d --build

# Execute command in calcom service
docker-compose -f docker-compose.coolify.yml exec calcom sh
```

## 📊 Resource Requirements

### Minimum Requirements

- **CPU**: 1 core
- **RAM**: 2GB
- **Disk**: 10GB
- **Database**: PostgreSQL 13+

### Recommended for Production

- **CPU**: 2+ cores
- **RAM**: 4GB+
- **Disk**: 20GB+ (with backups)
- **Database**: PostgreSQL 15+ with backups

## 🔐 Security Considerations

1. **Never use default secrets** - Always generate new ones
2. **Use HTTPS** - Configure SSL/TLS (Coolify does this automatically)
3. **Strong database password** - Use long random passwords
4. **Firewall rules** - Only expose necessary ports
5. **Regular updates** - Keep Cal.com and dependencies updated
6. **Backup database** - Regular automated backups
7. **Monitor logs** - Watch for suspicious activity
8. **Disable telemetry** - Set `CALCOM_TELEMETRY_DISABLED=1`

## 🚨 Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs <container-id>

# Common issues:
# - Missing environment variables
# - Invalid DATABASE_URL
# - Port 3000 already in use
```

### Database Connection Failed

```bash
# Test database connection
docker exec <container-id> psql $DATABASE_URL -c "SELECT 1"

# Common issues:
# - Incorrect DATABASE_URL format
# - Database not accessible from container
# - SSL mode misconfigured
```

### Build Fails

```bash
# Clean build cache
docker builder prune

# Build with no cache
docker build --no-cache -t calcom:latest .

# Common issues:
# - Insufficient memory (need 4GB+)
# - Network issues during yarn install
# - Missing source files
```

### Out of Memory

```bash
# Increase Docker memory limit
# Docker Desktop: Settings → Resources → Memory

# Or use build args
docker build --memory=4g --memory-swap=8g -t calcom:latest .
```

## 📈 Performance Optimization

### Use Redis for Caching

Add to environment variables:
```bash
UPSTASH_REDIS_REST_URL=https://your-redis.upstash.io
UPSTASH_REDIS_REST_TOKEN=your-token
```

### Database Connection Pooling

Configure in DATABASE_URL:
```bash
DATABASE_URL=postgresql://user:pass@host:5432/calcom?connection_limit=10&pool_timeout=60
```

### Enable Build Cache

Create `.dockercache/` directory for persistent build cache:
```bash
mkdir -p .dockercache
docker build --cache-from calcom:latest -t calcom:latest .
```

## 🔄 Updating Cal.com

### Method 1: Rebuild Image

```bash
# Pull latest code
git pull origin main

# Rebuild and restart
docker-compose -f docker-compose.coolify.yml up -d --build
```

### Method 2: Use New Image Tag

```bash
# Build with version tag
docker build -t calcom:v1.0.1 .

# Update docker-compose to use new tag
# Then restart services
```

### Don't Forget Database Migrations!

```bash
docker exec <container-id> yarn workspace @calcom/prisma db-deploy
```

## 📚 Additional Resources

- **Cal.com Documentation**: https://cal.com/docs
- **Docker Documentation**: https://docs.docker.com
- **Coolify Documentation**: https://coolify.io/docs
- **PostgreSQL Docker**: https://hub.docker.com/_/postgres
- **Node.js Best Practices**: https://github.com/goldbergyoni/nodebestpractices

## 🆘 Getting Help

1. **Check logs first**: `docker logs <container-id>`
2. **Read documentation**: `DEPLOYMENT.md` and `COOLIFY-QUICKSTART.md`
3. **Cal.com Discord**: https://discord.gg/calcom
4. **GitHub Issues**: https://github.com/calcom/cal.com/issues
5. **Coolify Discord**: https://discord.gg/coolify

## 📝 License

Cal.com is licensed under AGPLv3. Enterprise features require a commercial license.

See [LICENSE](./LICENSE) for more information.

---

**Happy Deploying! 🚀**

If you found this helpful, consider starring the repo and contributing back to the community!

