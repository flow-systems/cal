# Next Steps: You're Almost Done! ✅

## ✅ Step 1: Table Names Confirmed

Your table names match perfectly:
- ✅ `cards`
- ✅ `boards`
- ✅ `columns`

## ⚠️ Step 2: Verify Column Names (IMPORTANT)

Before running the migration, please verify your column names match what we're using.

**Run this SQL query in your database client:**

```sql
-- Check cards table columns
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'cards'
  AND column_name IN ('id', 'column_id', 'board_id', 'position', 'title', 'updated_at')
ORDER BY column_name;
```

**Expected columns:**
- `id` (should be UUID)
- `column_id` (should be UUID)
- `board_id` (should be UUID)
- `position` (should be INTEGER)
- `title` (should be TEXT/VARCHAR)
- `updated_at` (should be TIMESTAMP)

**If any column names are different** (e.g., `columnId` instead of `column_id`), let me know and I'll update the code!

---

## Step 3: Run the Migration

Once column names are confirmed, run:

```bash
yarn workspace @calcom/prisma db-migrate
```

**If you get errors:**
- Share the error message
- I'll help you fix it

---

## Step 4: Test the Function

After migration succeeds, test the PostgreSQL function:

```sql
-- Replace with actual IDs from your database
SELECT * FROM move_card_atomic(
  'your-card-id-here'::UUID,
  'target-column-id-here'::UUID,
  2::INTEGER,
  'board-id-here'::UUID
);
```

---

## Step 5: Test the API

Use the tRPC endpoint:

```typescript
const moveCard = trpc.viewer.boards.moveCard.useMutation()

moveCard.mutate({
  cardId: 'card-uuid',
  targetColumnId: 'column-uuid',
  targetPosition: 2,
  boardId: 'board-uuid'
})
```

---

## 🎉 Success Checklist

- [x] Table names confirmed
- [ ] Column names verified
- [ ] Migration run successfully
- [ ] Function tested
- [ ] API endpoint tested
- [ ] Frontend updated (if needed)

---

## Need Help?

If you run into any issues:
1. Share the error message
2. Share the column names if they differ
3. I'll help you fix it!