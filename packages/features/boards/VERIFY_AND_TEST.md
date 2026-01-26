# Verify Migration & Test Guide

## ✅ Step 1: Verify Migration Worked

Run these SQL queries to confirm everything was created:

```sql
-- 1. Check if function exists
SELECT routine_name, routine_type
FROM information_schema.routines 
WHERE routine_name = 'move_card_atomic';

-- 2. Check if index exists
SELECT indexname, tablename
FROM pg_indexes 
WHERE tablename = 'cards' 
  AND indexname = 'cards_board_id_column_id_position_idx';
```

**Expected results:**
- Function query should return 1 row with `move_card_atomic` and `FUNCTION`
- Index query should return 1 row with the index name

---

## ✅ Step 2: Test the PostgreSQL Function

Get some real IDs from your database first:

```sql
-- Get a sample card, column, and board ID
SELECT 
  c.id as card_id,
  c.column_id,
  c.position as current_position,
  c.board_id,
  col.id as target_column_id
FROM cards c
JOIN columns col ON col.board_id = c.board_id
WHERE c.board_id IS NOT NULL
LIMIT 1;
```

Then test the function with real IDs:

```sql
-- Replace with actual IDs from above query
SELECT * FROM move_card_atomic(
  'card-id-here'::UUID,      -- card_id from above
  'target-column-id-here'::UUID,  -- target_column_id from above
  0::INTEGER,                 -- target position (0 = top)
  'board-id-here'::UUID       -- board_id from above
);
```

**Expected result:** Should return affected cards with their new positions.

**If you get an error:**
- Check that the IDs exist
- Verify the card belongs to the board
- Check that target position is valid

---

## ✅ Step 3: Test the API Endpoint

### Option A: Via tRPC Client (Frontend)

```typescript
import { trpc } from '@calcom/trpc/react'

const moveCard = trpc.viewer.boards.moveCard.useMutation({
  onSuccess: (data) => {
    console.log('✅ Success!', data)
    console.log('Affected cards:', data.affectedCards)
  },
  onError: (error) => {
    console.error('❌ Error:', error.message)
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

### Option B: Via API Call (Backend/Testing)

```typescript
import { appRouter } from '@calcom/trpc/server'
import { createContext } from '@calcom/trpc/server/createContext'

const ctx = await createContext({ req, res })
const caller = appRouter.createCaller(ctx)

const result = await caller.viewer.boards.moveCard({
  cardId: 'card-uuid',
  targetColumnId: 'column-uuid',
  targetPosition: 2,
  boardId: 'board-uuid'
})

console.log('Result:', result)
```

---

## ✅ Step 4: Update Your Frontend

### Find Your Existing Card Move Code

Look for files that:
- Handle drag-and-drop (`handleDragEnd`, `onDragEnd`)
- Call card move APIs
- Update card positions

Common locations:
- `kanban-board.tsx`
- `BoardDetailPage.tsx`
- Any component with `moveCard` or `updateCardPosition`

### Replace with New Endpoint

**Before (old code):**
```typescript
// Old way - multiple API calls or non-atomic updates
await updateCardPosition(cardId, newPosition)
await updateCardColumn(cardId, newColumnId)
// ... more updates
```

**After (new code):**
```typescript
import { trpc } from '@calcom/trpc/react'

const moveCard = trpc.viewer.boards.moveCard.useMutation()

// In your drag handler:
await moveCard.mutateAsync({
  cardId: draggedCard.id,
  targetColumnId: destinationColumnId,
  targetPosition: destinationIndex,
  boardId: boardId
})

// The mutation returns all affected cards automatically!
// No need for multiple API calls
```

---

## ✅ Step 5: Update Realtime Listeners

If you have realtime subscriptions for card updates, update them to handle batch events:

```typescript
import { parseCardMoveEvent, processCardMoveEvent } from '@calcom/features/boards/lib/realtimeCardMoveHandler'

// Example with Supabase
supabase
  .channel('card-moves')
  .on('postgres_changes', {
    event: 'NOTIFY',
    schema: 'public',
    channel: 'card_move'
  }, async (payload) => {
    const event = parseCardMoveEvent(payload.new?.payload || payload.payload)
    if (event) {
      await processCardMoveEvent(
        event,
        async (cardIds) => {
          // Fetch full card details
          // You may need to create this endpoint or use existing one
          const response = await trpc.viewer.boards.getCardsByIds.query({ 
            cardIds 
          })
          return response.cards
        },
        (cards) => {
          // Update your UI state with all affected cards
          setCards(prevCards => {
            const updated = [...prevCards]
            cards.forEach(card => {
              const index = updated.findIndex(c => c.id === card.id)
              if (index >= 0) {
                updated[index] = card
              }
            })
            return updated
          })
        }
      )
    }
  })
  .subscribe()
```

---

## 🎉 Success Checklist

- [x] Migration ran successfully
- [ ] Function verified (Step 1)
- [ ] Function tested with real data (Step 2)
- [ ] API endpoint tested (Step 3)
- [ ] Frontend updated to use new endpoint (Step 4)
- [ ] Realtime listeners updated (Step 5)
- [ ] Tested moving cards within same column
- [ ] Tested moving cards between columns
- [ ] Tested rapid card moves (race condition test)

---

## 🐛 Troubleshooting

### Function Not Found
- Check migration ran: `SELECT * FROM _prisma_migrations WHERE name LIKE '%transaction_based_card_move%'`
- Re-run migration if needed

### API Returns 404
- Check router is registered: `packages/trpc/server/routers/viewer/_router.tsx` should have `boards: boardsRouter`
- Restart your dev server

### Cards Not Moving
- Check user has access to board (authorization check in handler)
- Verify card/column IDs are correct
- Check database constraints aren't blocking updates

---

**Ready to test?** Start with Step 1 to verify everything is set up correctly!