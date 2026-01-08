# Dokploy Deployment Setup Guide

This guide explains how to deploy Cal.com to Dokploy with the correct build arguments.

## Required Build Arguments

The Dockerfile requires the following build arguments to be set during the build process:

### Required (Must be set)
- `NEXTAUTH_SECRET` - Secret for NextAuth.js session encryption
- `CALENDSO_ENCRYPTION_KEY` - Encryption key for Cal.com
- `DATABASE_URL` - PostgreSQL database connection string
- `NEXT_PUBLIC_WEBAPP_URL` - Your Cal.com application URL (e.g., `https://cal.yourdomain.com`)

### Optional
- `NEXT_PUBLIC_WEBSITE_URL` - Your website URL (if different from webapp URL)
- `EMAIL_FROM` - Email address for sending emails
- `EMAIL_SERVER_HOST` - SMTP server hostname
- `EMAIL_SERVER_PORT` - SMTP server port
- `EMAIL_SERVER_USER` - SMTP username
- `EMAIL_SERVER_PASSWORD` - SMTP password

## Setting Build Arguments in Dokploy

### ⚠️ Important: Build Arguments vs Environment Variables

Dokploy has two separate concepts:
- **Environment Variables**: Available at runtime (when container runs)
- **Build Arguments**: Available during Docker build (when image is built)

**You need to set these as BUILD ARGUMENTS, not just environment variables!**

### Method 1: Build Arguments (Required)

In Dokploy, you need to configure these in the **Build Arguments** or **Docker Build Args** section:

1. Go to your project in Dokploy
2. Navigate to **Build Settings** or **Dockerfile Settings**
3. Look for **"Build Arguments"**, **"Docker Build Args"**, or **"Build-time Variables"**
4. Add the following build arguments:

```
NEXTAUTH_SECRET=your-secret-here
CALENDSO_ENCRYPTION_KEY=your-encryption-key-here
DATABASE_URL=postgresql://user:password@host:5432/database
NEXT_PUBLIC_WEBAPP_URL=https://cal.yourdomain.com
```

### Method 2: If Dokploy Auto-Passes Environment Variables

Some Dokploy configurations automatically pass environment variables as build arguments. If your Dokploy setup does this:

1. Go to **Environment Variables** section
2. Ensure these variables are set:
   - `NEXTAUTH_SECRET`
   - `CALENDSO_ENCRYPTION_KEY`
   - `DATABASE_URL`
   - `NEXT_PUBLIC_WEBAPP_URL`
3. Check if there's a toggle like **"Available during build"** or **"Pass as build arg"** and enable it

### Method 3: Manual Dockerfile Build Args (Advanced)

If Dokploy allows custom Docker build commands, you can specify:

```bash
docker build \
  --build-arg NEXTAUTH_SECRET=your-secret \
  --build-arg CALENDSO_ENCRYPTION_KEY=your-key \
  --build-arg DATABASE_URL=postgresql://... \
  --build-arg NEXT_PUBLIC_WEBAPP_URL=https://... \
  -t your-image .
```

## Generating Secrets

### Generate NEXTAUTH_SECRET
```bash
openssl rand -base64 32
```

### Generate CALENDSO_ENCRYPTION_KEY
```bash
openssl rand -base64 32
```

## Database Setup

Make sure your PostgreSQL database is:
1. Created and accessible
2. Connection string is in the format: `postgresql://user:password@host:port/database`
3. Database user has proper permissions

## Runtime Environment Variables

In addition to build arguments, you'll also need these at runtime (set in Dokploy's environment variables):

### Required Runtime Variables
- `NEXTAUTH_SECRET` (same as build arg)
- `CALENDSO_ENCRYPTION_KEY` (same as build arg)
- `DATABASE_URL` (same as build arg) - **Must be accessible from container network**
- `NEXT_PUBLIC_WEBAPP_URL` (same as build arg) - Your full Cal.com URL, e.g., `https://meet.ai-in-action.de`

### Important: ALLOWED_HOSTNAMES

**This is critical for organization support!** Set this to your base domain (without subdomain):

If your `NEXT_PUBLIC_WEBAPP_URL` is `https://meet.ai-in-action.de`, then:
```
ALLOWED_HOSTNAMES=ai-in-action.de
```
or (lowercase variant):
```
allowed_hostnames=ai-in-action.de
```

If you're using multiple domains (comma-separated, no spaces needed):
```
ALLOWED_HOSTNAMES=ai-in-action.de,another-domain.com
```

**Format:** Comma-separated list of base domains (no quotes needed)
**Note:** Both `ALLOWED_HOSTNAMES` (uppercase) and `allowed_hostnames` (lowercase) are supported. Uppercase takes precedence if both are set.
**Without this, you'll see warnings: "Match of WEBAPP_URL with ALLOWED_HOSTNAMES failed"**

### Other Common Runtime Variables
- `NEXT_PUBLIC_WEBSITE_URL` - Your website URL (if different from webapp)
- `EMAIL_FROM`, `EMAIL_SERVER_HOST`, etc. - For email functionality
- Any other Cal.com environment variables from `.env.example`

