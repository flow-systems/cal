# Debug 404 Issue - Step by Step

## Current Status from Logs

✅ **Good News:**
- Organization rewrites are DISABLED: `"Skipping rewrite config for organizations because ORGANIZATIONS_ENABLED is not set"`
- This means `/amose` should go directly to `/[user]` route (no rewrite)

❌ **Problem:**
- Visiting `https://meet.ai-in-action.de/amose` doesn't log anything
- This suggests the request might not be reaching Next.js, OR it's failing silently

## Root Cause Analysis

The code at `apps/web/server/lib/[user]/getServerSideProps.ts:129` returns 404 silently:

```typescript
if (!usersInOrgContext.length || (!isValidOrgDomain && !isThereAnyNonOrgUser)) {
  return { notFound: true };  // ← No logging!
}
```

**This means:**
1. `orgDomainConfig()` is still detecting `meet` as org domain (because `ALLOWED_HOSTNAMES` is set)
2. `isValidOrgDomain = true`
3. Looks for user in organization `meet`
4. User not found → returns 404 silently

## Diagnostic Steps (No Rebuild Needed)

### Step 1: Verify ALLOWED_HOSTNAMES is Actually Removed

**In Dokploy:**
1. Go to Environment Variables
2. Search for `ALLOWED_HOSTNAMES` or `allowed_hostnames`
3. **Delete it completely** (don't just set it to empty)
4. **Restart the container** (not rebuild, just restart)

**Verify it's gone:**
```bash
# In Dokploy terminal/shell for the container
env | grep -i allowed
# Should return nothing
```

### Step 2: Enable Debug Logging

The code has debug logging but it might not be enabled. Check your logger level:

**In Dokploy, set:**
```env
NEXT_PUBLIC_LOGGER_LEVEL=2  # or 3 for more verbose
```

Then restart container and try accessing the URL again. You should see:
```
[[pages/[user]]] { usersInOrgContext: [], isValidOrgDomain: true/false, currentOrgDomain: 'meet' or null }
```

### Step 3: Check Database Directly

**In Dokploy terminal or database client, run:**

```sql
-- Check if user exists
SELECT id, username, email, "createdAt" 
FROM "User" 
WHERE username = 'amose';

-- Check user's organization membership
SELECT 
  u.id,
  u.username,
  u.email,
  t.id as org_id,
  t.slug as org_slug,
  t.name as org_name,
  m.role as membership_role
FROM "User" u
LEFT JOIN "Membership" m ON m."userId" = u.id AND m.accepted = true
LEFT JOIN "Team" t ON t.id = m."teamId" AND t."isOrganization" = true
WHERE u.username = 'amose';
```

**Expected Results:**
- User should exist
- `org_slug` should be `NULL` (user not in any organization)
- If `org_slug = 'meet'`, then user IS in org (different issue)

### Step 4: Test with Direct Database Query

**Check what `findUsersByUsername` would return:**

```sql
-- Simulate what the code does (without org context)
SELECT 
  u.id,
  u.username,
  u.email,
  u.name,
  u."avatarUrl",
  u."allowSEOIndexing"
FROM "User" u
WHERE u.username = 'amose'
LIMIT 1;
```

If this returns no rows, the user doesn't exist (different problem).

### Step 5: Check if Request Reaches Next.js

**Add temporary logging** (if you can access container):

The request might be blocked before reaching Next.js. Check:
1. **Dokploy reverse proxy logs** - might be blocking/redirecting
2. **Container access logs** - see if request reaches container
3. **Next.js access logs** - should show request if it reaches the app

### Step 6: Test Alternative Routes

Try these URLs to see what works:

1. **Admin interface:** `https://meet.ai-in-action.de/` (should work)
2. **API endpoint:** `https://meet.ai-in-action.de/api/version` (should work)
3. **Profile page:** `https://meet.ai-in-action.de/amose` (currently 404)
4. **Event page:** `https://meet.ai-in-action.de/amose/30m` (currently 404)

If admin works but profile doesn't, it's a routing/user lookup issue.
If nothing works, it's a proxy/Dokploy configuration issue.

## Most Likely Issue

Based on the code flow, the most likely scenario is:

1. ✅ Organization rewrites are disabled (confirmed by logs)
2. ❌ `ALLOWED_HOSTNAMES` is still set (runtime check)
3. ❌ `orgDomainConfig()` detects `meet` as org domain
4. ❌ `isValidOrgDomain = true`
5. ❌ Code looks for user in org `meet`
6. ❌ User not in org → returns 404 silently

## Quick Fix to Try

### Option A: Remove ALLOWED_HOSTNAMES (Runtime Fix)

1. **In Dokploy, completely remove** `ALLOWED_HOSTNAMES` environment variable
2. **Restart container** (not rebuild)
3. **Test:** `https://meet.ai-in-action.de/amose`

**Expected:** Should work if user exists and isn't in an org.

### Option B: Verify User Exists

If removing `ALLOWED_HOSTNAMES` doesn't work, the user might not exist:

```sql
SELECT * FROM "User" WHERE username = 'amose';
```

If this returns nothing, create the user or check why it's missing.

### Option C: Check Username Case Sensitivity

Usernames might be case-sensitive:

```sql
SELECT username FROM "User" WHERE LOWER(username) = 'amose';
```

Try accessing with different cases if needed.

## What to Report Back

After trying the steps above, report:

1. **Is ALLOWED_HOSTNAMES removed?** (check with `env | grep allowed`)
2. **Does user exist in database?** (SQL query result)
3. **Is user in an organization?** (SQL query result)
4. **What happens when you access the URL?** (any new logs?)
5. **Does admin interface work?** (`https://meet.ai-in-action.de/`)

This will help identify if it's:
- Environment variable issue (ALLOWED_HOSTNAMES)
- Database issue (user doesn't exist)
- Organization membership issue (user in wrong org)
- Routing issue (something else blocking)

