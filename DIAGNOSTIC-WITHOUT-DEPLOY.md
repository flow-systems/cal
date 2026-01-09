# Diagnostic Guide: 404 Issues Without Redeploying

## Critical Understanding

**Next.js rewrites are baked at BUILD TIME**, but **organization domain detection runs at RUNTIME**.

This means:
- ✅ Changing `ORGANIZATIONS_ENABLED=0` in Dokploy **won't help** until you rebuild
- ✅ But `ALLOWED_HOSTNAMES` is checked at **runtime**, so removing it might help
- ⚠️ The current build still has organization rewrites active

## Issue Analysis

### Problem 1: Build-Time vs Runtime

1. **Build-time (baked into current deployment):**
   - `ORGANIZATIONS_ENABLED` value when build happened
   - Next.js rewrite rules
   - These CANNOT be changed without rebuild

2. **Runtime (checked on each request):**
   - `ALLOWED_HOSTNAMES` environment variable
   - `orgDomainConfig()` function that detects org domains
   - User lookup in database

### Problem 2: The Logic Flow

When you visit `https://meet.ai-in-action.de/amose`:

1. **Next.js Rewrite** (from build):
   - If `ORGANIZATIONS_ENABLED=1` was set during build → rewrites `/amose` to `/org/meet/amose`
   - If `ORGANIZATIONS_ENABLED=0` was set during build → no rewrite, goes to `/[user]` route

2. **Runtime Detection** (`orgDomainConfig`):
   - Checks if `ALLOWED_HOSTNAMES` contains base domain
   - Extracts `meet` as org slug from `meet.ai-in-action.de`
   - Sets `isValidOrgDomain = true`

3. **User Lookup** (`getServerSideProps.ts:129`):
   ```typescript
   if (!usersInOrgContext.length || (!isValidOrgDomain && !isThereAnyNonOrgUser)) {
     return { notFound: true };
   }
   ```
   - If `isValidOrgDomain = true` → looks for user in organization `meet`
   - If user not in org → returns 404

## Diagnostic Steps (Without Redeploying)

### Step 1: Check Current Environment Variables

In Dokploy, verify what's actually set:

```bash
# Check these in Dokploy environment variables:
ORGANIZATIONS_ENABLED=0  # or not set
ALLOWED_HOSTNAMES=ai-in-action.de  # This is the problem!
NEXT_PUBLIC_WEBAPP_URL=https://meet.ai-in-action.de
```

### Step 2: Remove ALLOWED_HOSTNAMES (Runtime Fix)

**This can work without rebuild!**

In Dokploy:
1. **Remove or unset** `ALLOWED_HOSTNAMES` environment variable
2. **Restart the container** (not full rebuild, just restart)

This should:
- Make `orgDomainConfig` return `isValidOrgDomain = false`
- Allow non-org users to be found
- Fix the 404 (if rewrites aren't blocking)

**Note:** You'll see warnings in logs, but it should work.

### Step 3: Check Application Logs

Look for these log messages when accessing `/amose`:

**Good signs:**
```
[orgDomains.ts] Match of WEBAPP_URL with ALLOWED_HOSTNAMES failed
```
This means org detection is disabled.

**Bad signs:**
```
[Phase: phase-production-server] Adding rewrite config for organizations
```
This means rewrites are active (from build).

### Step 4: Check Database

Verify the user exists and check organization membership:

**In Dokploy terminal or database client:**
```sql
-- Check if user exists
SELECT id, username, email FROM "User" WHERE username = 'amose';

-- Check if user is in any organization
SELECT u.username, t.slug as org_slug, t.name as org_name
FROM "User" u
LEFT JOIN "Membership" m ON m."userId" = u.id
LEFT JOIN "Team" t ON t.id = m."teamId" AND t."isOrganization" = true
WHERE u.username = 'amose';
```

**Expected:**
- User should exist
- If `org_slug` is NULL → user is not in an organization (good for non-org setup)
- If `org_slug = 'meet'` → user is in org (should work if org routing is correct)

### Step 5: Test Direct Route Access

Try accessing the route that should work:

**If organizations are disabled in build:**
- `https://meet.ai-in-action.de/amose` should work directly

**If organizations are enabled in build:**
- `https://meet.ai-in-action.de/amose` → rewrites to `/org/meet/amose`
- Try: `https://meet.ai-in-action.de/org/meet/amose` (might work if org exists)

### Step 6: Check What Was Built

You can't change the build, but you can verify what's active:

**Check startup logs for:**
```
[Phase: phase-production-server] Adding rewrite config for organizations
```
vs
```
[Phase: phase-production-server] Skipping rewrite config for organizations
```

This tells you if organization rewrites are active in the current build.

## Possible Scenarios

### Scenario A: Organizations Disabled in Build + ALLOWED_HOSTNAMES Removed

**Status:** ✅ Should work
- No rewrites active
- No org detection
- User lookup works normally

### Scenario B: Organizations Enabled in Build + ALLOWED_HOSTNAMES Removed

**Status:** ⚠️ Might work
- Rewrites are active (`/amose` → `/org/meet/amose`)
- But org detection fails (no ALLOWED_HOSTNAMES)
- Might fall back to non-org lookup

### Scenario C: Organizations Enabled in Build + ALLOWED_HOSTNAMES Set

**Status:** ❌ Won't work (current state)
- Rewrites active
- Org detection active
- Looks for user in org `meet`
- User not found → 404

## Quick Fixes to Try (No Rebuild)

### Fix 1: Remove ALLOWED_HOSTNAMES

1. In Dokploy, delete `ALLOWED_HOSTNAMES` environment variable
2. Restart container (not rebuild)
3. Test: `https://meet.ai-in-action.de/amose`

**Expected:** Should work if build doesn't have org rewrites, or might work with fallback.

### Fix 2: Create Organization (If You Want to Keep Setup)

1. In Cal.com admin, create organization with slug `meet`
2. Add user `amose` to organization
3. Keep current configuration

**Expected:** Should work immediately.

### Fix 3: Check if User Exists in Database

```sql
SELECT * FROM "User" WHERE username = 'amose';
```

If user doesn't exist, that's the problem (not routing).

## What to Check in Logs

When you access `https://meet.ai-in-action.de/amose`, look for:

1. **Organization detection:**
   ```
   Match of WEBAPP_URL with ALLOWED_HOSTNAMES failed
   ```
   or
   ```
   (no message) - means it matched
   ```

2. **User lookup:**
   ```
   usersInOrgContext: []
   ```
   or
   ```
   usersInOrgContext: [{ username: 'amose', ... }]
   ```

3. **Routing:**
   ```
   Adding rewrite config for organizations
   ```
   (means rewrites are active from build)

## Next Steps

1. **Remove ALLOWED_HOSTNAMES** and restart container
2. **Check logs** when accessing the URL
3. **Verify user exists** in database
4. **Check if organization exists** with slug `meet`
5. **Report findings** before deciding on rebuild

## Why Rebuild is Eventually Needed

Even if removing `ALLOWED_HOSTNAMES` works temporarily, you'll eventually need to rebuild because:
- The Next.js rewrites are still in the build
- Future updates might break
- It's not a permanent solution

But this diagnostic will tell us if the issue is:
- Build-time (rewrites) → needs rebuild
- Runtime (ALLOWED_HOSTNAMES) → can fix without rebuild
- Database (user doesn't exist) → different issue