## Troubleshooting

### Error: "Please set NEXTAUTH_SECRET" or "NEXTAUTH_SECRET is required but not set"

**This is the most common issue!** It means Dokploy has the variables set, but they're not being passed as build arguments.

**Solution:**
1. **Check Dokploy Build Settings**: Look for a "Build Arguments" or "Docker Build Args" section (separate from Environment Variables)
2. **Check if Dokploy auto-passes env vars**: Some Dokploy versions have a setting like "Pass environment variables as build arguments" - enable it
3. **Verify in build logs**: Check the Docker build command in Dokploy logs. You should see `--build-arg NEXTAUTH_SECRET=...` in the command
4. **Manual configuration**: If Dokploy doesn't auto-pass, you may need to manually configure build arguments in the Dockerfile/build settings

### Variables are set but build still fails

If you've set the variables in Dokploy but the build fails:

1. **Check variable names**: They must match exactly (case-sensitive):
   - `NEXTAUTH_SECRET` (not `NEXTAUTH_SECRET_KEY` or `NEXT_AUTH_SECRET`)
   - `CALENDSO_ENCRYPTION_KEY` (not `ENCRYPTION_KEY`)
   - `DATABASE_URL` (not `DB_URL` or `POSTGRES_URL`)
   - `NEXT_PUBLIC_WEBAPP_URL` (not `WEBAPP_URL`)

2. **Check if they're runtime-only**: Some platforms separate "Build-time" and "Runtime" variables. Make sure they're set for build-time.

3. **Check Dokploy version**: Newer versions of Dokploy may handle this differently. Check Dokploy documentation for your version.

### Build Fails with Validation Error

The Dockerfile now validates required arguments early. If you see:
```
❌ ERROR: NEXTAUTH_SECRET is required but not set
Configure it as a BUILD ARGUMENT in Dokploy settings
```

This means:
- The variable exists in Dokploy but isn't being passed to Docker build
- You need to configure it as a **build argument**, not just an environment variable
- Check Dokploy's build configuration section

### Database Connection Issues (P1001 Error)

If you see Prisma error `P1001` (Can't reach database server):

1. **Verify DATABASE_URL format**: Should be `postgresql://user:password@host:port/database`
   - If database is in same Docker network, use service name as host
   - If external database, use IP or domain name
   - Check if port is correct (default: 5432)

2. **Network connectivity**:
   - If database is in Dokploy, ensure it's on the same network
   - If external database, check firewall rules allow connections from Dokploy
   - Test connection from Dokploy container: `docker exec -it <container> nc -zv <db-host> 5432`

3. **Database credentials**:
   - Verify username and password are correct
   - Check database user has proper permissions
   - Ensure database exists

4. **SSL/TLS**:
   - If database requires SSL, add `?sslmode=require` to connection string
   - Example: `postgresql://user:pass@host:5432/db?sslmode=require`

5. **Connection pooling**:
   - For some setups, you may need `DATABASE_DIRECT_URL` (same as DATABASE_URL)
   - Some setups require separate read/write URLs

### ALLOWED_HOSTNAMES Warning

If you see: `"Match of WEBAPP_URL with ALLOWED_HOSTNAMES failed"`

**Solution**: Set `ALLOWED_HOSTNAMES` environment variable to your base domain:

```
ALLOWED_HOSTNAMES=ai-in-action.de
```

- Extract the base domain from your `NEXT_PUBLIC_WEBAPP_URL`
- If `NEXT_PUBLIC_WEBAPP_URL=https://meet.ai-in-action.de`, then `ALLOWED_HOSTNAMES=ai-in-action.de`
- If using multiple domains, use comma-separated: `ALLOWED_HOSTNAMES=domain1.com,domain2.com`

## Example Dokploy Configuration

Here's a complete example of environment variables to set in Dokploy:

```env
# Required Build Arguments
NEXTAUTH_SECRET=your-generated-secret-here-min-32-chars
CALENDSO_ENCRYPTION_KEY=your-generated-encryption-key-here-min-32-chars
DATABASE_URL=postgresql://calcom:password@postgres:5432/calcom
NEXT_PUBLIC_WEBAPP_URL=https://cal.yourdomain.com

# Optional
NEXT_PUBLIC_WEBSITE_URL=https://yourdomain.com
EMAIL_FROM=noreply@yourdomain.com
EMAIL_SERVER_HOST=smtp.gmail.com
EMAIL_SERVER_PORT=587
EMAIL_SERVER_USER=your-email@gmail.com
EMAIL_SERVER_PASSWORD=your-app-password
```

## After Deployment

1. Run database migrations:
   ```bash
   yarn workspace @calcom/prisma db-migrate
   ```

2. Seed the database (optional):
   ```bash
   yarn workspace @calcom/prisma db-seed
   ```

3. Verify the deployment by visiting `NEXT_PUBLIC_WEBAPP_URL`

## Need Help?

- Check Dokploy documentation for build argument configuration
- Review Cal.com deployment docs: https://cal.com/docs/self-hosting
- Check build logs in Dokploy for specific error messages

