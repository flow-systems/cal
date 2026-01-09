# Public Profile and Booking Pages 404 Troubleshooting

## Symptoms
- Admin interface works (you can access settings, create events)
- Public profile pages return 404: `https://meet.ai-in-action.de/amose`
- Booking pages return 404: `https://meet.ai-in-action.de/amose/30m`
- URLs in the interface show without protocol (e.g., `meet.ai-in-action.de/amose/meeting`)

## Root Causes

### 1. NEXT_PUBLIC_WEBAPP_URL Missing Protocol (Most Common)

**Problem:** `NEXT_PUBLIC_WEBAPP_URL` must include the protocol (`https://` or `http://`).

**Fix:** In Dokploy, set:
```
NEXT_PUBLIC_WEBAPP_URL=https://meet.ai-in-action.de
```

**NOT:**
```
NEXT_PUBLIC_WEBAPP_URL=meet.ai-in-action.de  ❌ Missing protocol!
```

### 2. ALLOWED_HOSTNAMES Not Set

**Problem:** Organization routing requires `ALLOWED_HOSTNAMES` to be set.

**Fix:** In Dokploy, set:
```
ALLOWED_HOSTNAMES=ai-in-action.de
```
or
```
allowed_hostnames=ai-in-action.de
```

**How to determine:** Extract the base domain from your `NEXT_PUBLIC_WEBAPP_URL`:
- If `NEXT_PUBLIC_WEBAPP_URL=https://meet.ai-in-action.de`
- Then `ALLOWED_HOSTNAMES=ai-in-action.de` (remove subdomain and protocol)

### 3. Organization Routing Configuration

Cal.com uses organization subdomain routing. For your setup:
- Your domain: `meet.ai-in-action.de`
- Base domain: `ai-in-action.de`
- Username: `amose`

The routing expects:
- Profile: `https://meet.ai-in-action.de/amose`
- Event: `https://meet.ai-in-action.de/amose/30m`

### 4. NEXT_PUBLIC_WEBSITE_URL (Optional but Recommended)

If you have a separate website URL, set:
```
NEXT_PUBLIC_WEBSITE_URL=https://meet.ai-in-action.de
```

If not set, it defaults to `https://cal.com` which might cause issues.

## Complete Configuration Checklist

In Dokploy, ensure these environment variables are set:

### Required:
```env
# MUST include https:// protocol
NEXT_PUBLIC_WEBAPP_URL=https://meet.ai-in-action.de

# Base domain (without subdomain)
ALLOWED_HOSTNAMES=ai-in-action.de

# Database
DATABASE_URL=postgresql://user:pass@host:5432/db

# Security
NEXTAUTH_SECRET=your-secret-here
CALENDSO_ENCRYPTION_KEY=your-key-here
```

### Recommended:
```env
# If different from WEBAPP_URL, set this
NEXT_PUBLIC_WEBSITE_URL=https://meet.ai-in-action.de
```

## Verification Steps

1. **Check environment variables in Dokploy:**
   - Verify `NEXT_PUBLIC_WEBAPP_URL` starts with `https://`
   - Verify `ALLOWED_HOSTNAMES` is set to base domain

2. **Check application logs:**
   - Look for organization routing messages
   - Check for any URL parsing errors

3. **Test URLs:**
   - Profile: `https://meet.ai-in-action.de/amose`
   - Event: `https://meet.ai-in-action.de/amose/30m` (or your event slug)

## About the Missing Protocol in UI

The missing protocol in the displayed URL (`meet.ai-in-action.de/amose/meeting`) is likely just a display issue in the UI. The important thing is that:
1. `NEXT_PUBLIC_WEBAPP_URL` has the protocol
2. The actual links work when clicked
3. The routing configuration is correct

If the protocol is missing in the UI but the links work, it's a cosmetic issue and can be ignored.

## Still Not Working?

1. **Rebuild the application** after changing environment variables
2. **Check Next.js rewrites** - organization routing uses Next.js rewrites
3. **Verify username** - ensure your username is `amose` (case-sensitive)
4. **Check event slug** - ensure the event slug matches exactly (e.g., `30m` not `30-min`)
5. **Review logs** for organization routing errors

## Common Mistakes

❌ `NEXT_PUBLIC_WEBAPP_URL=meet.ai-in-action.de` (missing protocol)
✅ `NEXT_PUBLIC_WEBAPP_URL=https://meet.ai-in-action.de`

❌ `ALLOWED_HOSTNAMES=meet.ai-in-action.de` (should be base domain)
✅ `ALLOWED_HOSTNAMES=ai-in-action.de`

❌ `ALLOWED_HOSTNAMES=https://ai-in-action.de` (should not include protocol)
✅ `ALLOWED_HOSTNAMES=ai-in-action.de`

