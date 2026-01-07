# Database Connection Troubleshooting (P1001 Error)

## What is P1001?

Prisma error code `P1001` means: **"Can't reach database server"**

This is a **network connectivity issue** - your Cal.com application cannot connect to your PostgreSQL database.

## Common Causes & Solutions

### 1. Database Not Running

**Check if database is running:**
- In Dokploy: Check if your PostgreSQL service/container is running
- Look for database container status in Dokploy dashboard
- Check database logs for errors

**Solution:** Start the database service in Dokploy

### 2. Wrong DATABASE_URL Format

**Correct format:**
```
postgresql://username:password@host:port/database
```

**Common mistakes:**
- Missing `postgresql://` prefix
- Wrong port (default is 5432)
- Special characters in password not URL-encoded
- Missing database name at the end

**Example:**
```
✅ Correct: postgresql://calcom:myPassword123@postgres:5432/calcom
❌ Wrong: postgres://calcom:myPassword123@postgres:5432
❌ Wrong: calcom:myPassword123@postgres:5432/calcom
```

### 3. Wrong Host in DATABASE_URL

**If database is in Dokploy (same network):**
- Use the **service name** as host (e.g., `postgres`, `db`, `database`)
- NOT `localhost` or `127.0.0.1`
- NOT the external IP/domain

**Examples:**
```
✅ If service is named "postgres": postgresql://user:pass@postgres:5432/db
✅ If service is named "db": postgresql://user:pass@db:5432/db
❌ Wrong: postgresql://user:pass@localhost:5432/db
❌ Wrong: postgresql://user:pass@127.0.0.1:5432/db
```

**If database is external:**
- Use the actual IP address or domain name
- Ensure firewall allows connections from Dokploy

### 4. Network Connectivity Issues

**If database is in Dokploy:**
- Ensure both Cal.com app and database are on the **same Docker network**
- Check Dokploy network settings
- Verify services can communicate

**If database is external:**
- Check firewall rules allow connections from Dokploy's IP
- Verify database server is accessible from internet (if needed)
- Test connection: `nc -zv <db-host> 5432` from Dokploy container

### 5. Database Credentials Wrong

**Check:**
- Username is correct
- Password is correct (watch for typos)
- User has permissions to access the database
- Database exists

**Test credentials:**
```bash
# From Dokploy container or server
psql postgresql://user:password@host:5432/database -c "SELECT 1;"
```

### 6. Database Doesn't Exist

**Check if database exists:**
```sql
-- Connect to PostgreSQL and list databases
\l
```

**Create database if missing:**
```sql
CREATE DATABASE calcom;
```

### 7. SSL/TLS Requirements

**If database requires SSL:**
Add `?sslmode=require` to connection string:
```
postgresql://user:pass@host:5432/db?sslmode=require
```

**Other SSL options:**
- `?sslmode=prefer` - Try SSL, fallback to non-SSL
- `?sslmode=disable` - Disable SSL (not recommended for production)

### 8. Connection Pooling Issues

Cal.com uses connection pooling. If you see connection errors:

**Try adding DATABASE_DIRECT_URL:**
```
DATABASE_URL=postgresql://user:pass@host:5432/db
DATABASE_DIRECT_URL=postgresql://user:pass@host:5432/db
```

**For read/write separation (if configured):**
```
DATABASE_URL=postgresql://user:pass@host:5432/db
DATABASE_READ_URL=postgresql://user:pass@read-host:5432/db
DATABASE_WRITE_URL=postgresql://user:pass@write-host:5432/db
```

## Diagnostic Steps

### Step 1: Verify DATABASE_URL Format

Check your DATABASE_URL in Dokploy:
1. Go to Environment Variables
2. Find `DATABASE_URL`
3. Verify format: `postgresql://user:password@host:port/database`

### Step 2: Test Database Connectivity

**From Dokploy container:**
```bash
# Test if database host is reachable
nc -zv <db-host> 5432

# Test connection with psql (if available)
psql "$DATABASE_URL" -c "SELECT version();"
```

### Step 3: Check Database Logs

In Dokploy, check database service logs for:
- Connection attempts
- Authentication failures
- Network errors

### Step 4: Verify Database is Running

```bash
# Check if PostgreSQL is listening
netstat -tuln | grep 5432
# or
ss -tuln | grep 5432
```

### Step 5: Check Network Configuration

**If using Dokploy services:**
- Ensure Cal.com app and database are on same network
- Check Dokploy service networking settings
- Verify service names match in DATABASE_URL

## Dokploy-Specific Issues

### Issue: Database Service Name

In Dokploy, when you create a PostgreSQL service, note the **service name**. Use that name as the host in DATABASE_URL.

**Example:**
- Service name: `postgres`
- DATABASE_URL: `postgresql://user:pass@postgres:5432/db`

### Issue: Environment Variables Not Available

Ensure `DATABASE_URL` is set as:
1. **Build argument** (for build-time if needed)
2. **Runtime environment variable** (required for app to run)

### Issue: Database on Different Network

If database is on a different Docker network:
1. Check Dokploy network configuration
2. Ensure services are on same network
3. Or use external database with proper firewall rules

## Quick Fix Checklist

- [ ] Database service is running in Dokploy
- [ ] DATABASE_URL format is correct: `postgresql://user:pass@host:port/db`
- [ ] Host name matches database service name (if in Dokploy)
- [ ] Port is correct (default: 5432)
- [ ] Username and password are correct
- [ ] Database exists
- [ ] Services are on same Docker network (if in Dokploy)
- [ ] Firewall allows connections (if external database)
- [ ] SSL mode is set if required (`?sslmode=require`)

## Dokploy Database Startup Issues

### Common Error: Database Won't Start

If you get an error when trying to "start" the database in Dokploy:

**Possible causes:**
1. **Port already in use**: Another service might be using port 5432
2. **Volume/permissions issue**: Database data directory might have permission problems
3. **Resource constraints**: Not enough memory/disk space
4. **Configuration error**: Invalid environment variables (POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB)

**Solutions:**
1. **Check if port 5432 is available**: Look for other PostgreSQL services
2. **Check Dokploy logs**: View database service logs for specific error
3. **Verify environment variables**: Ensure POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB are set
4. **Check resources**: Ensure Dokploy has enough memory/disk
5. **Try recreating**: Delete and recreate the database service

**Note**: The database doesn't need to be "started" separately if it's configured as a dependency. Dokploy should start it automatically when your Cal.com app starts (if configured with `depends_on`).

### Database Already Running

If Dokploy says the database is already running but you can't connect:
- Check the actual service status in Dokploy dashboard
- Verify the service name matches your DATABASE_URL host
- Check if database is on a different network

## Still Not Working?

1. **Check Cal.com container logs** in Dokploy for detailed error messages
2. **Check database logs** for connection attempts
3. **Test connection manually** using `psql` or `nc` from container
4. **Verify DATABASE_URL** is actually set in the running container:
   ```bash
   docker exec <container> env | grep DATABASE_URL
   ```
5. **Check Dokploy database service logs** for startup errors

## Example Working Configuration

For a Dokploy setup with PostgreSQL service named "postgres":

```env
# Build arguments (if needed)
DATABASE_URL=postgresql://calcom:securePassword123@postgres:5432/calcom

# Runtime environment variables
DATABASE_URL=postgresql://calcom:securePassword123@postgres:5432/calcom
DATABASE_DIRECT_URL=postgresql://calcom:securePassword123@postgres:5432/calcom
```

For external database:

```env
DATABASE_URL=postgresql://calcom:securePassword123@db.example.com:5432/calcom?sslmode=require
```

