# Setup Guide: Transaction-Based Card Move Implementation

## Step 1: Find Your Actual Table Names

We need to identify the actual table names for boards, cards, and columns in your database.

### Option A: Check Your Database Directly

Run this SQL query in your PostgreSQL database:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name ILIKE '%card%' 
   OR table_name ILIKE '%board%' 
   OR table_name ILIKE '%column%'
ORDER BY table_name;
```

### Option B: Check Existing Code

Look for any existing API handlers or queries that work with boards/cards. Check:
- Any files that query board/card data
- Existing migrations that create these tables
- Any working API endpoints

### Option C: Check Prisma Schema

If the models exist in your Prisma schema, they should be defined there. Search for:
- `model Card`
- `model Board`  
- `model Column`

## Step 2: Update Table Names (If Needed)

Once you know your actual table names, update these files:

### File 1: Migration SQL
**Location**: `packages/prisma/migrations/20260126204203_transaction_based_card_move/migration.sql`

Find and replace:
- `cards` → your actual card table name
- `boards` → your actual board table name  
- `columns` → your actual column table name

### File 2: Handler
**Location**: `packages/trpc/server/routers/viewer/boards/moveCard.handler.ts`

Update the raw SQL queries to use your actual table names.

## Step 3: Verify Column Names

Check that your tables have these columns (names may vary):
- `id` (UUID)
- `column_id` or `columnId` (UUID)
- `board_id` or `boardId` (UUID)
- `position` (INTEGER)
- `title` (TEXT)
- `updated_at` or `updatedAt` (TIMESTAMP)

Update the SQL queries if column names differ.

## Step 4: Run the Migration

```bash
yarn workspace @calcom/prisma db-migrate
```

## Step 5: Test the Implementation

1. Test the PostgreSQL function directly:
```sql
SELECT * FROM move_card_atomic(
  'your-card-id'::UUID,
  'target-column-id'::UUID,
  2::INTEGER,
  'board-id'::UUID
);
```

2. Test the API endpoint via tRPC:
```typescript
const moveCard = trpc.viewer.boards.moveCard.useMutation()
moveCard.mutate({
  cardId: 'card-uuid',
  targetColumnId: 'column-uuid',
  targetPosition: 2,
  boardId: 'board-uuid'
})
```

## Step 6: Update Frontend (If Needed)

If you have existing frontend code that calls the old card move API, update it to use:
```typescript
trpc.viewer.boards.moveCard.useMutation()
```

## Step 7: Update Realtime Listeners

Update your realtime event listeners to process the new batch event format using:
```typescript
import { parseCardMoveEvent, processCardMoveEvent } from '@calcom/features/boards/lib/realtimeCardMoveHandler'
```

## Troubleshooting

### Migration Fails
- Check table names match your actual schema
- Verify column names are correct
- Check for syntax errors in the SQL

### Function Not Found
- Ensure migration ran successfully
- Check function exists: `\df move_card_atomic` in psql

### Prisma Errors
- If using Prisma models, ensure they're defined in schema.prisma
- If using raw SQL, verify table/column names match database