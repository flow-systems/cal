# ✅ Cal.com Coolify Deployment Checklist

Use this checklist to ensure a successful deployment.

## Pre-Deployment Checklist

### Prerequisites
- [ ] Coolify installed and accessible on your VPS
- [ ] Domain name configured and pointing to VPS IP
- [ ] SMTP/email service credentials available
- [ ] At least 4GB RAM available on server
- [ ] At least 20GB disk space available

### Preparation
- [ ] Read `COOLIFY-QUICKSTART.md` or `DEPLOYMENT.md`
- [ ] Generated security keys using `./scripts/generate-secrets.sh`
- [ ] Saved generated keys securely (password manager recommended)
- [ ] Prepared SMTP server credentials
- [ ] Decided on initial configuration (which integrations to enable)

## Deployment Steps

### 1. Database Setup
- [ ] Created PostgreSQL 15 database in Coolify
- [ ] Saved database connection details
- [ ] Constructed `DATABASE_URL` connection string
- [ ] Tested database connectivity (optional but recommended)

### 2. Application Setup
- [ ] Created new Docker Compose application in Coolify
- [ ] Configured repository URL or uploaded code
- [ ] Selected correct branch (main/staging)
- [ ] Configured build settings (Dockerfile)

### 3. Environment Configuration
- [ ] Set `NEXT_PUBLIC_WEBAPP_URL` with your domain
- [ ] Set `NEXT_PUBLIC_WEBSITE_URL` with your domain
- [ ] Set `NEXTAUTH_URL` with `/api/auth` path
- [ ] Set `NEXTAUTH_SECRET` (generated secret)
- [ ] Set `CALENDSO_ENCRYPTION_KEY` (generated secret)
- [ ] Set `CRON_API_KEY` (generated secret)
- [ ] Set `DATABASE_URL` (PostgreSQL connection string)
- [ ] Set `EMAIL_FROM` (sender email address)
- [ ] Set `EMAIL_SERVER_HOST` (SMTP host)
- [ ] Set `EMAIL_SERVER_PORT` (usually 587)
- [ ] Set `EMAIL_SERVER_USER` (SMTP username)
- [ ] Set `EMAIL_SERVER_PASSWORD` (SMTP password)
- [ ] Set `CRON_ENABLE_APP_SYNC=true`
- [ ] Set `CALCOM_TELEMETRY_DISABLED=1`
- [ ] Set `NODE_ENV=production`

### 4. Domain & SSL
- [ ] Added custom domain in Coolify
- [ ] Enabled HTTPS/SSL certificate
- [ ] Verified DNS propagation (can take up to 48 hours)
- [ ] Confirmed Let's Encrypt certificate is active

### 5. Deployment
- [ ] Clicked Deploy button in Coolify
- [ ] Monitored build logs for errors
- [ ] Waited for deployment to complete (10-15 minutes first time)
- [ ] Verified container is running

### 6. Database Initialization
- [ ] Opened terminal in Coolify container
- [ ] Ran `yarn workspace @calcom/prisma db-deploy`
- [ ] Verified migrations completed successfully
- [ ] (Optional) Ran `yarn workspace @calcom/prisma db-seed` for test data

### 7. First Access
- [ ] Visited domain in browser
- [ ] Verified site loads without errors
- [ ] Checked `/api/version` endpoint returns version info
- [ ] Created first admin user account
- [ ] Logged in successfully

## Post-Deployment Verification

### Basic Functionality
- [ ] User registration/login works
- [ ] Can create event types
- [ ] Booking page displays correctly
- [ ] Can make a test booking
- [ ] Email notifications sent successfully
- [ ] Calendar integration page accessible (if configured)

### Security Checks
- [ ] HTTPS certificate is valid (padlock icon in browser)
- [ ] No security warnings in browser console
- [ ] Admin area requires authentication
- [ ] Password reset flow works
- [ ] 2FA setup available (if enabled)

### Performance Checks
- [ ] Page load time is acceptable (< 3 seconds)
- [ ] No JavaScript errors in console
- [ ] Images and static assets load correctly
- [ ] Booking flow completes smoothly
- [ ] Health check endpoint responding

## Optional Integrations Setup

### Email Provider (Enhanced)
- [ ] Configured SendGrid (alternative to SMTP)
- [ ] Set `SENDGRID_API_KEY`
- [ ] Set `SENDGRID_EMAIL`
- [ ] Verified email delivery

### Calendar Integrations
- [ ] Google Calendar
  - [ ] Created OAuth credentials
  - [ ] Set `GOOGLE_API_CREDENTIALS`
  - [ ] Set `GOOGLE_LOGIN_ENABLED=true`
  - [ ] Tested connection
- [ ] Microsoft 365
  - [ ] Created Azure app registration
  - [ ] Set `MS_GRAPH_CLIENT_ID`
  - [ ] Set `MS_GRAPH_CLIENT_SECRET`
  - [ ] Tested connection

