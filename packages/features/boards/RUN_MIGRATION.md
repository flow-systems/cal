# Run the Migration - Quick Guide

## ✅ Everything is Ready!

Your table and column names match perfectly:
- ✅ Tables: `cards`, `boards`, `columns`
- ✅ Columns: `id`, `column_id`, `board_id`, `position`, `title`, `updated_at`

## Option 1: Run via Prisma (Recommended)

If you can fix the yarn lockfile issue first:

```bash
# Fix yarn lockfile (if needed)
yarn install

# Then run migration
cd packages/prisma
yarn prisma migrate deploy
```

Or from root:
```bash
yarn workspace @calcom/prisma db-deploy
```

## Option 2: Run SQL Directly (Fastest)

If you have database access, you can run the migration SQL directly:

1. **Open your database client** (pgAdmin, DBeaver, TablePlus, etc.)
2. **Connect to your database**
3. **Copy and paste the entire contents** of this file:
   `packages/prisma/migrations/20260126204203_transaction_based_card_move/migration.sql`
4. **Execute it**

The migration will:
- ✅ Create the `move_card_atomic()` PostgreSQL function
- ✅ Add a performance index
- ✅ Be ready to use immediately

## Option 3: Run via psql Command Line

```bash
# If you have DATABASE_URL set
psql $DATABASE_URL -f packages/prisma/migrations/20260126204203_transaction_based_card_move/migration.sql
```

## Verify Migration Worked

After running the migration, verify the function exists:

```sql
-- Check if function exists
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_name = 'move_card_atomic';

-- Check if index exists
SELECT indexname 
FROM pg_indexes 
WHERE tablename = 'cards' 
  AND indexname = 'cards_board_id_column_id_position_idx';
```

Both should return results if the migration succeeded.

## Test the Function

Once migration is complete, test it:

```sql
-- Replace with actual IDs from your database
SELECT * FROM move_card_atomic(
  'your-card-id'::UUID,
  'target-column-id'::UUID,
  2::INTEGER,
  'board-id'::UUID
);
```

## Next Steps

After migration:
1. ✅ Test the PostgreSQL function (see above)
2. ✅ Test the API endpoint: `trpc.viewer.boards.moveCard`
3. ✅ Update your frontend to use the new endpoint
4. ✅ Update realtime listeners to handle batch events

---

**Which option do you want to use?** Option 2 (direct SQL) is usually fastest if you have database access!