# Deploying Cal.com to Coolify

This guide will help you deploy Cal.com to your VPS using Coolify.

## Prerequisites

1. **Coolify installed** on your VPS
2. **PostgreSQL database** (can be created in Coolify)
3. **Domain name** pointed to your VPS
4. **SMTP server** for email notifications (optional but recommended)

## Quick Start with Coolify

### Step 1: Create a New Resource in Coolify

1. Log into your Coolify dashboard
2. Click **+ New Resource**
3. Select **Docker Compose**
4. Choose your server and destination

### Step 2: Configure the Application

1. **Repository Setup:**
   - If using Git: Enter your repository URL
   - If using local files: Use the file upload feature

2. **Docker Configuration:**
   - Use the `docker-compose.coolify.yml` file from this repository
   - Or point to the `Dockerfile` for a simpler setup

### Step 3: Create PostgreSQL Database

If you don't have a database yet:

1. In Coolify, click **+ New Resource** → **Database** → **PostgreSQL**
2. Choose PostgreSQL 17 (or 15+)
3. Note the connection details (host, port, username, password, database name)
4. Construct your `DATABASE_URL`:
   ```
   postgresql://username:password@postgres-host:5432/database_name?sslmode=require
   ```

### Step 4: Configure Environment Variables

In Coolify's environment variables section, add the following (refer to `.env.coolify.example` for complete list):

#### Required Variables

```bash
# Application URLs
NEXT_PUBLIC_WEBAPP_URL=https://your-domain.com
NEXT_PUBLIC_WEBSITE_URL=https://your-domain.com
NEXTAUTH_URL=https://your-domain.com/api/auth

# Security Keys (generate these!)
NEXTAUTH_SECRET=run_openssl_rand_base64_32_to_generate
CALENDSO_ENCRYPTION_KEY=run_openssl_rand_base64_24_to_generate
CRON_API_KEY=run_openssl_rand_base64_32_to_generate

# Database
DATABASE_URL=postgresql://user:pass@host:5432/calcom?sslmode=require

# Email (required for user registration and notifications)
EMAIL_FROM=notifications@your-domain.com
EMAIL_FROM_NAME=Cal.com
EMAIL_SERVER_HOST=smtp.your-provider.com
EMAIL_SERVER_PORT=587
EMAIL_SERVER_USER=your-smtp-username
EMAIL_SERVER_PASSWORD=your-smtp-password

# Cron Jobs
CRON_ENABLE_APP_SYNC=true

# Disable telemetry for self-hosted
CALCOM_TELEMETRY_DISABLED=1
```

#### Generate Security Keys

Run these commands on your local machine or VPS:

```bash
# Generate NEXTAUTH_SECRET (32 bytes)
openssl rand -base64 32

# Generate CALENDSO_ENCRYPTION_KEY (24 bytes for 32-character base64)
openssl rand -base64 24

# Generate CRON_API_KEY (32 bytes)
openssl rand -base64 32
```

### Step 5: Configure Domain

