# Root Cause Analysis: Public Profile Pages Returning 404

## Problem Summary

When visiting `https://meet.ai-in-action.de/amose`, the page returns 404 even though:
- The admin interface works
- The user `amose` exists
- Events are created

## Root Cause

Cal.com is treating `meet.ai-in-action.de` as an **organization subdomain** because:

1. **ALLOWED_HOSTNAMES is set** to `ai-in-action.de`
2. **Organization routing is enabled** (ORGANIZATIONS_ENABLED is likely set or auto-enabled)
3. The system extracts `meet` as the organization slug from the subdomain
4. It rewrites `/amose` → `/org/meet/amose`
5. The user `amose` is **NOT in an organization** with slug `meet`
6. The lookup fails → returns 404

### Code Flow

1. **Domain Detection** (`packages/features/ee/organizations/lib/orgDomains.ts:41-45`):
   ```typescript
   const currentHostname = ALLOWED_HOSTNAMES.find((ahn) => {
     const url = new URL(WEBAPP_URL);
     const testHostname = `${url.hostname}${url.port ? `:${url.port}` : ""}`;
     return testHostname.endsWith(`.${ahn}`);
   });
   ```
   - Checks if `meet.ai-in-action.de` ends with `.ai-in-action.de` ✅ (matches)
   - Extracts `meet` as the org slug

2. **Next.js Rewrite** (`apps/web/next.config.ts:322-323`):
   ```typescript
   {
     ...orgDomainMatcherConfig.user,
     destination: `/org/${orgSlug}/:user`,
   }
   ```
   - Rewrites `/amose` to `/org/meet/amose`

3. **User Lookup** (`apps/web/server/lib/[user]/getServerSideProps.ts:129`):
   ```typescript
   if (!usersInOrgContext.length || (!isValidOrgDomain && !isThereAnyNonOrgUser)) {
     return { notFound: true };
   }
   ```
   - Looks for user `amose` in organization `meet`
   - User not found → returns 404

## Solutions

### Solution 1: Use Root Domain (Recommended for Single User)

**Change your domain setup:**
- **Current:** `https://meet.ai-in-action.de`
- **New:** `https://ai-in-action.de` (no subdomain)

**Configuration:**
```env
NEXT_PUBLIC_WEBAPP_URL=https://ai-in-action.de
ALLOWED_HOSTNAMES=ai-in-action.de
```

**Pros:**
- No organization routing conflicts
- Simpler setup
- Works immediately

**Cons:**
- Need to change DNS
- Need to update SSL certificate

### Solution 2: Remove ALLOWED_HOSTNAMES (If Not Using Organizations)

**If you're not using organizations:**
```env
# Remove or don't set ALLOWED_HOSTNAMES
# ALLOWED_HOSTNAMES=  (remove this)
```

**Also ensure:**
```env
ORGANIZATIONS_ENABLED=0  # or don't set it
```

**Pros:**
- Keeps your current domain
- No DNS changes needed

**Cons:**
- You'll see warnings about ALLOWED_HOSTNAMES
- Can't use organization features later

### Solution 3: Create an Organization (If You Want Organizations)

**In Cal.com admin:**
1. Go to Settings → Organizations
2. Create a new organization with slug `meet`
3. Add user `amose` to the organization

**Configuration stays the same:**
```env
NEXT_PUBLIC_WEBAPP_URL=https://meet.ai-in-action.de
ALLOWED_HOSTNAMES=ai-in-action.de
ORGANIZATIONS_ENABLED=1
```

**Pros:**
- Enables organization features
- Supports multiple users/teams
- Future-proof

**Cons:**
- More complex setup
- Requires organization management

### Solution 4: Use Single Org Mode

**If you want one organization for all users:**
```env
NEXT_PUBLIC_WEBAPP_URL=https://meet.ai-in-action.de
ALLOWED_HOSTNAMES=ai-in-action.de
NEXT_PUBLIC_SINGLE_ORG_SLUG=meet
ORGANIZATIONS_ENABLED=1
```

Then create an organization with slug `meet` and add all users to it.

## Recommended Solution

**For a single-user setup:** Use **Solution 1** (root domain) or **Solution 2** (remove ALLOWED_HOSTNAMES).

**For multi-user/team setup:** Use **Solution 3** (create organization).

## Verification Steps

After applying a solution:

1. **Check environment variables** in Dokploy
2. **Rebuild the application** (env vars are baked into the build)
3. **Test the URL:** `https://meet.ai-in-action.de/amose` (or your chosen domain)
4. **Check logs** for organization routing messages

## Current Configuration Check

Verify these in Dokploy:

```env
# Current (causing the issue):
NEXT_PUBLIC_WEBAPP_URL=https://meet.ai-in-action.de  ✅ (has protocol)
ALLOWED_HOSTNAMES=ai-in-action.de  ⚠️ (enables org routing)
ORGANIZATIONS_ENABLED=1  ⚠️ (or auto-enabled)
```

The combination of `ALLOWED_HOSTNAMES` + `ORGANIZATIONS_ENABLED` + subdomain is causing the issue.

