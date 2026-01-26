# Debug: Card Not Persisting After Move

## Problem
Card moves in UI but returns to original position after page refresh.

## Possible Causes

### 1. Frontend Using Old API
The frontend might still be calling the old API endpoint that doesn't use the atomic function.

**Check:**
- Open browser DevTools → Network tab
- Move a card
- Look at the API call being made
- Is it calling `/api/boards/moveCard` or something else?

### 2. Database Not Actually Updated
The move might be happening optimistically in the UI but not persisting.

**Verify:**
```sql
-- Check the card's current state in database
SELECT id, title, column_id, position, updated_at
FROM cards
WHERE title = 'Realtime Test'
ORDER BY updated_at DESC;
```

### 3. Multiple API Endpoints
There might be multiple endpoints and the wrong one is being called.

**Check for:**
- Old REST API endpoints
- Old tRPC endpoints
- GraphQL mutations

### 4. Transaction Rollback
The atomic function might be failing silently.

**Check PostgreSQL logs:**
```sql
-- Check if function exists and works
SELECT * FROM move_card_atomic(
  'your-card-id'::UUID,
  'target-column-id'::UUID,
  0::INTEGER,
  'board-id'::UUID
);
```

## Quick Fix Steps

### Step 1: Verify Database State
```sql
-- Before moving: Note the card's column_id and position
SELECT id, title, column_id, position 
FROM cards 
WHERE title = 'Realtime Test';

-- Move card in UI

-- After moving: Check if it changed
SELECT id, title, column_id, position, updated_at
FROM cards 
WHERE title = 'Realtime Test';
```

### Step 2: Check What API is Being Called
1. Open browser DevTools (F12)
2. Go to Network tab
3. Move the card
4. Find the API request
5. Check:
   - What endpoint is being called?
   - What's the request payload?
   - What's the response?

### Step 3: Test New Endpoint Directly
```typescript
// In browser console or test file
import { trpc } from '@calcom/trpc/react'

const moveCard = trpc.viewer.boards.moveCard.useMutation()
moveCard.mutate({
  cardId: 'card-id',
  targetColumnId: 'target-column-id',
  targetPosition: 0,
  boardId: 'board-id'
})
```

## Solution

If the frontend is using the old API, update it to use:
```typescript
trpc.viewer.boards.moveCard.useMutation()
```

See `packages/features/boards/UPDATE_FRONTEND.md` for details.