1. In Coolify, go to your application settings
2. Under **Domains**, add your domain: `your-domain.com`
3. Enable **HTTPS** (Coolify will automatically provision SSL via Let's Encrypt)
4. Save changes

### Step 6: Deploy

1. Click **Deploy** in Coolify
2. Wait for the build to complete (this may take 10-15 minutes on first deploy)
3. Monitor the logs for any errors

### Step 7: Initialize the Database

After first deployment, you need to run database migrations:

1. Go to your application in Coolify
2. Open the **Terminal** for your container
3. Run these commands:

```bash
# Run database migrations
yarn workspace @calcom/prisma db-deploy

# (Optional) Seed with example data
yarn workspace @calcom/prisma db-seed
```

### Step 8: Create Your First User

Option 1: Via Database Studio (if accessible)
```bash
yarn db-studio
```

Option 2: Via Direct Database Access
- Log into your PostgreSQL database
- Create a user with encrypted password (use BCrypt)

Option 3: Enable Signup
- Set `NEXT_PUBLIC_DISABLE_SIGNUP=0` in environment variables
- Go to `https://your-domain.com/signup`

## Configuration Options

### Email Providers

#### SendGrid
```bash
SENDGRID_API_KEY=SG.xxxxx
SENDGRID_EMAIL=notifications@your-domain.com
```

#### Generic SMTP
```bash
EMAIL_SERVER_HOST=smtp.gmail.com  # or your SMTP server
EMAIL_SERVER_PORT=587
EMAIL_SERVER_USER=your-email@gmail.com
EMAIL_SERVER_PASSWORD=your-app-password
```

### Calendar Integrations

#### Google Calendar
1. Get credentials from [Google Cloud Console](https://console.cloud.google.com)
2. Add to environment:
```bash
GOOGLE_API_CREDENTIALS='{"web":{"client_id":"...","client_secret":"...","redirect_uris":["https://your-domain.com/api/integrations/googlecalendar/callback"]}}'
GOOGLE_LOGIN_ENABLED=true
```

#### Microsoft 365
1. Get credentials from [Azure Portal](https://portal.azure.com)
2. Add to environment:
```bash
MS_GRAPH_CLIENT_ID=your-client-id
MS_GRAPH_CLIENT_SECRET=your-client-secret
```

### Video Conferencing

#### Zoom
```bash
ZOOM_CLIENT_ID=your-zoom-client-id
ZOOM_CLIENT_SECRET=your-zoom-client-secret
```

#### Daily.co
```bash
DAILY_API_KEY=your-daily-api-key
DAILY_SCALE_PLAN=false  # Set to true if you have scale plan
```

### Payment Processing

#### Stripe
```bash
NEXT_PUBLIC_STRIPE_PUBLIC_KEY=pk_live_...
STRIPE_PRIVATE_KEY=sk_live_...
STRIPE_CLIENT_ID=ca_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

## Updating Your Deployment

### Option 1: Via Coolify UI
1. Go to your application in Coolify
2. Click **Redeploy**
3. Wait for the new image to build and deploy

### Option 2: Automatic Deployments
1. In Coolify, enable **Auto Deploy** under **General** settings
2. Set up a webhook from your Git repository
3. Coolify will automatically deploy on each push

## Health Checks

The Docker container includes a health check on `/api/version`. Coolify will automatically monitor this endpoint.

You can manually check health:
```bash
curl https://your-domain.com/api/version
```

## Troubleshooting

### Application won't start
- Check environment variables are set correctly
- Verify DATABASE_URL is correct and database is accessible
- Check logs in Coolify: Application → Logs

### Database connection errors
- Verify PostgreSQL is running
- Check DATABASE_URL format
- Ensure database exists: `?sslmode=require` or `?sslmode=disable` depending on setup

### Email not working
- Verify SMTP credentials
- Check EMAIL_SERVER_* variables
- Test SMTP connection manually

### Build fails
- Increase memory limit in Coolify if needed
- Check Docker build logs for specific errors
- Ensure all required files are present in repository

### Cannot access after deployment
- Verify domain DNS is pointing to your VPS
- Check Coolify proxy/traefik logs
- Ensure port 3000 is exposed in Docker configuration

## Performance Optimization

### For Production Use

1. **Use Redis for caching:**
```bash
UPSTASH_REDIS_REST_URL=https://your-redis-url.upstash.io
UPSTASH_REDIS_REST_TOKEN=your-redis-token
```

2. **Enable database connection pooling:**
```bash
DATABASE_URL=postgresql://user:pass@host:5432/calcom?sslmode=require&connection_limit=10&pool_timeout=60
```

3. **Configure resource limits in docker-compose:**
```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 4G
    reservations:
      memory: 2G
```

## Security Best Practices

1. **Use strong passwords** for DATABASE_URL
2. **Keep secrets secret** - never commit `.env` files
3. **Enable HTTPS** via Coolify's SSL feature
4. **Regularly update** by redeploying from latest code
5. **Backup database** regularly using Coolify's backup feature
6. **Restrict signups** if needed: `NEXT_PUBLIC_DISABLE_SIGNUP=1`
7. **Set up monitoring** with Sentry or similar

## Backup and Restore

### Backup Database
```bash
# Using Coolify's backup feature (recommended)
# Or manually:
pg_dump -h postgres-host -U username -d calcom > backup.sql
```

### Restore Database
```bash
psql -h postgres-host -U username -d calcom < backup.sql
```

## Support

- **Cal.com Documentation:** https://cal.com/docs
- **Coolify Documentation:** https://coolify.io/docs
- **Community Discord:** https://discord.gg/calcom
- **GitHub Issues:** https://github.com/calcom/cal.com/issues

## Resources

- [Cal.com Self-Hosting Guide](https://github.com/calcom/cal.com#self-hosting)
- [Coolify Documentation](https://coolify.io/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Next.js Deployment](https://nextjs.org/docs/deployment)

## License

Cal.com is licensed under AGPLv3. Enterprise features require a commercial license.
See [LICENSE](./LICENSE) for more information.

