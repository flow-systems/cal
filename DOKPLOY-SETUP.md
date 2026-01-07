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

### Method 1: Environment Variables (Recommended)

In your Dokploy project settings, add these as **Environment Variables**. Dokploy will automatically pass them as build arguments:

1. Go to your project in Dokploy
2. Navigate to **Environment Variables** or **Build Settings**
3. Add the following variables:

```
NEXTAUTH_SECRET=your-secret-here
CALENDSO_ENCRYPTION_KEY=your-encryption-key-here
DATABASE_URL=postgresql://user:password@host:5432/database
NEXT_PUBLIC_WEBAPP_URL=https://cal.yourdomain.com
```

### Method 2: Build Arguments

If Dokploy has a specific "Build Arguments" section:

1. Go to **Build Settings** or **Dockerfile Settings**
2. Add build arguments:

```
--build-arg NEXTAUTH_SECRET=your-secret-here
--build-arg CALENDSO_ENCRYPTION_KEY=your-encryption-key-here
--build-arg DATABASE_URL=postgresql://user:password@host:5432/database
--build-arg NEXT_PUBLIC_WEBAPP_URL=https://cal.yourdomain.com
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

- `NEXTAUTH_SECRET` (same as build arg)
- `CALENDSO_ENCRYPTION_KEY` (same as build arg)
- `DATABASE_URL` (same as build arg)
- `NEXT_PUBLIC_WEBAPP_URL` (same as build arg)
- Any other Cal.com environment variables from `.env.example`

## Troubleshooting

### Error: "Please set NEXTAUTH_SECRET"

This means the build argument wasn't passed. Check:
1. Environment variables are set in Dokploy project settings
2. Variables are marked as "Available during build" if Dokploy has that option
3. Variable names match exactly (case-sensitive)

### Build Fails with Validation Error

The Dockerfile now validates required arguments early. If you see:
```
ERROR: NEXTAUTH_SECRET environment variable is required but not set
```

This means Dokploy isn't passing the variable as a build argument. Ensure:
1. Variable is set in Dokploy project settings
2. Variable is available during build phase (not just runtime)
3. Check Dokploy logs for the actual build command being used

### Database Connection Issues

If the build succeeds but runtime fails with database errors:
1. Verify `DATABASE_URL` is correct
2. Check database is accessible from Dokploy's network
3. Ensure database user has proper permissions
4. Check if database requires SSL (add `?sslmode=require` to connection string)

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