### Video Conferencing
- [ ] Zoom
  - [ ] Created Zoom app
  - [ ] Set `ZOOM_CLIENT_ID`
  - [ ] Set `ZOOM_CLIENT_SECRET`
  - [ ] Tested integration
- [ ] Daily.co
  - [ ] Obtained API key
  - [ ] Set `DAILY_API_KEY`
  - [ ] Set `DAILY_SCALE_PLAN` (true/false)
  - [ ] Tested video calls

### Payment Processing
- [ ] Stripe
  - [ ] Created Stripe account
  - [ ] Set `NEXT_PUBLIC_STRIPE_PUBLIC_KEY`
  - [ ] Set `STRIPE_PRIVATE_KEY`
  - [ ] Set `STRIPE_CLIENT_ID`
  - [ ] Set `STRIPE_WEBHOOK_SECRET`
  - [ ] Configured webhook endpoint
  - [ ] Tested payment flow

### SMS Notifications
- [ ] Twilio
  - [ ] Created Twilio account
  - [ ] Set `TWILIO_SID`
  - [ ] Set `TWILIO_TOKEN`
  - [ ] Set `TWILIO_PHONE_NUMBER`
  - [ ] Set `TWILIO_MESSAGING_SID`
  - [ ] Set `TWILIO_VERIFY_SID`
  - [ ] Tested SMS delivery

## Ongoing Maintenance

### Regular Tasks
- [ ] Set up automated database backups (weekly minimum)
- [ ] Configure backup retention policy
- [ ] Set up monitoring/alerting (Sentry, etc.)
- [ ] Document custom configuration in secure location
- [ ] Test backup restoration process

### Security
- [ ] Review access logs periodically
- [ ] Keep Cal.com updated (redeploy regularly)
- [ ] Monitor for security advisories
- [ ] Review user permissions
- [ ] Update passwords/secrets annually

### Performance
- [ ] Monitor resource usage (CPU, RAM, disk)
- [ ] Review database size and optimize if needed
- [ ] Check application logs for errors
- [ ] Monitor response times
- [ ] Consider Redis for caching if needed

### Updates
- [ ] Subscribe to Cal.com release notifications
- [ ] Test updates in staging environment first (if available)
- [ ] Plan update maintenance windows
- [ ] Notify users of scheduled maintenance
- [ ] Keep documentation updated with changes

## Troubleshooting Reference

### Build Failures
- **Symptom**: Build fails in Coolify
- **Check**: Memory allocation (need 4GB+)
- **Check**: Environment variables are set
- **Check**: Repository is accessible
- **Action**: Review build logs in Coolify

### Container Restarts
- **Symptom**: Container keeps restarting
- **Check**: Required environment variables present
- **Check**: Database is accessible
- **Check**: Secrets are valid (no special characters issues)
- **Action**: Check container logs in Coolify

### Database Connection Errors
- **Symptom**: Cannot connect to database
- **Check**: DATABASE_URL format correct
- **Check**: PostgreSQL service is running
- **Check**: Network connectivity between services
- **Action**: Test database connection manually

### Email Not Sending
- **Symptom**: Users not receiving emails
- **Check**: SMTP credentials are correct
- **Check**: EMAIL_SERVER_* variables set
- **Check**: Port 587/465 accessible from server
- **Action**: Test SMTP connection with curl/telnet

### SSL Certificate Issues
- **Symptom**: Browser shows security warning
- **Check**: DNS is properly configured
- **Check**: Let's Encrypt renewal working
- **Check**: Domain matches certificate
- **Action**: Regenerate certificate in Coolify

### Performance Issues
- **Symptom**: Slow page loads
- **Check**: Server resources (CPU/RAM usage)
- **Check**: Database performance
- **Check**: Network latency
- **Action**: Consider adding Redis, scaling resources

## Support Resources

### Documentation
- Quick Start: `COOLIFY-QUICKSTART.md`
- Full Guide: `DEPLOYMENT.md`
- Docker Info: `DOCKER-README.md`
- Summary: `DEPLOYMENT-SUMMARY.md`

### Community
- Cal.com Discord: https://discord.gg/calcom
- Coolify Discord: https://discord.gg/coolify
- GitHub Issues: https://github.com/calcom/cal.com/issues

### Official Resources
- Cal.com Docs: https://cal.com/docs
- Coolify Docs: https://coolify.io/docs
- Self-Hosting Guide: https://cal.com/docs/self-hosting

## Success Indicators

You've successfully deployed Cal.com when:

✅ Application loads without errors  
✅ Users can register and log in  
✅ Event types can be created  
✅ Bookings can be made  
✅ Email notifications work  
✅ SSL certificate is valid  
✅ Health check passes  
✅ No errors in logs  

## 🎉 Congratulations!

Once all critical items are checked, your Cal.com instance is ready for use!

Remember to:
1. Set up regular backups
2. Monitor performance
3. Keep the system updated
4. Join the community for support

---

Need help? Check the documentation or reach out to the community!

