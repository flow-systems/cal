# Step-by-Step Guide: Implementing Transaction-Based Card Move

## 🎯 Goal
Refactor your card move system to use Option D: Transaction-Based Move with Single Realtime Event to fix positioning and persistence issues.

---

## Step 1: Find Your Database Table Names ⚠️ CRITICAL

**This is the most important step!** We need to know your actual table names.

### Method 1: Query Your Database (Recommended)

Connect to your PostgreSQL database and run:

```sql
-- Find all tables with 'card', 'board', or 'column' in the name
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND (
    table_name ILIKE '%card%' 
    OR table_name ILIKE '%board%' 
    OR table_name ILIKE '%column%'
  )
ORDER BY table_name;
```

**Write down the results here:**
- Card table name: `_________________`
- Board table name: `_________________`
- Column table name: `_________________`

### Method 2: Check Your Existing Working Code

If you have code that currently works with boards/cards, check what table names it uses. Look for:
- Any API endpoints that fetch board/card data
- Any database queries in your codebase
- Any Prisma queries that work

### Method 3: Check Column Names

Also verify your column names. Run:

```sql
-- Check card table structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'your_card_table_name'  -- Replace with actual table name
ORDER BY ordinal_position;
```

**Common column names to check:**
- `id` or `card_id`?
- `column_id` or `columnId`?
- `board_id` or `boardId`?
- `position`?
- `title`?
- `updated_at` or `updatedAt`?

---

## Step 2: Update the Migration File

**File**: `packages/prisma/migrations/20260126204203_transaction_based_card_move/migration.sql`

### What to Update:

1. **Find all instances of `cards`** and replace with your actual card table name
2. **Find all instances of `boards`** and replace with your actual board table name  
3. **Find all instances of `columns`** and replace with your actual column table name

### Example:
If your tables are named `kanban_cards`, `kanban_boards`, `kanban_columns`:

```sql
-- Change this:
FROM cards
-- To this:
FROM kanban_cards
```

### Quick Find & Replace:
- Search for: `FROM cards` → Replace with: `FROM your_actual_table_name`
- Search for: `UPDATE cards` → Replace with: `UPDATE your_actual_table_name`
- Search for: `ON cards` → Replace with: `ON your_actual_table_name`

**Do this for all three tables (cards, boards, columns).**

---

## Step 3: Update the Handler File

**File**: `packages/trpc/server/routers/viewer/boards/moveCard.handler.ts`

### What to Update:

1. **Line ~40**: Update `FROM boards` to your actual board table name
2. **Line ~61**: Update `FROM cards` to your actual card table name
3. **Line ~77**: Update `FROM columns` to your actual column table name
4. **Line ~116**: Update `FROM cards` to your actual card table name

### Also Check Column Names:

If your columns use different names (e.g., `columnId` instead of `column_id`), update:
- `column_id` → your actual column name
- `board_id` → your actual board column name
- `user_id` → your actual user column name
- `team_id` → your actual team column name

---

## Step 4: Verify the Migration SQL

Before running the migration, double-check:

1. ✅ All table names are correct
2. ✅ All column names are correct
3. ✅ The function name `move_card_atomic` is acceptable (or change it if needed)

---

## Step 5: Run the Migration

```bash
# Navigate to your project root
cd /Users/Mo/Library/CloudStorage/OneDrive-inside360.studio/Repos/cal

# Run the migration
yarn workspace @calcom/prisma db-migrate
```

**If you get errors:**
- Check the error message - it will tell you what's wrong
- Common issues:
  - Table doesn't exist → Check table name
  - Column doesn't exist → Check column name
  - Syntax error → Check SQL syntax

---

## Step 6: Test the PostgreSQL Function

Test the function directly in your database:

```sql
-- Replace with actual IDs from your database
SELECT * FROM move_card_atomic(
  'your-card-id-here'::UUID,
  'target-column-id-here'::UUID,
  2::INTEGER,
  'board-id-here'::UUID
);
```

**Expected result:** Should return affected cards with their new positions.

**If it fails:**
- Check the error message
- Verify the IDs exist
- Check table/column names are correct

---

## Step 7: Test the API Endpoint

### Option A: Via tRPC Client

```typescript
import { trpc } from '@calcom/trpc/react'

const moveCard = trpc.viewer.boards.moveCard.useMutation({
  onSuccess: (data) => {
    console.log('Cards moved:', data.affectedCards)
  },
  onError: (error) => {
    console.error('Error:', error.message)
  }
})

// Use it:
moveCard.mutate({
  cardId: 'card-uuid',
  targetColumnId: 'column-uuid',
  targetPosition: 2,
  boardId: 'board-uuid'
})
```

### Option B: Check Your Frontend

If you have existing frontend code that moves cards, update it to use:
```typescript
trpc.viewer.boards.moveCard.useMutation()
```

---

## Step 8: Update Realtime Event Listeners

If you have realtime listeners for card updates, update them to handle the new batch event format:

```typescript
import { parseCardMoveEvent, processCardMoveEvent } from '@calcom/features/boards/lib/realtimeCardMoveHandler'

// In your realtime subscription:
const event = parseCardMoveEvent(payload)
if (event) {
  await processCardMoveEvent(
    event,
    async (cardIds) => {
      // Fetch full card details
      const response = await trpc.viewer.boards.getCardsByIds.query({ cardIds })
      return response.cards
    },
    (cards) => {
      // Update your UI state
      setCards(cards)
    }
  )
}
```

---

## Step 9: Verify Everything Works

1. ✅ Move a card within the same column
2. ✅ Move a card between columns
3. ✅ Move multiple cards rapidly (test for race conditions)
4. ✅ Check that only ONE realtime event is emitted per move
5. ✅ Verify all affected cards are included in the event

---

## 🆘 Need Help?

### Common Issues:

**Issue**: "Table does not exist"
- **Solution**: Check Step 1 - you need to find your actual table names

**Issue**: "Column does not exist"  
- **Solution**: Check column names in Step 1

**Issue**: "Function already exists"
- **Solution**: The migration uses `CREATE OR REPLACE` so this should be fine, but if you get conflicts, you may need to drop the function first

**Issue**: "Permission denied"
- **Solution**: Make sure your database user has permissions to create functions and triggers

---

## 📝 Checklist

Before you're done, verify:

- [ ] Found actual table names (Step 1)
- [ ] Updated migration SQL with correct table names (Step 2)
- [ ] Updated handler with correct table names (Step 3)
- [ ] Migration ran successfully (Step 5)
- [ ] PostgreSQL function works (Step 6)
- [ ] API endpoint works (Step 7)
- [ ] Frontend updated to use new endpoint (Step 7)
- [ ] Realtime listeners updated (Step 8)
- [ ] Tested card moves work correctly (Step 9)

---

## 🎉 Success!

Once all steps are complete, you should have:
- ✅ Atomic card moves (no race conditions)
- ✅ Single realtime event per move (better scalability)
- ✅ Reliable card positioning
- ✅ Persistent card positions

Good luck! Let me know if you get stuck on any step.