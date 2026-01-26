# Simple Guide to Find Your Table Names

## Option 1: Run SQL Query in Your Database Client (Easiest)

**Don't run this in terminal!** Instead:

1. Open your database client (pgAdmin, DBeaver, TablePlus, or any SQL client)
2. Connect to your database
3. Run this SQL query:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND (
    table_name ILIKE '%card%' 
    OR table_name ILIKE '%board%' 
    OR table_name ILIKE '%column%'
    OR table_name ILIKE '%kanban%'
  )
ORDER BY table_name;
```

4. Copy the results and share them with me

---

## Option 2: Use Prisma Studio

If you have Prisma Studio installed:

```bash
npx prisma studio
```

Then look for tables with names containing "card", "board", or "column".

---

## Option 3: Check Your Database Connection String

If you have a `.env` file with `DATABASE_URL`, you can connect directly:

```bash
# If using psql from terminal (not SQL client):
psql $DATABASE_URL

# Then once connected, run:
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND (table_name ILIKE '%card%' OR table_name ILIKE '%board%' OR table_name ILIKE '%column%') ORDER BY table_name;
```

---

## Option 4: Tell Me About Your Existing Code

If you have any existing code that:
- Fetches board data
- Moves cards
- Queries cards/boards/columns

Share the file path and I can check what table names it uses!

---

## What I Need From You

Just tell me:
1. **Card table name**: `?`
2. **Board table name**: `?`
3. **Column table name**: `?`

Once I have these, I'll update all the code for you automatically!