# Quick Start Guide

## 🚀 Fastest Path to Implementation

### Step 1: Find Your Table Names (5 minutes)

**Option A: Run SQL Query**
```bash
# Connect to your database and run:
psql $DATABASE_URL -c "
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND (table_name ILIKE '%card%' OR table_name ILIKE '%board%' OR table_name ILIKE '%column%')
ORDER BY table_name;
"
```

**Option B: Check Existing Code**
Look for any file that queries board/card data. The table names will be in the SQL queries.

### Step 2: Update Two Files (10 minutes)

#### File 1: Migration
**File**: `packages/prisma/migrations/20260126204203_transaction_based_card_move/migration.sql`

Use Find & Replace:
- `cards` → your actual card table name
- `boards` → your actual board table name
- `columns` → your actual column table name

#### File 2: Handler  
**File**: `packages/trpc/server/routers/viewer/boards/moveCard.handler.ts`

Same Find & Replace:
- `cards` → your actual card table name
- `boards` → your actual board table name
- `columns` → your actual column table name

### Step 3: Run Migration (2 minutes)

```bash
yarn workspace @calcom/prisma db-migrate
```

### Step 4: Test (5 minutes)

```sql
-- Test in your database (replace with real IDs):
SELECT * FROM move_card_atomic(
  'card-id'::UUID,
  'column-id'::UUID,
  1::INTEGER,
  'board-id'::UUID
);
```

### Step 5: Update Frontend (if needed)

Change your existing card move code to use:
```typescript
trpc.viewer.boards.moveCard.useMutation()
```

---

## ⚠️ Common Issues

**"Table does not exist"**
→ You need to update table names in Step 2

**"Column does not exist"**  
→ Check if your columns use `columnId` (camelCase) instead of `column_id` (snake_case)

**"Function already exists"**
→ This is fine - the migration uses `CREATE OR REPLACE`

---

## 📞 Need Help?

1. Share the output from Step 1 (table names)
2. Share any error messages you get
3. I'll help you fix it!

---

## ✅ Success Checklist

- [ ] Found table names
- [ ] Updated migration file
- [ ] Updated handler file  
- [ ] Migration ran successfully
- [ ] Function works when tested
- [ ] API endpoint works
- [ ] Frontend updated